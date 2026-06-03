import 'package:flutter/material.dart';
import 'package:fall_detect/service/authservice.dart';

class AuthProvider extends ChangeNotifier {
  int _userId = -1;
  String? _deviceCode;
  List<String> _deviceCodes = [];
  String _firstname = "";
  String _appPhone = "";
  String _relativePhone1 = "";
  String _relativePhone2 = "";

  int get userId => _userId;
  String? get deviceCode => _deviceCode;
  List<String> get deviceCodes => List.unmodifiable(_deviceCodes);
  String get firstname => _firstname;
  String get appPhone => _appPhone;
  String get phone => _appPhone;
  String get relativePhone1 => _relativePhone1;
  String get relativePhone2 => _relativePhone2;
  bool get isLogin => _userId != -1;
  bool get hasDevice => _deviceCodes.isNotEmpty;

  List<String> _parseDeviceCodes(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value.map((item) => item.toString()).toList();
  }

  void _setUserInfo(Map<String, dynamic> result) {
    _firstname = result["firstname"]?.toString() ?? "";
    _appPhone =
        result["app_phone"]?.toString() ?? result["phone"]?.toString() ?? "";
    _relativePhone1 = result["relative_phone_1"]?.toString() ?? "";
    _relativePhone2 = result["relative_phone_2"]?.toString() ?? "";
  }

  Future<String?> login(String email, String password, String fcmToken) async {
    Authservice authservice = Authservice();
    final result = await authservice.login(email, password, fcmToken);
    debugPrint("Login result: $result");
    if (result["success"] == true) {
      _userId = result["user_id"];
      _setUserInfo(result);
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
    String appPhone,
    String fcmToken,
  ) async {
    Authservice authservice = Authservice();
    final result = await authservice.signup(
      firstname,
      email,
      password,
      appPhone,
      fcmToken,
    );

    if (result["success"] == true) {
      _userId = result["user_id"];
      _setUserInfo(result);
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

  Future<String?> updateUserInfo(
    String firstname,
    String appPhone,
    String relativePhone1,
    String relativePhone2,
  ) async {
    Authservice authservice = Authservice();
    final result = await authservice.updateUser(
      _userId,
      firstname,
      appPhone,
      relativePhone1,
      relativePhone2,
    );

    if (result["success"] == true) {
      _setUserInfo(result);
      notifyListeners();
      return null;
    }

    return result["message"];
  }

  void logout() {
    final userId = _userId;
    if (userId != -1) {
      Authservice().logout(userId);
    }

    _userId = -1;
    _deviceCode = null;
    _deviceCodes = [];
    _firstname = "";
    _appPhone = "";
    _relativePhone1 = "";
    _relativePhone2 = "";
    notifyListeners();
  }
}
