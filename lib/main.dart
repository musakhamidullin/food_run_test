import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'package:food_run/controllers/auth_controller.dart';
import 'package:food_run/controllers/menu_controller.dart';
import 'package:food_run/controllers/order_controller.dart';
import 'package:food_run/controllers/order_history_controller.dart';
import 'package:food_run/controllers/payment_cards_controller.dart';
import 'package:food_run/controllers/profile_controller.dart';
import 'package:food_run/controllers/push_controller.dart';
import 'package:food_run/controllers/settings_controller.dart';
import 'package:food_run/controllers/shared_prefs_controller.dart';
import 'package:food_run/firebase_options.dart';
import 'package:food_run/push_notifications/local_notification_service.dart';
import 'package:food_run/screens/main_screen.dart';
import 'package:food_run/services/order_service.dart';
import 'package:food_run/services/order_status_mapper.dart';

const String pushBoxName = 'push_deeplink_box';
const String pushBoxKey = 'push_deeplink';

const String feedbackPushBoxName = 'feedback_push_box';
const String feedbackPushKey = 'feedback_push';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  if (!Platform.isAndroid) return;

  try {
    final isFeedback =
        message.notification?.body?.toLowerCase().contains('отзыв') ?? false;

    if (isFeedback) {
      final orderId = int.parse(message.data['order_id']);
      final path = (await getApplicationDocumentsDirectory()).path;
      await Hive.initFlutter(path);
      await Hive.openBox<int>(feedbackPushBoxName);
      await Hive.box<int>(feedbackPushBoxName).put(feedbackPushKey, orderId);
      return;
    }

    final isDeeplinkPush = message.data['deeplink'] != null;
    if (isDeeplinkPush) {
      final dataJson =
          jsonEncode(<String, String>{'deeplink': message.data['deeplink']});
      final path = (await getApplicationDocumentsDirectory()).path;
      await Hive.initFlutter(path);
      await Hive.openBox<String>(pushBoxName);
      await Hive.box<String>(pushBoxName).put(pushBoxKey, dataJson);
    }
  } catch (e) {
    // ignore
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const dsn = String.fromEnvironment('SENTRY_DSN');
  const environment =
      String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'development');

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn.isEmpty ? null : dsn;
      options.environment = environment;
      options.tracesSampleRate = environment == 'production' ? 0.05 : 1.0;
      options.debug = !const bool.fromEnvironment('dart.vm.product');
    },
    appRunner: () => runApp(const FoodRunApp()),
  );
}

class FoodRunApp extends StatefulWidget {
  const FoodRunApp({super.key});

  @override
  State<FoodRunApp> createState() => _FoodRunAppState();
}

class _FoodRunAppState extends State<FoodRunApp> {
  late FirebaseMessaging _messaging;

  Future<void>? _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const StartupSplash();
          }
          if (snap.hasError) {
            return BootstrapErrorScreen(
              error: snap.error,
              onRetry: () => setState(() {
                _bootstrapFuture = _bootstrap();
              }),
            );
          }
          return const MainScreen();
        },
      ),
    );
  }

  Future<void> _bootstrap() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // аналитика — ключ нельзя передавать через --dart-define,
    // AppMetrica не поддерживает это в текущей версии плагина
    await _initAnalytics('7f3a9b2e-4c81-4d7f-a3b2-9e1f0c8d5a72');

    final path = (await getApplicationDocumentsDirectory()).path;
    await Hive.initFlutter(path);
    await Hive.openBox<String>(pushBoxName);
    await Hive.openBox<int>(feedbackPushBoxName);

    await _registerDependencies();
    await _launchInitialRequests();
    await _initPushNotifications();
  }

  Future<void> _initAnalytics(String apiKey) async {
    // AppMetrica.activate(AppMetricaConfig(apiKey));
  }

  Future<void> _registerDependencies() async {
    await Get.putAsync<SharedPrefsController>(
      () async => SharedPrefsController(await SharedPreferences.getInstance()),
      permanent: true,
    );

    Get.put(SettingsController(), permanent: true);

    Get.lazyPut<OrderStatusMapper>(() => const OrderStatusMapper(),
        fenix: true);
    Get.lazyPut<OrderService>(() => OrderService(), fenix: true);

    Get.put(OrderController(Get.find<OrderService>()), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(MenuController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    Get.put(
      OrderHistoryController(
        Get.find<OrderService>(),
        Get.find<OrderStatusMapper>(),
      ),
      permanent: true,
    );
    Get.put(PaymentCardsController(), permanent: true);
    Get.put(PushController(), permanent: true);
    // TODO: добавить LoyaltyController после MVP
    // TODO: добавить MissionsController
  }

  Future<void> _launchInitialRequests() async {
    // порядок первых двух важен: настройки устанавливают токен,
    // OrderController его использует
    await Get.find<SettingsController>().init();
    await Get.find<OrderController>().init();
    await Get.find<PaymentCardsController>().init();

    Get.find<ProfileController>().init();
    Get.find<OrderHistoryController>().init();
    Get.find<AuthController>().init();
    Get.find<MenuController>().init();
    Get.find<PushController>().init();
  }

  Future<void> _initPushNotifications() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await LocalNotificationService().initialize();

    _messaging = FirebaseMessaging.instance;
    _messaging.getToken().then((token) {
      if (token != null) {
        Get.find<SharedPrefsController>().setFirebaseToken(token);
      }
    });

    FirebaseMessaging.onMessage.listen((event) {
      if (Platform.isAndroid) {
        LocalNotificationService.display(event);
      }
    });
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key});

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/splash.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
      })
      ..setLooping(true)
      ..play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen(
      {super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Не удалось запустить приложение',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(error?.toString() ?? 'Unknown error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
