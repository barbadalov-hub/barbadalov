import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected primary tab in [HomeShell] (0 Today · 1 Money · 2 Health ·
/// 3 Goals · 4 More). Exposed as a provider so features like the command
/// palette can jump between tabs from anywhere.
final homeTabProvider = StateProvider<int>((_) => 0);
