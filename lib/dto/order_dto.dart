import 'package:json_annotation/json_annotation.dart';
import 'package:food_run/models/order.dart';

part 'order_dto.g.dart';

@JsonSerializable()
class OrderDto {
  final int id;
  @JsonKey(defaultValue: '')
  final String status;
  @JsonKey(name: 'total_price', defaultValue: 0)
  final int totalPrice;
  @JsonKey(name: 'created_at', defaultValue: '')
  final String createdAt;
  @JsonKey(name: 'order_type')
  final String? orderType;
  @JsonKey(name: 'guest_number')
  final String? guestNumber;

  const OrderDto({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.orderType,
    this.guestNumber,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);

  Order toEntity() => Order(
        id: id,
        status: status,
        totalPrice: totalPrice,
        createdAt: createdAt,
        orderType: orderType,
        guestNumber: guestNumber,
      );

  factory OrderDto.fromEntity(Order entity) => OrderDto(
        id: entity.id,
        status: entity.status,
        totalPrice: entity.totalPrice,
        createdAt: entity.createdAt,
        orderType: entity.orderType,
        guestNumber: entity.guestNumber,
      );
}
