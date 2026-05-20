import 'package:dio/dio.dart';
import 'package:food_run/network/api/dio_client.dart';
import 'package:retrofit/retrofit.dart';

part 'payment_cards_api.g.dart';

@RestApi()
abstract class PaymentCardsApiClient {
  factory PaymentCardsApiClient(Dio dio, {String baseUrl}) =
      _PaymentCardsApiClient;

  @GET("/payment-cards/")
  Future<dynamic> fetchPaymentCardsRaw();

  @DELETE("/payment-cards/{cardId}/")
  Future<dynamic> deletePaymentCardRaw(
    @Path("cardId") int cardId,
    @Body() Map<String, dynamic> body,
  );
}

class PaymentCardsApi {
  final PaymentCardsApiClient _client;

  PaymentCardsApi(Dio dio) : _client = PaymentCardsApiClient(dio);

  Future<List<Map<String, dynamic>>> fetchPaymentCards() async {
    final response =
        await DioClient.runSafe(() => _client.fetchPaymentCardsRaw());
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> deletePaymentCard(int cardId) async {
    await DioClient.runSafe(() => _client.deletePaymentCardRaw(cardId, {}));
  }
}
