import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'profile_api.g.dart';

@RestApi()
abstract class ProfileApiClient {
  factory ProfileApiClient(Dio dio, {String baseUrl}) = _ProfileApiClient;

  // Идет на старый сайт (абсолютный URL)
  @POST("https://foodrun.ru/api/whoami/")
  Future<dynamic> setUserFirstName(@Body() Map<String, dynamic> body);

  // Идет в API проектов (относительный URL, склеится с baseUrl)
  @GET("/profile/")
  Future<dynamic> getProfile();

  // Идет на старый сайт (абсолютный URL)
  @GET("https://foodrun.ru/api/delete-my-account/")
  Future<dynamic> deleteAccount();

  // Идет в API проектов (относительный URL)
  @GET("/cashback/")
  Future<dynamic> fetchCashback();
}

class ProfileApi {
  final ProfileApiClient _client;

  ProfileApi(Dio dio) : _client = ProfileApiClient(dio);

  Future<bool> setUserFirstName(String value) async {
    try {
      await DioClient.runSafe(
          () => _client.setUserFirstName({'first_name': value}));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await DioClient.runSafe(() => _client.getProfile());
    return response as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    await DioClient.runSafe(() => _client.deleteAccount());
  }

  Future<void> fetchCashback() async {
    await DioClient.runSafe(() => _client.fetchCashback());
  }
}
