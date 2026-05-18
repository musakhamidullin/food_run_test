import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:food_run/network/api_exception.dart';

class HttpClient {
  HttpClient._privateConstructor();

  static final HttpClient _instance = HttpClient._privateConstructor();

  factory HttpClient() {
    return _instance;
  }

  Future<dynamic> getRequest({required String url, String? token}) async {
    http.Response response;

    log(url);

    var headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    try {
      response = await http.get(Uri.parse(url), headers: headers);
      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 299) {
        if (response.body.isEmpty) {
          return '';
        } else {
          final str = const Utf8Decoder().convert(response.bodyBytes);
          return jsonDecode(str);
        }
      } else if (statusCode >= 400 && statusCode < 500) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        log(error);
        throw ClientErrorException();
      } else if (statusCode >= 500 && statusCode < 600) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        log(error);
        throw ServerErrorException();
      } else {
        throw UnknownException();
      }
    } on SocketException {
      throw ConnectionException();
    }
  }

  Future<dynamic> postRequest(
    String url,
    Map<String, dynamic> body, {
    String? token,
    bool? throwClientErrorText,
    bool? throwServerErrorText,
  }) async {
    http.Response response;

    log(url);

    var headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    try {
      response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: headers,
      );
      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 299) {
        if (response.body.isEmpty) {
          return '';
        } else {
          final str = const Utf8Decoder().convert(response.bodyBytes);
          return jsonDecode(str);
        }
      } else if (statusCode >= 400 && statusCode < 500) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        final errorJson = jsonDecode(error);
        log(error);
        throw ClientErrorException(
            error: throwClientErrorText ?? false ? errorJson : null);
      } else if (statusCode >= 500 && statusCode < 600) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        final errorJson = jsonDecode(error);
        throw ServerErrorException(
            error: (throwServerErrorText ?? false) ? errorJson : null);
      } else {
        throw UnknownException();
      }
    } on SocketException {
      throw ConnectionException();
    }
  }

  Future<dynamic> patchRequest({
    required String url,
    String? token,
    Map<String, dynamic>? body,
  }) async {
    http.Response response;

    log(url);

    var headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    try {
      response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 299) {
        if (response.body.isEmpty) {
          return '';
        } else {
          final str = const Utf8Decoder().convert(response.bodyBytes);
          return jsonDecode(str);
        }
      } else if (statusCode >= 400 && statusCode < 500) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        log(error);
        throw ClientErrorException();
      } else if (statusCode >= 500 && statusCode < 600) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        log(error);
        throw ServerErrorException();
      } else {
        throw UnknownException();
      }
    } on SocketException {
      throw ConnectionException();
    }
  }

  Future<dynamic> deleteRequest(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    http.Response response;

    log(url);

    var headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }

    try {
      response = await http.delete(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: headers,
      );
      final statusCode = response.statusCode;
      if (statusCode >= 200 && statusCode < 299) {
        if (response.body.isEmpty) {
          return '';
        } else {
          final str = const Utf8Decoder().convert(response.bodyBytes);
          return jsonDecode(str);
        }
      } else if (statusCode >= 400 && statusCode < 500) {
        final error = const Utf8Decoder().convert(response.bodyBytes);
        log(error);
        throw ClientErrorException();
      } else if (statusCode >= 500 && statusCode < 600) {
        throw ServerErrorException();
      } else {
        throw UnknownException();
      }
    } on SocketException {
      throw ConnectionException();
    }
  }
}
