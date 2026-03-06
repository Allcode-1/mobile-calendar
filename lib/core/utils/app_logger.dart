import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _debugLogsEnabled = bool.fromEnvironment(
    'APP_DEBUG_LOGS',
    defaultValue: true,
  );

  static void debug(String message, {String scope = 'app'}) {
    if (!kDebugMode || !_debugLogsEnabled) {
      return;
    }
    developer.log(message, name: scope, level: 500);
  }

  static void info(String message, {String scope = 'app'}) {
    if (!kDebugMode || !_debugLogsEnabled) {
      return;
    }
    developer.log(message, name: scope, level: 800);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String scope = 'app',
  }) {
    developer.log(
      message,
      name: scope,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String scope = 'app',
  }) {
    developer.log(
      message,
      name: scope,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
