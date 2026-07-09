# Only the Latin ML Kit text-recognition model is bundled. R8 sees references to
# the other script recognizers (Chinese/Devanagari/Japanese/Korean) in the
# plugin and errors on the missing classes — they are optional, so ignore them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit classes (they are accessed via the platform channel / reflection).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
