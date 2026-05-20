import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'system_api.g.dart';

@RestApi()
abstract class SystemApiClient {
  factory SystemApiClient(Dio dio, {String baseUrl}) = _SystemApiClient;

  @GET("https://foodrun.ru/api/mobile-warning/")
  Future<dynamic> getWarningMessageRaw();

  @GET("https://foodrun.ru/api/check-order-time/")
  Future<dynamic> canOrderRaw(
    @Query("restaurant") int restaurantId,
  );

  @POST("https://foodrun.ru/api/check-min-price/")
  Future<dynamic> checkMinPriceRaw(
    @Body() Map<String, dynamic> body,
  );
}

class SystemApi {
  final SystemApiClient _client;

  SystemApi(Dio dio) : _client = SystemApiClient(dio);

  Future<String?> getWarningMessage() async {
    try {
      final response =
          await DioClient.runSafe(() => _client.getWarningMessageRaw());
      final map = response as Map<String, dynamic>;
      final message = map['message'];
      if (message is! String || message.isEmpty) return null;
      return message;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> canOrder(int restaurantId) async {
    try {
      final response =
          await DioClient.runSafe(() => _client.canOrderRaw(restaurantId));
      final map = response as Map<String, dynamic>;
      return map['can_order'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> checkMinPrice(int orderId) async {
    try {
      final response = await DioClient.runSafe(
          () => _client.checkMinPriceRaw({'order_id': orderId}));
      final map = response as Map<String, dynamic>;
      if (map['ok'] == true) return null;
      return map['message'] as String?;
    } catch (e) {
      debugPrint('checkMinPrice error: $e');
      return null;
    }
  }
}
