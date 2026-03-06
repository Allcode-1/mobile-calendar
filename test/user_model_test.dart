import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/data/models/user_model.dart';

void main() {
  test('UserModel parses profile fields from valid payload', () {
    final user = UserModel.fromJson({
      'id': 'u-1',
      'email': 'user@example.com',
      'profile': {
        'full_name': 'John Doe',
        'avatar_url': 'https://img.test/a.png',
      },
    });

    expect(user.id, 'u-1');
    expect(user.email, 'user@example.com');
    expect(user.fullName, 'John Doe');
    expect(user.avatarUrl, 'https://img.test/a.png');
  });

  test('UserModel falls back when profile payload is invalid', () {
    final user = UserModel.fromJson({
      'id': 99,
      'email': 'user@example.com',
      'profile': 'invalid-profile',
    });

    expect(user.id, '99');
    expect(user.fullName, '');
    expect(user.avatarUrl, isNull);
  });
}
