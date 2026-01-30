class AppConstants {
  // App name
  static const String appName = "Quest Calendar";
  static const String appVersion = "1.0.0";

  // keys for SharedPreferences (local data)
  // use them in AuthRepository and ApiClient
  static const String keyToken = 'access_token';
  static const String keyUserEmail = 'user_email';
  static const String keyUserId = 'user_id';
  static const String keyIsDarkMode = 'is_dark_mode';

  // design system (UI constants)
  // if i gonna change padding in figma, change there for app
  static const double screenPadding = 24.0;
  static const double elementSpacing = 16.0;
  static const double borderRadius = 16.0;
  static const double buttonHeight = 56.0;

  // animations
  static const int animationDurationMs = 300;

  // error messages (standart)
  static const String errorNetwork = "Check your internet connection";
  static const String errorUnknown = "Something went wrong. Try later";
  static const String errorFieldRequired = "This field is required";

  // date formats
  static const String dateDisplayFormat = "dd.MM.yyyy";
  static const String timeDisplayFormat = "HH:mm";
}
