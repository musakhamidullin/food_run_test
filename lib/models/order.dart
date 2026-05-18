class Order {
  final int id;
  final String status;
  final int totalPrice;
  final String createdAt;
  final String? orderType;
  final String? guestNumber;

  const Order({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.orderType,
    this.guestNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        status: json['status'] as String? ?? '',
        totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        orderType: json['order_type'] as String?,
        guestNumber: json['guest_number'] as String?,
      );
}
