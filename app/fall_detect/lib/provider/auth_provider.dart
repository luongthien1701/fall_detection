import 'package:flutter/material.dart';
import 'package:fall_detect/service/authservice.dart';

class AuthProvider extends ChangeNotifier {
  int _userId = -1;

  int get userId => _userId;
  bool get isLogin => _userId != -1;

  Future<String?> login(String email, String password, String fcmToken) async {
    Authservice authservice = Authservice();
    final result = await authservice.login(email, password, fcmToken);
    debugPrint("Login result: $result");
    if (result["success"] == true) {
      _userId = result["user_id"];
      notifyListeners();
      return null;
    }
    return result["message"];
  }

  Future<String?> signup(
    String firstname,
    String email,
    String password,
    String phone,
    String fcmToken,
  ) async {
    Authservice authservice = Authservice();
    final result = await authservice.signup(
      firstname,
      email,
      password,
      phone,
      fcmToken,
    );

    _userId = result["user_id"];
    notifyListeners(); // 🔥
    return result["message"];
  }

  void logout() {
    _userId = -1;
    notifyListeners();
  }
}
