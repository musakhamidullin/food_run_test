import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';
import 'package:food_run/dto/order_dto.dart';
import 'package:food_run/controllers/order_controller.dart'
    show ConfirmOrderResponse, ClosedRestaurantResponse;

part 'order_api.g.dart';

@RestApi()
abstract class OrderApiClient {
  factory OrderApiClient(Dio dio, {String baseUrl}) = _OrderApiClient;

  @GET("/shops/{shopCode}/stop-list/")
  Future<dynamic> fetchStopList(@Path("shopCode") String shopCode);

  @GET("/shops/{shopCode}/leftovers/")
  Future<dynamic> fetchProductLeftoversRaw(
    @Path("shopCode") String shopCode,
  );

  @POST("/orders/")
  Future<dynamic> confirmOrderRaw(
    @Body() Map<String, dynamic> body,
  );

  @GET("/orders/")
  Future<dynamic> fetchOrderHistoryRaw(
    @Query("page") int page,
  );
}

class OrderApi {
  final OrderApiClient _client;

  OrderApi(Dio dio) : _client = OrderApiClient(dio);

  Future<List<int>> fetchStopList(String shopCode) async {
    final response =
        await DioClient.runSafe(() => _client.fetchStopList(shopCode));
    return List<int>.from(response as List);
  }

  Future<Map<int, int>> fetchProductLeftovers(String shopCode) async {
    final response = await DioClient.runSafe(
        () => _client.fetchProductLeftoversRaw(shopCode));
    final map = response as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<ConfirmOrderResponse> confirmOrder(Map<String, dynamic> body) async {
    final response =
        await DioClient.runSafe(() => _client.confirmOrderRaw(body));
    final json = response as Map<String, dynamic>;

    if (json.containsKey('closed')) {
      return ConfirmOrderResponse(
        orderId: 0,
        closed: ClosedRestaurantResponse(json['closed'] as String),
      );
    }

    return ConfirmOrderResponse(
      paymentUrl: json['payment_url'] as String?,
      orderId: json['id'] as int,
      order: json['order'] != null
          ? OrderDto.fromJson(json['order'] as Map<String, dynamic>).toEntity()
          : null,
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrderHistory(int page) async {
    final response =
        await DioClient.runSafe(() => _client.fetchOrderHistoryRaw(page));
    return List<Map<String, dynamic>>.from(response['results']);
  }
}
