import 'package:flutter/foundation.dart';

/// Lightweight diagnostics that are silent in release builds.
class AppLogger {
  const AppLogger._();

  static void debug(Object? message) {
    if (kDebugMode) {
      debugPrint(message?.toString());
    }
  }
}
