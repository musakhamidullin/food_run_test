enum OrderUiMode { normal, canceled }

class OrderStatusMapper {
  const OrderStatusMapper();

  static const _pickupSteps = [
    _StepInfo('Принят', 'ic_processing.svg'),
    _StepInfo('Готовится', 'ic_cooking.svg'),
    _StepInfo('Готов к выдаче', 'ic_ready.svg'),
    _StepInfo('Выдан', 'ic_done.svg'),
  ];

  static const _deliverySteps = [
    _StepInfo('Принят', 'ic_processing.svg'),
    _StepInfo('Готовится', 'ic_cooking.svg'),
    _StepInfo('У курьера', 'ic_courier.svg'),
    _StepInfo('Доставлен', 'ic_done.svg'),
  ];

  StatusUiModel map({
    required bool isPickup,
    required int backendStatus,
    required String orderNumber,
  }) {
    if (_isCanceled(backendStatus)) {
      return _buildCanceledModel(isPickup, orderNumber);
    }

    final stepIndex = _toStepIndex(isPickup: isPickup, status: backendStatus);
    final defs = isPickup ? _pickupSteps : _deliverySteps;

    final steps = List<StatusUiStep>.generate(defs.length, (i) {
      return StatusUiStep(
        name: defs[i].name,
        icon: defs[i].icon,
        isActive: i == stepIndex,
        isCompleted: i < stepIndex,
      );
    });

    final title = (stepIndex >= 0 && stepIndex < defs.length)
        ? defs[stepIndex].name
        : defs.first.name;

    return StatusUiModel(
      title: title,
      steps: steps,
      mode: OrderUiMode.normal,
      activeStepIndex: stepIndex,
      orderNumber: orderNumber,
    );
  }

  int _toStepIndex({required bool isPickup, required int status}) {
    if (isPickup) {
      if (status <= 4 || status == 6) return 0;
      if (status == 9) return 1;
      if (status == 10) return 2;
      return 3;
    } else {
      if (status <= 4 || status == 6) return 0;
      if (status == 9) return 1;
      if (status == 7) return 2;
      return 3;
    }
  }

  bool _isCanceled(int status) => status == 8;

  StatusUiModel _buildCanceledModel(bool isPickup, String orderNumber) {
    final defs = isPickup ? _pickupSteps : _deliverySteps;
    final steps = defs
        .map((d) => StatusUiStep(
              name: d.name,
              icon: d.icon,
              isActive: false,
              isCompleted: false,
            ))
        .toList();

    return StatusUiModel(
      title: 'Заказ отменён',
      steps: steps,
      mode: OrderUiMode.canceled,
      activeStepIndex: null,
      orderNumber: orderNumber,
    );
  }
}

class _StepInfo {
  final String name;
  final String icon;
  const _StepInfo(this.name, this.icon);
}

class StatusUiModel {
  final String title;
  final List<StatusUiStep> steps;
  final OrderUiMode mode;
  final int? activeStepIndex;
  final String orderNumber;

  const StatusUiModel({
    required this.title,
    required this.steps,
    required this.mode,
    required this.activeStepIndex,
    required this.orderNumber,
  });
}

class StatusUiStep {
  final String name;
  final String icon;
  final bool isActive;
  final bool isCompleted;

  const StatusUiStep({
    required this.name,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
  });
}
