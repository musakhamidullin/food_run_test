import 'package:get/get.dart';
import 'package:food_run/network/apis.dart';

class ProfileController extends GetxController {
  Future<void> init() async {
    loadProfile();
  }

  void loadProfile() {
    // загрузка профиля пользователя
  }

  Future<void> fetchCashback() async {
    try {
      await Api().fetchCashback();
    } on Exception catch (_) {
      return;
    }
  }
}
