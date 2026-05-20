import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';
import 'package:food_run/controllers/order_controller.dart'
    show Discount, DiscountType;

part 'loyalty_api.g.dart';

@RestApi()
abstract class LoyaltyApiClient {
  factory LoyaltyApiClient(Dio dio, {String baseUrl}) = _LoyaltyApiClient;

  @POST("/shops/{shopCode}/discounts/check/")
  Future<dynamic> fetchPromocodeRaw(
    @Path("shopCode") String shopCode,
    @Body() Map<String, dynamic> body,
  );

  @GET("/loyalty/bonuses/")
  Future<dynamic> fetchBonusesRaw();

  @POST("/shops/{shopCode}/earned-points/")
  Future<dynamic> fetchEarnedPointsRaw(
    @Path("shopCode") String shopCode,
    @Body() Map<String, dynamic> body,
  );
}

class LoyaltyApi {
  final LoyaltyApiClient _client;

  LoyaltyApi(Dio dio) : _client = LoyaltyApiClient(dio);

  Future<Discount> fetchPromocode(
      Map<String, dynamic> body, String shopCode) async {
    final response = await DioClient.runSafe(
        () => _client.fetchPromocodeRaw(shopCode, body));
    final json = response as Map<String, dynamic>;
    return Discount(
      code: json['code'] as String?,
      type: DiscountType.values.byName(json['type'] as String? ?? 'percent'),
      amount: json['amount'] as int?,
      minOrderSum: json['min_order_sum'] as int?,
    );
  }

  Future<int> fetchBonuses() async {
    final response = await DioClient.runSafe(() => _client.fetchBonusesRaw());
    return (response['total'] as num).toInt();
  }

  Future<({int amount})> fetchEarnedPoints(
      String shopCode, Map<String, dynamic> body) async {
    final response = await DioClient.runSafe(
        () => _client.fetchEarnedPointsRaw(shopCode, body));
    return (amount: (response['amount'] as num).toInt());
  }
}
