import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FcmService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;

    FirebaseMessaging.onMessage.listen((message) {
      navigatorKey.currentState?.pushNamed('/hazardous');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.pushNamed('/hazardous');
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        navigatorKey.currentState?.pushNamed('/hazardous');
      }
    });
  }
}