import "dart:convert";

import "package:fall_detect/service/ip.dart";
import "package:http/http.dart" as http;

class Authservice {
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "fcm_token": token,
      }),
    );

    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> logout(int userId) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/auth/logout'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'user_id': userId}),
    );

    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> signup(
    String email,
    String password,
    String phone,
    String fcmToken,
  ) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/auth/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'password': password,
        'phone': phone,
        'fcm_token': fcmToken,
      }),
    );
    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> updateUser(
    int userId,
    String phone,
    String relativePhone1,
    String relativePhone2,
  ) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/user/update'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'user_id': userId,
        'phone': phone,
        'relative_phone_1': relativePhone1,
        'relative_phone_2': relativePhone2,
      }),
    );

    final data = jsonDecode(response.body);

    return data;
  }

  Future<Map<String, dynamic>> connectDevice(
    int userId,
    String deviceCode,
  ) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/device/connect'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "device_code": deviceCode}),
    );

    final data = jsonDecode(response.body);

    return data;
  }
}
