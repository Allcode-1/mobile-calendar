import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/data/models/category_model.dart';

void main() {
  test('CategoryModel parses color from hex string', () {
    final model = CategoryModel.fromJson({
      'id': 'cat-1',
      'name': 'Work',
      'color_hex': '#FF0000',
      'user_id': 'user-1',
      'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    });

    expect(model.flutterColor, equals(const Color(0xFFFF0000)));
  });

  test('CategoryModel falls back to blue when color is invalid', () {
    final model = CategoryModel.fromJson({
      'id': 'cat-1',
      'name': 'Work',
      'color_hex': 'invalid',
      'user_id': 'user-1',
      'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    });

    expect(model.flutterColor, equals(Colors.blue));
  });

  test('CategoryModel parses id and is_deleted from mixed types', () {
    final model = CategoryModel.fromJson({
      'id': 42,
      'name': 'Home',
      'color': '#00FF00',
      'user_id': 777,
      'is_deleted': 'true',
    });

    expect(model.id, '42');
    expect(model.userId, '777');
    expect(model.isDeleted, isTrue);
  });
}
