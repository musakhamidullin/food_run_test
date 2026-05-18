import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:food_run/controllers/shared_prefs_controller.dart';
import 'package:food_run/models/category.dart';
import 'package:food_run/models/order.dart';
import 'package:food_run/models/product.dart';
import 'package:food_run/network/api_exception.dart';
import 'package:food_run/network/http_client.dart';
import 'package:food_run/controllers/order_controller.dart'
    show Discount, DiscountType, ConfirmOrderResponse, ClosedRestaurantResponse;

class Api {
  factory Api() => _api;

  Api._internal();

  static final Api _api = Api._internal();

  final HttpClient _httpClient = HttpClient();

  static const baseUrl = 'https://api.foodrun.ru/api/projects/main';

  String get _token =>
      Get.find<SharedPrefsController>().getToken() ?? '';

  Map<String, String> get _authHeaders => {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> sendPhone(Map<String, dynamic> body) async {
    await _httpClient.postRequest('$baseUrl/auth/send-code/', body);
  }

  Future<Map<String, dynamic>> verifyCode(Map<String, dynamic> body) async {
    final response =
        await _httpClient.postRequest('$baseUrl/auth/verify-code/', body);
    return response as Map<String, dynamic>;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  // использует основной сайт, а не API-проект
  Future<bool> setUserFirstName(String value) async {
    final response = await http.post(
      Uri.parse('https://foodrun.ru/api/whoami/'),
      headers: _authHeaders,
      body: jsonEncode({'first_name': value}),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response =
        await _httpClient.getRequest(url: '$baseUrl/profile/');
    return response as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    // этот endpoint живёт на основном сайте, а не в API
    await http.get(
      Uri.parse('https://foodrun.ru/api/delete-my-account/'),
      headers: _authHeaders,
    );
  }

  Future<void> fetchCashback() async {
    await _httpClient.getRequest(url: '$baseUrl/cashback/');
  }

  // ── Menu ──────────────────────────────────────────────────────────────────

  Future<List<Category>> fetchCategories(String shopCode) async {
    final response = await _httpClient.getRequest(
      url: '$baseUrl/shops/$shopCode/categories/',
    );
    final results = response['results'] as List;
    return results.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Product>> fetchCategoryProducts(
    int categoryId,
    String shopCode,
    List<int> filterIds,
    String deliveryType,
  ) async {
    final tagsQuery = filterIds.map((id) => '&tag=$id').join();
    final url =
        '$baseUrl/shops/$shopCode/products/?category=$categoryId$tagsQuery&available=$deliveryType';
    final response = await _httpClient.getRequest(url: url);
    final results = response['results'] as List;
    return results.map((e) => Product.fromJson(e)).toList();
  }

  Future<List<int>> fetchFilters(String shopCode) async {
    final response =
        await _httpClient.getRequest(url: '$baseUrl/shops/$shopCode/filters/');
    return List<int>.from(response as List);
  }

  Future<Product?> fetchProduct(
      String shopCode, int productId, String deliveryType) async {
    try {
      final response = await _httpClient.getRequest(
        url: '$baseUrl/shops/$shopCode/products/$productId/?available=$deliveryType',
      );
      return Product.fromJson(response as Map<String, dynamic>);
    } on Exception catch (_) {
      return null;
    }
  }

  // ── Stop-list / leftovers ─────────────────────────────────────────────────

  Future<List<int>> fetchStopList(String shopCode) async {
    final response =
        await _httpClient.getRequest(url: '$baseUrl/shops/$shopCode/stop-list/');
    return List<int>.from(response as List);
  }

  Future<Map<int, int>> fetchProductLeftovers(String shopCode) async {
    final response = await _httpClient.getRequest(
        url: '$baseUrl/shops/$shopCode/leftovers/');
    final map = response as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<ConfirmOrderResponse> confirmOrder(Map<String, dynamic> body) async {
    final response = await _httpClient.postRequest(
      '$baseUrl/orders/',
      body,
      throwClientErrorText: true,
      throwServerErrorText: true,
    );
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
          ? Order.fromJson(json['order'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<List<Map<String, dynamic>>> fetchOrderHistory(int page) async {
    final response = await _httpClient.getRequest(
      url: '$baseUrl/orders/?page=$page',
    );
    return List<Map<String, dynamic>>.from(response['results']);
  }

  // ── Promo / bonuses ───────────────────────────────────────────────────────

  Future<Discount> fetchPromocode(
      Map<String, dynamic> body, String shopCode) async {
    final response = await _httpClient.postRequest(
      '$baseUrl/shops/$shopCode/discounts/check/',
      body,
      throwClientErrorText: true,
    );
    final json = response as Map<String, dynamic>;
    return Discount(
      code: json['code'] as String?,
      type: DiscountType.values.byName(json['type'] as String? ?? 'percent'),
      amount: json['amount'] as int?,
      minOrderSum: json['min_order_sum'] as int?,
    );
  }

  Future<int> fetchBonuses() async {
    final response =
        await _httpClient.getRequest(url: '$baseUrl/loyalty/bonuses/');
    return (response['total'] as num).toInt();
  }

  Future<({int amount})> fetchEarnedPoints(
      String shopCode, Map<String, dynamic> body) async {
    final response = await _httpClient.postRequest(
      '$baseUrl/shops/$shopCode/earned-points/',
      body,
    );
    return (amount: (response['amount'] as num).toInt());
  }

  // ── Payment cards ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPaymentCards() async {
    final response =
        await _httpClient.getRequest(url: '$baseUrl/payment-cards/');
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> deletePaymentCard(int cardId) async {
    await _httpClient.deleteRequest('$baseUrl/payment-cards/$cardId/', {});
  }

  // ── System ────────────────────────────────────────────────────────────────

  Future<String?> getWarningMessage() async {
    try {
      // тоже на основном сайте, не в API-проекте
      final response = await http.get(
        Uri.parse('https://foodrun.ru/api/mobile-warning/'),
      );
      if (response.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body['message'];
      if (message is! String || message.isEmpty) return null;
      return message;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<bool?> canOrder(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://foodrun.ru/api/check-order-time/?restaurant=$restaurantId'),
      );
      if (response.statusCode != 200) return true;
      return jsonDecode(response.body)['can_order'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> checkMinPrice(int orderId) async {
    final response = await http.post(
      Uri.parse('https://foodrun.ru/api/check-min-price/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'order_id': orderId}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['ok'] == true) return null;
      return jsonDecode(utf8.decode(response.bodyBytes))['message'] as String?;
    }
    debugPrint(utf8.decode(response.bodyBytes));
    return null;
  }
}
