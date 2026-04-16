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

  Future<Map<String, dynamic>> signup(
    String firstname,
    String email,
    String password,
    String phone,
    String fcmToken,
  ) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/api/auth/signup'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'firstname': firstname,
        'email': email,
        'password': password,
        'phone': phone,
        'fcm_token': fcmToken,
      }),
    );
    final data = jsonDecode(response.body);

    return data;
  }
}
