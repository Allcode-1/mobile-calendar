import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

class ApiClient {
  // singleton pattern: one pattern for whole app
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _addInterceptors();
  }

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString('access_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          AppLogger.debug(
            '[REQ] ${options.method} ${options.uri}',
            scope: 'api',
          );
          if (options.data != null) {
            AppLogger.debug('[REQ BODY] ${options.data}', scope: 'api');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug(
            '[RES] ${response.statusCode} ${response.requestOptions.path}',
            scope: 'api',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          AppLogger.warning(
            '[ERR] ${e.response?.statusCode} ${e.requestOptions.path}',
            error: e,
            stackTrace: e.stackTrace,
            scope: 'api',
          );
          AppLogger.debug('[ERR DATA] ${e.response?.data}', scope: 'api');

          // if token expired (401) logout user
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
          }

          return handler.next(e);
        },
      ),
    );
  }

  // utilit for handle bag check
  String getReadableError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return "Server not responding";
      }
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) {
          return detail;
        }
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }
      }
    }
    return "We got undefined error...";
  }
}
