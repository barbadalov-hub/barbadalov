package com.example.lifeos

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Voice input, written against Android's own SpeechRecognizer rather than
 * pulled in as a package.
 *
 * Every published speech plugin either ships a Windows implementation — which
 * forces the desktop build to need Developer Mode, the one thing this project
 * is built to avoid — or is old enough that its Gradle script still calls the
 * long-removed `jcenter()` and will not build at all. There is no version that
 * is both. Roughly eighty lines here keep the dependency surface untouched and
 * every platform building as before.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "lumo/speech"
    private var channel: MethodChannel? = null
    private var recognizer: SpeechRecognizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(SpeechRecognizer.isRecognitionAvailable(this))
                "start" -> result.success(start(call.argument<String>("locale")))
                "stop" -> {
                    stopListening()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Returns false when the microphone is not granted yet; the request is
     *  raised so a second tap works. A refusal is an answer, not a failure. */
    private fun start(locale: String?): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.RECORD_AUDIO), 4711
            )
            return false
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) return false

        stopListening()
        val sr = SpeechRecognizer.createSpeechRecognizer(this)
        recognizer = sr
        sr.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle?) {
                emit(results, final = true)
            }

            override fun onPartialResults(partial: Bundle?) {
                // Partial text lets the field fill as the user speaks, so they
                // can see it going wrong instead of finding out at the end.
                emit(partial, final = false)
            }

            override fun onError(error: Int) {
                channel?.invokeMethod("onDone", null)
            }

            override fun onEndOfSpeech() {}
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            // The app's own language: dictating Russian into an English
            // recogniser produces confident nonsense rather than an error.
            if (locale != null) putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
        }
        return try {
            sr.startListening(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun emit(bundle: Bundle?, final: Boolean) {
        val text = bundle
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()
            ?: return
        channel?.invokeMethod("onText", mapOf("text" to text, "final" to final))
        if (final) channel?.invokeMethod("onDone", null)
    }

    private fun stopListening() {
        try {
            recognizer?.stopListening()
            recognizer?.destroy()
        } catch (_: Exception) {
            // Nothing useful to do if the engine has already gone.
        }
        recognizer = null
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }
}
