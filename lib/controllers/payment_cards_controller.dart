import 'package:get/get.dart';
import 'package:food_run/network/apis.dart';

class PaymentCardsController extends GetxController {
  List<Map<String, dynamic>> cards = [];
  int? selectedCardId;

  Future<void> init() async {
    try {
      cards = await Api().fetchPaymentCards();
      update(['payment_cards']);
    } on Exception catch (_) {
      return;
    }
  }

  void selectCard(int? cardId) {
    selectedCardId = cardId;
    update(['payment_cards']);
  }
}
