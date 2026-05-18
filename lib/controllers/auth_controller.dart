import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:food_run/controllers/order_controller.dart';
import 'package:food_run/controllers/profile_controller.dart';
import 'package:food_run/controllers/settings_controller.dart';
import 'package:food_run/network/apis.dart';

class AuthController extends GetxController {
  final signinPageController = PageController();
  RxInt currentPageIndex = 0.obs;

  RxBool isFirstVisit = true.obs;

  final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '### ### ## ##',
    filter: {'#': RegExp('[0-9]')},
  );

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  RxString phoneError = ''.obs;
  RxString codeError = ''.obs;

  bool isLoggedIn = false;

  bool hasUserSeenOnboarding = false;

  String appVersion = '';

  DateTime? applicationLaunchTime;

  bool chekingCode = false;

  final _authEventController = StreamController<bool>();

  StreamSubscription<bool>? authEventSubscription;

  Stream<bool> get authStream async* {
    yield* _authEventController.stream;
  }

  Future<void> init() async {
    await setFirstVisitStatus();
    await returnAppVersion();
    setApplicationLaunchTime();
  }

  void setApplicationLaunchTime() {
    applicationLaunchTime = DateTime.now();
  }

  Future<void> returnAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion = info.version;
  }

  Future<void> setFirstVisitStatus() async {
    final token = Get.find<SettingsController>().token;
    isLoggedIn = token != null && token.isNotEmpty;
    isFirstVisit.value = !isLoggedIn;
  }

  Future<void> sendPhone() async {
    try {
      final phone = '7${phoneFormatter.getUnmaskedText()}';
      final body = <String, dynamic>{'phone': phone, 'source': 'app'};
      await Api().sendPhone(body);
      phoneError.value = '';
    } on Exception catch (_) {
      phoneError.value =
          'Произошла ошибка при проверке номера.\nПопробуйте позже.';
    }
  }

  Future<void> sendCode(BuildContext context) async {
    try {
      final phone = '7${phoneFormatter.getUnmaskedText()}';
      final code = codeController.text;

      chekingCode = true;
      update(['code_loader']);

      final body = {'phone': phone, 'code': code};
      final response = await Api().verifyCode(body);

      chekingCode = false;
      update(['code_loader']);

      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        codeError.value = 'Неверный код. Попробуйте ещё раз.';
        return;
      }

      await Get.find<SettingsController>().setToken(token);
      isLoggedIn = true;
      isFirstVisit.value = false;

      Get.find<ProfileController>().loadProfile();
      Get.find<OrderController>().onAuthSuccess();

      _authEventController.add(true);
    } on Exception catch (_) {
      chekingCode = false;
      update(['code_loader']);
      codeError.value = 'Произошла ошибка. Попробуйте позже.';
    }
  }

  void logout() {
    Get.find<SettingsController>().clearToken();
    isLoggedIn = false;
    isFirstVisit.value = true;
    currentPageIndex.value = 0;
    phoneController.clear();
    codeController.clear();
  }

  @override
  void onClose() {
    signinPageController.dispose();
    phoneController.dispose();
    codeController.dispose();
    _authEventController.close();
    authEventSubscription?.cancel();
    super.onClose();
  }
}
