import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/core/utils/icon_mapper.dart';

void main() {
  test('getIcon returns mapped icon for known key', () {
    final icon = IconMapper.getIcon('home');
    expect(icon, equals(Icons.home_filled));
  });

  test('getIcon returns fallback icon for unknown key', () {
    final icon = IconMapper.getIcon('unknown');
    expect(icon, equals(Icons.folder_rounded));
  });

  test('allNames is not empty', () {
    expect(IconMapper.allNames, isNotEmpty);
  });
}
