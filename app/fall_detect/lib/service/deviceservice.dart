import 'dart:convert';

import 'package:fall_detect/model/device.dart';
import 'package:fall_detect/model/history.dart';
import 'package:fall_detect/service/ip.dart';
import 'package:http/http.dart' as http;

class DeviceService {
  Future<Device> getStatusDevice() async {
    final response = await http.get(Uri.parse('${Ip.ip}/status'));
    if (response.statusCode == 200) {
      return Device.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch device status');
    }
  }

  Future<List<History>> getHistoryDevice() async {
    final response = await http.get(Uri.parse('${Ip.ip}/history'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => History.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to fetch device history');
    }
  }

  Future<bool> controlDevice(String command) async {
    final response = await http.post(
      Uri.parse('${Ip.ip}/control'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'command': command}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } else {
      throw Exception('Failed to control device');
    }
  }
}
