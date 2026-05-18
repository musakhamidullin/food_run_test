import 'package:food_run/models/order_item.dart';
import 'package:food_run/models/product.dart';

class OrderService {
  void saveCart(List<OrderItem> items) {}

  List<OrderItem> loadCart() => [];

  void saveLoyaltyCart(List<OrderItem> items) {}

  List<OrderItem> loadLoyaltyCart() => [];

  /// Возвращает (итоговая сумма позиции, сумма без доп. позиций).
  (int total, int totalWithoutExtras) computeItemPrice(
    int amount,
    int price,
    double discountMultiplier,
    List<GroupMod> groupMods,
  ) {
    double modSum = groupMods
        .expand((gm) => gm.items)
        .fold(0.0, (s, item) => s + (item.price ?? 0));

    final total =
        ((price + modSum) * amount * discountMultiplier).round();
    return (total, total);
  }

  String formatModifierNames(List<GroupMod> groupMods) {
    final names = groupMods
        .expand((gm) => gm.items)
        .map((item) => item.name?.replaceFirst(RegExp(r'^-\s+'), '') ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    return '- ${names.join(', ')}';
  }
}
