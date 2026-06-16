import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingRoute;
  static bool Function() _canHandleAlert = () => true;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _fallAlertChannel =
      AndroidNotificationChannel(
        'fall_alerts',
        'Fall alerts',
        description: 'Fall detection alerts',
        importance: Importance.max,
        playSound: true,
      );

  static Future<void> init(
    GlobalKey<NavigatorState> key, {
    bool Function()? canHandleAlert,
  }) async {
    navigatorKey = key;
    _canHandleAlert = canHandleAlert ?? (() => true);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {
        openHazardous();
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_fallAlertChannel);

    FirebaseMessaging.onMessage.listen((message) {
      if (!_shouldHandleMessage(message)) {
        return;
      }
      _showLocalNotification(message);
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (!_shouldHandleMessage(message)) {
        return;
      }
      _handleMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && _shouldHandleMessage(message)) {
        _handleMessage(message);
      }
    });
  }

  static bool isFallAlert(RemoteMessage message) {
    final type = message.data['type'];
    final route = message.data['route'];
    return type == 'fall_alert' || route == '/hazardous';
  }

  static bool _shouldHandleMessage(RemoteMessage message) {
    return _canHandleAlert() && isFallAlert(message);
  }

  static void _handleMessage(RemoteMessage message) {
    openHazardous();
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'fall_alerts',
        'Fall alerts',
        channelDescription: 'Fall detection alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification?.title ?? 'Alert',
      notification?.body ?? 'Fall detected!',
      details,
    );
  }

  static void openHazardous() {
    if (!_canHandleAlert()) {
      return;
    }
    _pushOrQueue('/hazardous');
  }

  static void openPendingRoute() {
    final route = _pendingRoute;
    if (route == null) {
      return;
    }
    _pendingRoute = null;
    _pushOrQueue(route);
  }

  static void _pushOrQueue(String route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingRoute = route;
      WidgetsBinding.instance.addPostFrameCallback((_) => openPendingRoute());
      return;
    }

    final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
    if (currentRoute == route) {
      return;
    }

    navigator.pushNamed(route);
  }
}
