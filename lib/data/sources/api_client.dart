import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

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

          if (kDebugMode) {
            print('🌐 [API REQ] ${options.method}: ${options.uri}');
            if (options.data != null) print('📦 Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '✅ [API RES] ${response.statusCode}: ${response.requestOptions.path}',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            print(
              '❌ [API ERR] ${e.response?.statusCode}: ${e.requestOptions.path}',
            );
            print('💬 Data: ${e.response?.data}');
          }

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
      if (e.type == DioExceptionType.connectionTimeout)
        return "Server not responding";
      if (e.response?.data?['detail'] != null) {
        final detail = e.response?.data['detail'];
        return detail is String ? detail : detail[0]['msg'].toString();
      }
    }
    return "We got undefined error...";
  }
}
