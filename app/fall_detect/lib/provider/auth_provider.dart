import 'package:flutter/material.dart';
import 'package:fall_detect/service/authservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  int _userId = -1;
  String _email = "";
  String? _deviceCode;
  List<String> _deviceCodes = [];
  String _phone = "";
  String _relativePhone1 = "";
  String _relativePhone2 = "";

  int get userId => _userId;
  String get email => _email;
  String? get deviceCode => _deviceCode;
  List<String> get deviceCodes => List.unmodifiable(_deviceCodes);
  String get phone => _phone;
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
    _email = result["email"]?.toString() ?? _email;
    _phone = result["phone"]?.toString() ?? "";
    _relativePhone1 = result["relative_phone_1"]?.toString() ?? "";
    _relativePhone2 = result["relative_phone_2"]?.toString() ?? "";
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? -1;
    if (userId == -1) {
      return;
    }

    _userId = userId;
    _email = prefs.getString('email') ?? "";
    _phone = prefs.getString('phone') ?? "";
    _relativePhone1 = prefs.getString('relative_phone_1') ?? "";
    _relativePhone2 = prefs.getString('relative_phone_2') ?? "";
    _deviceCodes = prefs.getStringList('device_codes') ?? [];
    _deviceCode =
        prefs.getString('device_code') ??
        (_deviceCodes.isNotEmpty ? _deviceCodes.first : null);
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', _userId);
    await prefs.setString('email', _email);
    await prefs.setString('phone', _phone);
    await prefs.setString('relative_phone_1', _relativePhone1);
    await prefs.setString('relative_phone_2', _relativePhone2);
    await prefs.setStringList('device_codes', _deviceCodes);

    final deviceCode = _deviceCode;
    if (deviceCode == null || deviceCode.isEmpty) {
      await prefs.remove('device_code');
    } else {
      await prefs.setString('device_code', deviceCode);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('relative_phone_1');
    await prefs.remove('relative_phone_2');
    await prefs.remove('device_code');
    await prefs.remove('device_codes');
  }

  Future<String?> login(String email, String password, String fcmToken) async {
    Authservice authservice = Authservice();
    final result = await authservice.login(email, password, fcmToken);
    debugPrint("Login result: $result");
    if (result["success"] == true) {
      _userId = result["user_id"];
      _email = result["email"]?.toString() ?? email;
      _setUserInfo(result);
      _deviceCodes = _parseDeviceCodes(result["device_codes"]);
      _deviceCode =
          result["device_code"] ??
          (_deviceCodes.isNotEmpty ? _deviceCodes.first : null);
      await _saveSession();
      notifyListeners();
      return null;
    }
    return result["message"];
  }

  Future<String?> signup(
    String email,
    String password,
    String phone,
    String fcmToken,
  ) async {
    Authservice authservice = Authservice();
    final result = await authservice.signup(email, password, phone, fcmToken);

    if (result["success"] == true) {
      _userId = result["user_id"];
      _email = result["email"]?.toString() ?? email;
      _setUserInfo(result);
      _deviceCodes = _parseDeviceCodes(result["device_codes"]);
      _deviceCode = _deviceCodes.isNotEmpty ? _deviceCodes.first : null;
      await _saveSession();
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
      await _saveSession();
      notifyListeners();
      return null;
    }

    return result["message"];
  }

  Future<String?> updateUserInfo(
    String phone,
    String relativePhone1,
    String relativePhone2,
  ) async {
    Authservice authservice = Authservice();
    final result = await authservice.updateUser(
      _userId,
      phone,
      relativePhone1,
      relativePhone2,
    );

    if (result["success"] == true) {
      _setUserInfo(result);
      await _saveSession();
      notifyListeners();
      return null;
    }

    return result["message"];
  }

  Future<void> logout() async {
    final userId = _userId;
    if (userId != -1) {
      await Authservice().logout(userId);
    }

    _userId = -1;
    _email = "";
    _deviceCode = null;
    _deviceCodes = [];
    _phone = "";
    _relativePhone1 = "";
    _relativePhone2 = "";
    await _clearSession();
    notifyListeners();
  }
}
