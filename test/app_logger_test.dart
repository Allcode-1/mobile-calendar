import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/core/utils/app_logger.dart';

void main() {
  test('AppLogger methods do not throw', () {
    expect(() => AppLogger.debug('debug message'), returnsNormally);
    expect(() => AppLogger.info('info message'), returnsNormally);
    expect(() => AppLogger.warning('warn message'), returnsNormally);
    expect(() => AppLogger.error('error message'), returnsNormally);
  });
}
