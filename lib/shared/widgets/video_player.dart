// In-app technique-video playback, chosen at compile time:
// web → inline HTML <video> inside a bottom sheet (works even where external
// links are blocked); native → system player via openUrl. Zero plugins.
export 'video_player_io.dart' if (dart.library.js_interop) 'video_player_web.dart';
