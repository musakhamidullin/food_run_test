import 'package:food_run/models/product.dart';

class OrderItem {
  final int productId;
  final String productName;
  int amount;
  final int productPrice;
  final List<GroupMod> selectedGroupMods;
  final bool isPromoItem;
  final bool isLoyaltyItem;
  final int? linkedProductId;
  final String? image;
  final String modNames;
  int productSum;
  int productSumWithoutExtras;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.amount,
    required this.productPrice,
    required this.selectedGroupMods,
    this.isPromoItem = false,
    this.isLoyaltyItem = false,
    this.linkedProductId,
    this.image,
    this.modNames = '',
    int? productSum,
    int? productSumWithoutExtras,
  })  : productSum = productSum ?? 0,
        productSumWithoutExtras = productSumWithoutExtras ?? 0;

  bool get hasExtras => false;

  Map<String, dynamic> toOrderBody() => {
        'product': productId,
        'quantity': amount,
        'group_mods': selectedGroupMods
            .expand((gm) => gm.items)
            .map((item) => item.toJson())
            .toList(),
      };

  Map<String, dynamic> toComboBody() => {
        'product': productId,
        'quantity': amount,
      };
}
