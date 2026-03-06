import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/core/utils/validators.dart';

void main() {
  test('validateEmail rejects invalid email', () {
    final result = Validators.validateEmail('invalid-email');
    expect(result, isNotNull);
  });

  test('validateEmail accepts valid email', () {
    final result = Validators.validateEmail('user@example.com');
    expect(result, isNull);
  });

  test('validatePassword enforces minimum length', () {
    final result = Validators.validatePassword('123');
    expect(result, isNotNull);
  });

  test('validateName accepts non-empty name', () {
    final result = Validators.validateName('John');
    expect(result, isNull);
  });
}
