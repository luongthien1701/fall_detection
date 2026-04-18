import 'package:fall_detect/model/device.dart';
import 'package:fall_detect/model/history.dart';
import 'package:fall_detect/service/deviceservice.dart';
import 'package:flutter/material.dart';

class DeviceProvider extends ChangeNotifier {
  Device? _device;
  Device? get device => _device;
  List<History> _history = [];
  List<History> get history => _history;
  bool isLoading = false;
  Future<void> getStatus() async {
    isLoading = true;
    notifyListeners();
    print("Fetching device status...");
    try {
      _device = await DeviceService().getStatusDevice();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getHistory() async {
    _history = await DeviceService().getHistoryDevice();
    notifyListeners();
  }

  Future<bool> controlDevice(String command) async {
    try {
      return await DeviceService().controlDevice(command);
    } catch (e) {
      print("Error controlling device: $e");
      return false;
    }
  }
}
