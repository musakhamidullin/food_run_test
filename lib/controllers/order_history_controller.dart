import 'package:get/get.dart';
import 'package:food_run/services/order_service.dart';
import 'package:food_run/services/order_status_mapper.dart';

class OrderHistoryController extends GetxController {
  OrderHistoryController(this._service, this._mapper);

  final OrderService _service;
  final OrderStatusMapper _mapper;

  Future<void> init() async {
    // загрузка истории заказов
  }
}
