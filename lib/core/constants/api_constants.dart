class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';

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
