import 'package:flutter/widgets.dart';
import 'package:lifeos/core/utils/open_url.dart';

/// Play a technique video — desktop/mobile variant: hand the file to the
/// system browser/player (streams on demand, no plugin).
Future<void> playVideo(BuildContext context, String url, String title) =>
    openUrl(url);
