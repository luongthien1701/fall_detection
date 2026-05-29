import 'package:flutter/material.dart';
import 'package:fall_detect/service/authservice.dart';

class AuthProvider extends ChangeNotifier {
  int _userId = -1;
  String? _deviceCode;
  List<String> _deviceCodes = [];

  int get userId => _userId;
  String? get deviceCode => _deviceCode;
  List<String> get deviceCodes => List.unmodifiable(_deviceCodes);
  bool get isLogin => _userId != -1;
  bool get hasDevice => _deviceCodes.isNotEmpty;

  List<String> _parseDeviceCodes(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value.map((item) => item.toString()).toList();
  }

  Future<String?> login(String email, String password, String fcmToken) async {
    Authservice authservice = Authservice();
    final result = await authservice.login(email, password, fcmToken);
    debugPrint("Login result: $result");
    if (result["success"] == true) {
      _userId = result["user_id"];
      _deviceCodes = _parseDeviceCodes(result["device_codes"]);
      _deviceCode =
          result["device_code"] ??
          (_deviceCodes.isNotEmpty ? _deviceCodes.first : null);
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

    if (result["success"] == true) {
      _userId = result["user_id"];
      _deviceCodes = _parseDeviceCodes(result["device_codes"]);
      _deviceCode = _deviceCodes.isNotEmpty ? _deviceCodes.first : null;
      notifyListeners();
    }
    return result["message"];
  }

  Future<String?> connectDevice(String deviceCode) async {
    Authservice authservice = Authservice();
    final result = await authservice.connectDevice(_userId, deviceCode);

    if (result["success"] == true) {
      _deviceCodes = _parseDeviceCodes(result["device_codes"]);
      _deviceCode = result["device_code"] ?? deviceCode;
      if (!_deviceCodes.contains(_deviceCode)) {
        _deviceCodes = [..._deviceCodes, _deviceCode!];
      }
      notifyListeners();
      return null;
    }

    return result["message"];
  }

  void logout() {
    _userId = -1;
    _deviceCode = null;
    _deviceCodes = [];
    notifyListeners();
  }
}
