import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1',
  );

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // events and sync
  static const String events = '/events/';
  static const String sync = '/events/sync';

  // categories
  static const String categories = '/categories/';

  // statistics
  static const String statsSummary = '/stats/summary';
}
