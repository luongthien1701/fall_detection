import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/fcm_provider.dart';
import 'package:fall_detect/screen/hazardous.dart';
import 'package:fall_detect/screen/history.dart';
import 'package:fall_detect/screen/home.dart';
import 'package:fall_detect/screen/login.dart';
import 'package:fall_detect/screen/signup.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FcmProvider()), 
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/signup': (context) => const SignupWidget(),
        '/login': (context) => const LoginWidget(),
        '/home': (context) => const HomeWidget(),
        '/history': (context) => const HistoryWidget(),
        '/hazardous': (context) => const HazardousWidget(),
      },
    );
  }
}
