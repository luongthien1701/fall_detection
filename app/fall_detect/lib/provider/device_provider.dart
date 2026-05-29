import 'package:fall_detect/model/device.dart';
import 'package:fall_detect/model/history.dart';
import 'package:fall_detect/service/deviceservice.dart';
import 'package:flutter/material.dart';

class DeviceProvider extends ChangeNotifier {
  Device? _device;
  Device? get device => _device;
  String? _deviceCode;
  String? get deviceCode => _deviceCode;
  List<History> _history = [];
  List<History> get history => _history;
  bool isLoading = false;

  void setDeviceCode(String? deviceCode) {
    _deviceCode = deviceCode;
    if (deviceCode == null || deviceCode.isEmpty) {
      _device = null;
      _history = [];
    }
    notifyListeners();
  }

  Future<void> getStatus() async {
    if (_deviceCode == null || _deviceCode!.isEmpty) {
      return;
    }

    isLoading = true;
    notifyListeners();
    print("Fetching device status...");
    try {
      _device = await DeviceService().getStatusDevice(_deviceCode!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getHistory() async {
    if (_deviceCode == null || _deviceCode!.isEmpty) {
      return;
    }

    _history = await DeviceService().getHistoryDevice(_deviceCode!);
    _history = _history.reversed.toList();
    notifyListeners();
  }

  Future<bool> controlDevice(String command) async {
    if (_deviceCode == null || _deviceCode!.isEmpty) {
      return false;
    }

    try {
      return await DeviceService().controlDevice(command, _deviceCode!);
    } catch (e) {
      print("Error controlling device: $e");
      return false;
    }
  }
}
