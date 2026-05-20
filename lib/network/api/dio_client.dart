import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:food_run/controllers/shared_prefs_controller.dart';
import 'package:food_run/network/api_exception.dart';

class DioClient {
  factory DioClient() => _instance;

  DioClient._internal() {
    const defaultTimeOut = const Duration(seconds: 15);

    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.foodrun.ru/api/projects/main',
      connectTimeout: defaultTimeOut,
      receiveTimeout: defaultTimeOut,
      sendTimeout: defaultTimeOut,
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Content-Type'] = 'application/json; charset=utf-8';
        try {
          final token = Get.find<SharedPrefsController>().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
        } catch (_) {}
        return handler.next(options);
      },
    ));
  }

  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  static Future<T> runSafe<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.error is SocketException) {
        throw ConnectionException();
      }

      if (statusCode != null) {
        if (statusCode >= 400 && statusCode < 500) {
          throw ClientErrorException(error: data);
        } else if (statusCode >= 500 && statusCode < 600) {
          throw ServerErrorException(error: data);
        }
      }
      throw UnknownException();
    } catch (_) {
      rethrow;
    }
  }
}
