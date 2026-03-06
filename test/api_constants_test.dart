import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_calendar/core/constants/api_constants.dart';

void main() {
  test('ApiConstants.baseUrl has API prefix', () {
    expect(ApiConstants.baseUrl, isNotEmpty);
    expect(ApiConstants.baseUrl, contains('/api/v1'));
    expect(ApiConstants.baseUrl.startsWith('http://'), isTrue);
  });
}
