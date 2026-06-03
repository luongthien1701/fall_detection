import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/provider/fcm_provider.dart';
import 'package:fall_detect/provider/mqtt_provider.dart';
import 'package:fall_detect/screen/hazardous.dart';
import 'package:fall_detect/screen/history.dart';
import 'package:fall_detect/screen/home.dart';
import 'package:fall_detect/screen/hub.dart';
import 'package:fall_detect/screen/login.dart';
import 'package:fall_detect/screen/signup.dart';
import 'package:fall_detect/service/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final authProvider = AuthProvider();
  await authProvider.restoreSession();
  final fcmProvider = FcmProvider();
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    fcmProvider.setToken(fcmToken);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fcmProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProxyProvider<DeviceProvider, MqttProvider>(
          create: (_) => MqttProvider(),
          update: (_, deviceProvider, mqttProvider) {
            mqttProvider!.setDeviceProvider(deviceProvider);
            return mqttProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );

  await FcmService.init(
    FcmService.navigatorKey,
    canHandleAlert: () => authProvider.isLogin,
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmService.openPendingRoute();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FcmService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: context.read<AuthProvider>().isLogin ? '/hub' : '/login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/signup': (context) => const SignupWidget(),
        '/login': (context) => const LoginWidget(),
        '/home': (context) => const HomeWidget(),
        '/history': (context) => const HistoryWidget(),
        '/hazardous': (context) => const HazardousWidget(),
        '/hub': (context) => const HubWidget(),
      },
    );
  }
}
