import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FcmService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingRoute;

  static void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;

    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
  }

  static bool isFallAlert(RemoteMessage message) {
    final type = message.data['type'];
    final route = message.data['route'];
    return type == 'fall_alert' || route == '/hazardous';
  }

  static void _handleMessage(RemoteMessage message) {
    if (!isFallAlert(message)) {
      return;
    }
    openHazardous();
  }

  static void openHazardous() {
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
