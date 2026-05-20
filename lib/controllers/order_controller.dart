import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:food_run/controllers/menu_controller.dart';
import 'package:food_run/controllers/payment_cards_controller.dart';
import 'package:food_run/controllers/profile_controller.dart';
import 'package:food_run/controllers/shared_prefs_controller.dart';
import 'package:food_run/controllers/settings_controller.dart';
import 'package:food_run/models/order.dart';
import 'package:food_run/models/order_item.dart';
import 'package:food_run/models/product.dart';
import 'package:food_run/network/api_exception.dart';
import 'package:food_run/network/apis.dart';
import 'package:food_run/network/ws_client.dart';
import 'package:food_run/screens/payment_screen.dart';
import 'package:food_run/screens/post_order_screen.dart';
import 'package:food_run/services/order_service.dart';
import 'package:food_run/services/order_status_mapper.dart';

class AddressException implements Exception {}

class ComputeBonusException implements Exception {}

enum PriceDropperType { bonus, discount, personalOffer }

class OrderController extends GetxController {
  OrderController(this._orderService);

  final OrderService _orderService;

  // ── Анимация экрана пост-заказа ───────────────────────────────────────────
  AnimationController? postOrderAnimationController;

  // ── Корзина: обычные товары ───────────────────────────────────────────────
  List<OrderItem> orderItemList = [];
  List<OrderItem> orderItemListCopy = [];

  // ── Корзина: loyalty-товары (оплата баллами) ──────────────────────────────
  RxList<OrderItem> loyaltyItemList = <OrderItem>[].obs;

  // ── Корзина: наборы (комбо) ───────────────────────────────────────────────
  List<OrderItem> comboItemList = [];
  List<OrderItem> comboItemListCopy = [];

  // ── Цены ─────────────────────────────────────────────────────────────────
  RxInt totalOrderPrice = 0.obs;
  int productsPrice = 0;
  RxInt totalLoyaltyItemsPrice = 0.obs;

  // ── Скидки / промокоды ────────────────────────────────────────────────────
  Discount? activeDiscount;
  final promoController = TextEditingController();
  RxString promoError = ''.obs;
  int discountSum = 0;

  // ── Бонусы ────────────────────────────────────────────────────────────────
  final bonusController = TextEditingController();
  int totalBonuses = 0;
  RxInt writtenOffBonuses = 0.obs;

  // ── Комментарий и вспомогательные флаги ──────────────────────────────────
  final commentController = TextEditingController();
  bool _isWithoutSaucePressed = false;

  bool inPlacePickup = true;

  RxInt cutleryCount = 0.obs;

  bool isNutrientsVisible = false;

  List<bool> checkboxStates = [true, true, true];

  // ── Стоп-лист и остатки ───────────────────────────────────────────────────
  List<int> stopList = [];
  Map<int, int> productLeftovers = {};

  // ── Заработанные баллы (debounced) ────────────────────────────────────────
  RxInt earnedPoints = 0.obs;
  Timer? _earnedPointsTimer;

  // ── WebSocket: текущий заказ ──────────────────────────────────────────────
  StreamSubscription? _wsSubscription;
  WsClient? _wsClient;

  // ── Типы активных скидок ──────────────────────────────────────────────────
  Set<PriceDropperType> priceDroppers = {};

  // ── Misc ──────────────────────────────────────────────────────────────────
  int? idOfLastOpenedComboPanel = -1;

  // ── Инициализация ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadSavedCart();
    await _fetchStopList();
    await fetchBonuses();
  }

  Future<void> _loadSavedCart() async {
    try {
      final prefs = Get.find<SharedPrefsController>();
      final savedItems = prefs.loadCart();
      if (savedItems.isNotEmpty) {
        orderItemList.addAll(savedItems);
        await _recalculate();
      }
      final savedLoyaltyItems = prefs.loadLoyaltyCart();
      loyaltyItemList.addAll(savedLoyaltyItems);
      _computeLoyaltyItemsPrice();
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> _fetchStopList() async {
    try {
      final shopCode = _currentShopCode();
      if (shopCode == null) return;
      stopList = await Api().fetchStopList(shopCode);
      productLeftovers = await Api().fetchProductLeftovers(shopCode);
      update(['basket']);
    } on Exception catch (_) {
      return;
    }
  }

  // ── Комментарий / соус ────────────────────────────────────────────────────

  void onWithoutSauceButtonTap() {
    _isWithoutSaucePressed = !_isWithoutSaucePressed;
    update(['without_sauce_button']);

    if (_isWithoutSaucePressed) {
      commentController.text = 'Без соуса. ${commentController.text}';
    } else {
      commentController.text =
          commentController.text.replaceFirst(RegExp(r'^Без соуса\.\s*'), '');
    }
  }

  bool get withoutSauceButtonIsActive {
    return _isWithoutSaucePressed &&
        commentController.text.contains('Без соуса.');
  }

  // ── Промокод ──────────────────────────────────────────────────────────────

  Future<void> applyPromo(BuildContext context) async {
    if (promoController.text.isEmpty) return;

// временно отключили 5.10.2024 — бонусы и промокод конфликтуют на бэке
    // await _ensureNoBonusesApplied(context);

    try {
      priceDroppers.add(PriceDropperType.discount);

      final discount = await _fetchDiscount();
      activeDiscount = discount;
      promoError.value = '';
      update(['promo']);

      if (discount.type == DiscountType.product) {
        final price = discount.amount ?? 0;
        await addProductToCart(
          discount.product!,
          amount: 1,
          isPromoItem: true,
          promoPrice: price,
        );
      } else {
        await _recalculate();
      }

      _sendAnalyticsEvent('promo_applied', {'code': promoController.text});
    } on ClientErrorException catch (e) {
      final error = (e.error as Map<String, dynamic>)['error'] as String? ?? '';
      promoError.value = error;
      await _showAlert(context, title: 'Ошибка', body: error);
      await _cancelDiscountAndCleanUp();
      rethrow;
    } on Exception catch (_) {
      await _cancelDiscountAndCleanUp();
      rethrow;
    }
  }

  Future<Discount> _fetchDiscount() async {
    final items = orderItemList
        .map((item) => {'id': item.productId, 'quantity': item.amount})
        .toList();

    final body = {
      'discount_code': promoController.text,
      'items': items,
      'available': _deliveryTypeString(),
    };

    return await Api().fetchPromocode(body, _currentShopCode() ?? 'main');
  }

  Future<void> _ensureNoBonusesApplied(BuildContext context) async {
    if (writtenOffBonuses.value == 0) return;
    await _showAlert(
      context,
      title: 'Внимание',
      body: 'Невозможно применить промокод: уже применены бонусы',
    );
    throw Exception();
  }

  Future<void> _cancelDiscountAndCleanUp() async {
    activeDiscount = null;
    discountSum = 0;
    priceDroppers.remove(PriceDropperType.discount);
    promoController.clear();
    orderItemList.removeWhere((item) => item.isPromoItem);
    await _recalculate();
  }

  // ── Бонусы ────────────────────────────────────────────────────────────────

  Future<void> fetchBonuses() async {
    try {
      final bonuses = await Api().fetchBonuses();
      totalBonuses = bonuses;
      update(['bonuses']);
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> applyBonuses(BuildContext context) async {
    try {
      final bonusesRequested = int.tryParse(bonusController.text) ?? 0;
      if (bonusesRequested <= 0) return;

      final available = totalBonuses - totalLoyaltyItemsPrice.value;
      if (bonusesRequested > available) {
        await _showAlert(context, title: 'Внимание', body: 'Не хватает баллов');
        return;
      }

      writtenOffBonuses.value = bonusesRequested;
      priceDroppers.add(PriceDropperType.bonus);
      await _recalculate(context: context);
    } on ComputeBonusException catch (_) {
      await _recoverCart(context);
    }
  }

  Future<void> removeBonuses() async {
    writtenOffBonuses.value = 0;
    bonusController.clear();
    priceDroppers.remove(PriceDropperType.bonus);
    await _recalculate();
  }

  // ── Добавление в корзину ──────────────────────────────────────────────────

  Future<void> addProductToCart(
    Product product, {
    int amount = 1,
    bool isPromoItem = false,
    int? promoPrice,
    List<GroupMod>? groupMods,
  }) async {
    try {
      final price = isPromoItem
          ? (promoPrice ?? 0)
          : (product.minPriceWithGroupMods ?? product.price ?? 0);

      final discount = _loyaltyDiscountFor(product.id);
      final mods = groupMods ?? [];

      final (total, totalWithoutExtras) =
          _orderService.computeItemPrice(amount, price, discount, mods);

      final modNames = _orderService.formatModifierNames(mods);

      final item = OrderItem(
        productId: product.id,
        productName: product.name,
        amount: amount,
        productPrice: price,
        selectedGroupMods: mods,
        isPromoItem: isPromoItem,
        productSum: total,
        productSumWithoutExtras: totalWithoutExtras,
        image: product.image,
        modNames: modNames,
      );

      orderItemList.add(item);

      update(['button${product.id}', 'basket', 'quantity']);

      await _recalculate();
      await _saveCart();

      if (orderItemList.length == 1) {
        _fetchRecommendations(product.id);
      }

      _sendAnalyticsEvent('add_to_cart', {
        'product_id': product.id,
        'product_name': product.name,
        'price': price,
      });
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> addLoyaltyProductToCart(Product product) async {
    try {
      await _ensureEnoughPoints(product.price ?? 0);

      final item = OrderItem(
        productId: product.id,
        productName: product.name,
        amount: 1,
        productPrice: product.price ?? 0,
        selectedGroupMods: [],
        isLoyaltyItem: true,
      );

      loyaltyItemList.add(item);
      _computeLoyaltyItemsPrice();
      await _recalculate();
      await _saveLoyaltyCart();
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> _ensureEnoughPoints(int price) async {
    final willSpend =
        totalLoyaltyItemsPrice.value + price + writtenOffBonuses.value;
    if (totalBonuses >= willSpend) return;

    await Get.defaultDialog(
      title: 'Внимание',
      content: const Text('Не хватает баллов'),
      confirm: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Закрыть'),
      ),
    );
    throw Exception();
  }

  // ── Изменение количества ──────────────────────────────────────────────────

  Future<void> incrementItem(
    BuildContext context,
    OrderItem item,
    int leftover,
  ) async {
    final canIncrement = await _canIncrement(context, leftover, item.amount);
    if (!canIncrement) return;

    item.amount++;
    _updateItemSum(item);

    update(['button${item.productId}', 'basket', 'quantity']);
    await _recalculate();
    await _saveCart();

    _sendAnalyticsEvent('add_to_cart', {
      'product_id': item.productId,
      'product_name': item.productName,
    });
  }

  Future<bool> _canIncrement(
      BuildContext context, int leftover, int inCart) async {
    if (leftover > inCart) return true;
    await _showAlert(
      context,
      title: 'Внимание',
      body: 'Превышено количество доступного товара',
    );
    return false;
  }

  Future<void> decrementItem(BuildContext context, OrderItem item) async {
    try {
      if (item.amount <= 1) {
        orderItemList.remove(item);

        final basketEmpty = orderItemList.isEmpty &&
            loyaltyItemList.isEmpty &&
            comboItemList.isEmpty;

        if (basketEmpty) {
          await _fullCleanUp();
        } else if (item.hasExtras) {
          _removeExtrasFor(item);
        }
      } else {
        item.amount--;
        _updateItemSum(item);
      }

      await _recalculate(context: context);
      await _saveCart();
      await _checkPromoStillValid(context);

      update(['button${item.productId}', 'basket', 'quantity']);
    } on ComputeBonusException catch (_) {
      await _recoverCart(context);
    }
  }

  // ── Оформление заказа ─────────────────────────────────────────────────────

  Future<void> confirmOrder(BuildContext context) async {
    try {
      _setLoader(true, context);

      final address = _requireAddress();
      final productsReady = await _checkStopList(context);
      if (!productsReady) {
        _setLoader(false, context);
        return;
      }

      final orderItems = orderItemList
          .where((i) => !i.isPromoItem && !i.isLoyaltyItem)
          .map((i) => i.toOrderBody())
          .toList();
      orderItems.addAll(loyaltyItemList.map((i) => i.toOrderBody()));

      final comboItems = comboItemList.map((i) => i.toComboBody()).toList();

      final appInfo = await _appInfo();

      final discountCode = activeDiscount?.code ??
          Get.find<SettingsController>().personalOfferCode;

      final cardId = Get.find<PaymentCardsController>().selectedCardId;

      final body = {
        'shop': address.shopId,
        'items': orderItems,
        'combos': comboItems,
        'bonuses': totalLoyaltyItemsPrice.value + writtenOffBonuses.value,
        'delivery_type': _deliveryTypeString(),
        'discount_code': discountCode,
        'comment': commentController.text,
        'device_id': Get.find<SharedPrefsController>().getFirebaseToken() ?? '',
        'app_version': appInfo,
        'cutlery': cutleryCount.value,
        if (cardId != null && !cardId.isNegative) 'card_id': cardId,
        if (address.street != null) 'street': address.street,
        if (address.house != null) 'house': address.house,
        if (address.flat != null) 'flat': address.flat,
        if (address.longitude != null) 'longitude': address.longitude,
        if (address.latitude != null) 'latitude': address.latitude,
        'with_group_mods': true,
      };

      final result = await Api().confirmOrder(body);

      if (result.closed != null) {
        _setLoader(false, context);
        await _showAlert(context,
            title: 'Внимание', body: result.closed!.message);
        return;
      }

      final paymentUrl = result.paymentUrl;
      if (paymentUrl == null) {
        _setLoader(false, context);
        throw Exception('No payment URL');
      }

      _setLoader(false, context);

      final answer = await Get.to(
        () => PaymentScreen(url: paymentUrl, orderId: result.orderId),
      );

      if (answer != 'success') return;

      await _fullCleanUp();
      await _openPostOrderScreen(context, result.order!);

      fetchBonuses();
    } on ClientErrorException catch (e) {
      _setLoader(false, context);
      final msg = (e.error as Map?)?.containsKey('error') == true
          ? e.error['error'] as String
          : null;
      await _showOrderError(context, msg);
    } on ServerErrorException catch (e) {
      _setLoader(false, context);
      final msg = (e.error as Map?)?.containsKey('error') == true
          ? e.error['error'] as String
          : null;
      await _showOrderError(context, msg);
    } on AddressException catch (_) {
      _setLoader(false, context);
      await _showAlert(context, title: 'Ошибка', body: 'Укажите адрес заказа');
    } on Exception catch (_) {
      _setLoader(false, context);
      await _showOrderError(context, null);
    }
  }

// нужная вещь — закомментированный mock для отладки без реального бэкенда
  // Future<void> _mockConfirmOrder(BuildContext context) async {
  //   final fakeResponse = {
  //     'id': 102345,
  //     'payment_url': 'https://pay.foodrun.ru/mock',
  //     'order': {
  //       'id': 102345,
  //       'status': 1,
  //       'items': [
  //         {
  //           'id': 555,
  //           'product': {
  //             'id': 101,
  //             'name': 'Бургер классик',
  //             'price': 299,
  //           }
  //         },
  //       ],
  //     },
  //   };
  //   // ...
  // }

  Future<void> _openPostOrderScreen(BuildContext context, Order order) async {
    final isPickup = order.orderType != 'delivery';

    // регистрируем зависимости для экрана статуса
    if (Get.isRegistered<ActualOrderStatusController>()) {
      // force:true — контроллер пересоздаётся при каждом новом заказе,
      // а не переиспользуется от предыдущего
      await Get.delete<ActualOrderStatusController>(force: true);

      print(Get.isRegistered<ActualOrderStatusController>()); // проверочный лог
    }

    final wsClient = WsClient();
    _wsClient = wsClient;

    Get.put(
      ActualOrderStatusController(
        wsClient: wsClient,
        mapper: Get.find<OrderStatusMapper>(),
        orderId: order.id,
        isPickup: isPickup,
      ),
      permanent: true,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      transitionAnimationController: postOrderAnimationController,
      builder: (_) => PostOrderScreen(order: order),
    );
  }

  // ── Проверка стоп-листа перед отправкой ───────────────────────────────────

  Future<bool> _checkStopList(BuildContext context) async {
    stopList.clear();
    productLeftovers.clear();

    final allItems = [...orderItemList, ...comboItemList];

    for (final item in allItems) {
      if (item.isPromoItem || item.isLoyaltyItem) continue;

      final product = await _fetchProduct(item.productId);

      if (product == null) {
        stopList.add(item.productId);
        continue;
      }

      final available = product.balance ?? 9999;
      if (item.amount > available) {
        productLeftovers[product.id] = available;
      }
    }

    if (stopList.isEmpty && productLeftovers.isEmpty) return true;

    await _showAlert(
      context,
      title: 'Внимание',
      body:
          'Некоторых товаров нет в наличии или не хватает нужного количества. '
          'Проверьте корзину.',
    );

    update(['basket']);
    return false;
  }

  Future<Product?> _fetchProduct(int productId) async {
    try {
      final shopCode = _currentShopCode() ?? 'main';
      return await Api()
          .fetchProduct(shopCode, productId, _deliveryTypeString());
    } on Exception catch (_) {
      return null;
    }
  }

  // ── Пересчёт цены ─────────────────────────────────────────────────────────

  Future<void> _recalculate({BuildContext? context}) async {
    try {
      await _computeOrderPrice(context: context);
      _computeLoyaltyItemsPrice();
      update(['basket_button', 'total_price', 'basket_info']);
      await _scheduleEarnedPointsFetch();
      await Get.find<ProfileController>().fetchCashback();
    } on ComputeBonusException catch (_) {
      rethrow;
    }
  }

  Future<void> _computeOrderPrice({BuildContext? context}) async {
    productsPrice = 0;

    for (final item in orderItemList) {
      productsPrice += item.productSum;
    }
    for (final item in comboItemList) {
      productsPrice += item.productSum;
    }

    int bonusDeduction = writtenOffBonuses.value;

    if (bonusDeduction > productsPrice) {
      if (context != null) {
        await _showAlert(
          context,
          title: 'Внимание',
          body: 'Сумма бонусов превышает сумму заказа',
        );
      }
      writtenOffBonuses.value = 0;
      bonusController.clear();
      priceDroppers.remove(PriceDropperType.bonus);
      bonusDeduction = 0;
      throw ComputeBonusException();
    }

    totalOrderPrice.value = productsPrice - discountSum - bonusDeduction;
    if (totalOrderPrice.value < 0) totalOrderPrice.value = 0;
  }

  void _computeLoyaltyItemsPrice() {
    int sum = 0;
    for (final item in loyaltyItemList) {
      sum += item.productPrice * item.amount;
    }

    // если в корзине только loyalty-товары без обычных — вычитаем 1 рубль,
    // чтобы бэкенд не считал заказ нулевым и не блокировал его
    totalLoyaltyItemsPrice.value =
        (orderItemList.isEmpty && comboItemList.isEmpty) ? sum - 1 : sum;

    update(['basket_info']);
  }

  Future<void> _scheduleEarnedPointsFetch() async {
    _earnedPointsTimer?.cancel();
    _earnedPointsTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final shopCode = _currentShopCode();
        if (shopCode == null) return;
        final body = {'full_price': totalOrderPrice.value};
        final result = await Api().fetchEarnedPoints(shopCode, body);
        earnedPoints.value = result.amount;
      } on Exception catch (_) {
        earnedPoints.value = 0;
      }
    });
  }

  // ── Очистка ───────────────────────────────────────────────────────────────

  Future<void> _fullCleanUp() async {
    final prefs = Get.find<SharedPrefsController>();

    orderItemList.clear();
    orderItemListCopy.clear();
    loyaltyItemList.clear();
    comboItemList.clear();
    comboItemListCopy.clear();

    await prefs.clearCart();
    await prefs.clearLoyaltyCart();

    totalOrderPrice.value = 0;
    productsPrice = 0;
    earnedPoints.value = 0;
    writtenOffBonuses.value = 0;

    await _cancelDiscountAndCleanUp();

    commentController.clear();
    stopList.clear();
    productLeftovers.clear();
    priceDroppers.clear();

    update(['basket', 'quantity']);
  }

  Future<void> _recoverCart(BuildContext context) async {
    orderItemList.clear();
    orderItemList.addAll(orderItemListCopy);
    await _recalculate(context: context);
    update(['basket']);
  }

  // ── Рекомендации ──────────────────────────────────────────────────────────

  void _fetchRecommendations(int productId) {
    try {
      final menuCtrl = Get.find<MenuController>();
      final sauceCategoryId = menuCtrl.categoriesList
          .firstWhereOrNull((cat) => cat.name.toLowerCase().startsWith('соус'))
          ?.id;

      // TODO: добавить RecommendedSectionController
      if (sauceCategoryId != null) {
        // Get.find<RecommendedController>().fetchSauces(sauceCategoryId);
      }
    } on Exception catch (_) {
      return;
    }
  }

  // ── Вспомогательное ───────────────────────────────────────────────────────

  void refreshLeftovers() {
    update(['basket', 'quantity']);
  }

  void onAuthSuccess() {
    _recalculate();
  }

  void changePickupType({required bool inPlace}) {
    inPlacePickup = inPlace;
    update(['pickup_type']);
  }

  void changeCutlery(int delta) {
    final next = cutleryCount.value + delta;
    if (next < 0) return;
    cutleryCount.value = next;
    update(['cutlery']);
  }

  void toggleNutrients() {
    isNutrientsVisible = !isNutrientsVisible;
    update(['nutrients']);
  }

  void changeCheckbox(int index) {
    checkboxStates[index] = !checkboxStates[index];
    update(['checkbox']);
  }

  double _loyaltyDiscountFor(int productId) {
    // TODO: получать через FavouriteProductController после разделения контроллеров
    return 1.0;
  }

  void _updateItemSum(OrderItem item) {
    final (total, totalWithoutExtras) = _orderService.computeItemPrice(
      item.amount,
      item.productPrice,
      1.0,
      item.selectedGroupMods,
    );
    item.productSum = total;
    item.productSumWithoutExtras = totalWithoutExtras;
  }

  void _removeExtrasFor(OrderItem item) {
    orderItemList.removeWhere(
      (i) => i.isPromoItem && i.linkedProductId == item.productId,
    );
  }

  Future<void> _checkPromoStillValid(BuildContext context) async {
    final isProduct = activeDiscount?.type == DiscountType.product;
    if (!isProduct) return;

    final minSum = activeDiscount!.minOrderSum ?? 0;
    if (totalOrderPrice.value >= minSum) return;

    final text = promoController.text.isEmpty
        ? 'Персональное предложение действует только при заказе от $minSum ₽'
        : 'Промокод действует только при заказе от $minSum ₽';

    await _showAlert(context, title: 'Внимание', body: text);
    orderItemList.removeWhere((i) => i.isPromoItem);
    await _cancelDiscountAndCleanUp();
  }

  SavedAddress _requireAddress() {
    final address = Get.find<SharedPrefsController>().getSelectedAddress();
    if (address == null) throw AddressException();
    return address as SavedAddress;
  }

  String _deliveryTypeString() {
    final isPickup = Get.find<SettingsController>().isPickup;
    final isInPlacePickup = isPickup && inPlacePickup;
    if (!isPickup) return 'DeliveryByCourier';
    if (isInPlacePickup) return 'pickup_on_tray';
    return 'packed_pickup';
  }

  String? _currentShopCode() {
    return Get.find<SettingsController>().currentShopCode;
  }

  Future<String> _appInfo() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      return 'FoodRun $version, Android ${android.version.release} '
          '(SDK ${android.version.sdkInt}), '
          '${android.manufacturer} ${android.model}';
    } else {
      final ios = await DeviceInfoPlugin().iosInfo;
      return 'FoodRun $version, ${ios.systemName} ${ios.systemVersion}, '
          '${ios.name} ${ios.model}';
    }
  }

  void _setLoader(bool value, BuildContext context) {
    update(['loader']);
  }

  Future<void> _showAlert(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        backgroundColor: Colors.white,
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text('Закрыть'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderError(BuildContext context, String? msg) async {
    await _showAlert(
      context,
      title: 'Ошибка',
      body: msg ??
          'При оформлении заказа произошла ошибка. '
              'Попробуйте позже или обратитесь в поддержку.',
    );
  }

  void _sendAnalyticsEvent(String name, Map<String, dynamic> params) {
    // AppMetrica.reportEvent(name, params);
  }

  Future<void> _saveCart() async {
    final itemsToSave = orderItemList.where((i) => !i.isPromoItem).toList();
    Get.find<SharedPrefsController>().saveCart(itemsToSave);
  }

  Future<void> _saveLoyaltyCart() async {
    Get.find<SharedPrefsController>().saveLoyaltyCart(loyaltyItemList);
  }

  @override
  void onClose() {
    commentController.dispose();
    promoController.dispose();
    bonusController.dispose();
    _earnedPointsTimer?.cancel();
    _wsSubscription?.cancel();
    super.onClose();
  }
}

// ── Вспомогательные типы ─────────────────────────────────────────────────────

class Discount {
  final String? code;
  final DiscountType type;
  final int? amount;
  final int? minOrderSum;
  final Product? product;

  const Discount({
    this.code,
    required this.type,
    this.amount,
    this.minOrderSum,
    this.product,
  });
}

enum DiscountType { percent, fixed, product }

class SavedAddress {
  final int shopId;
  final String? street;
  final String? house;
  final String? flat;
  final double? longitude;
  final double? latitude;

  const SavedAddress({
    required this.shopId,
    this.street,
    this.house,
    this.flat,
    this.longitude,
    this.latitude,
  });
}

class ClosedRestaurantResponse {
  final String message;
  const ClosedRestaurantResponse(this.message);
}

class ConfirmOrderResponse {
  final String? paymentUrl;
  final int orderId;
  final Order? order;
  final ClosedRestaurantResponse? closed;

  const ConfirmOrderResponse({
    this.paymentUrl,
    required this.orderId,
    this.order,
    this.closed,
  });
}

class ActualOrderStatusController extends GetxController {
  ActualOrderStatusController({
    required WsClient wsClient,
    required OrderStatusMapper mapper,
    required int orderId,
    required bool isPickup,
  });
}
