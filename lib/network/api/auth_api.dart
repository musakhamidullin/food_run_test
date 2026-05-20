import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String baseUrl}) = _AuthApiClient;

  @POST("/auth/send-code/")
  Future<dynamic> sendPhone(@Body() Map<String, dynamic> body);

  @POST("/auth/verify-code/")
  Future<dynamic> verifyCode(@Body() Map<String, dynamic> body);
}

class AuthApi {
  final AuthApiClient _client;

  AuthApi(Dio dio) : _client = AuthApiClient(dio);

  Future<void> sendPhone(Map<String, dynamic> body) async {
    await DioClient.runSafe(() => _client.sendPhone(body));
  }

  Future<Map<String, dynamic>> verifyCode(Map<String, dynamic> body) async {
    final response = await DioClient.runSafe(() => _client.verifyCode(body));
    return response as Map<String, dynamic>;
  }
}
