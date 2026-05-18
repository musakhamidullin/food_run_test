import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_run/models/order_item.dart';

class SharedPrefsController {
  SharedPrefsController(this._prefs);

  final SharedPreferences _prefs;

  String? getToken() => _prefs.getString('auth_token');
  Future<void> setToken(String token) => _prefs.setString('auth_token', token);
  Future<void> clearToken() => _prefs.remove('auth_token');

  String? getFirebaseToken() => _prefs.getString('firebase_token');
  Future<void> setFirebaseToken(String token) =>
      _prefs.setString('firebase_token', token);

  void saveCart(List<OrderItem> items) {
    // JSON-сериализация корзины
  }

  List<OrderItem> loadCart() => [];

  Future<void> clearCart() async {}

  void saveLoyaltyCart(List<OrderItem> items) {}

  List<OrderItem> loadLoyaltyCart() => [];

  Future<void> clearLoyaltyCart() async {}

  dynamic getSelectedAddress() => null;
}
