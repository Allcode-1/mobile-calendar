class Validators {
  // Валидация Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter correct email daress';
    }
    return null;
  }

  // password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (value.length < 8) {
      return 'The password must be at least 8 characters long';
    }
    return null;
  }

  // name valid
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter name';
    }
    if (value.length < 2) {
      return 'The name is too short';
    }
    return null;
  }

  // validation for event header
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Field "$fieldName" cannot be empty';
    }
    return null;
  }
}
