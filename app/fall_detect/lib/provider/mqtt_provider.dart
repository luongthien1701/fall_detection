import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/service/mqtt_service.dart';
import 'package:flutter/material.dart';

class MqttProvider extends ChangeNotifier {
  final MqttService _service = MqttService();

  DeviceProvider? _deviceProvider;

  void setDeviceProvider(DeviceProvider provider) {
    _deviceProvider = provider;
  }

  bool isConnected = false;

  Future<void> init() async {
    await _service.connect();
    isConnected = true;
    notifyListeners();
  }

  void subscribe(String topic) {
    _service.subscribe(topic);

    _service.listen(topic).listen((msg) async {
      if (topic.contains("esp32/device/status" )) {
        print("Received MQTT message: $msg");
        await _deviceProvider?.getStatus();
      }
    });
  }

  void publish(String topic, String msg) {
    _service.publish(topic, msg);
  }
}