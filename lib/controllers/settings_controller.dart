import 'package:get/get.dart';

class SettingsController extends GetxController {
  String? token;
  bool isPickup = true;
  String? currentShopCode;
  String? personalOfferCode;

  Future<void> init() async {
    // загрузка настроек, получение токена, определение текущего магазина
  }

  Future<void> setToken(String t) async {
    token = t;
  }

  void clearToken() {
    token = null;
  }
}
