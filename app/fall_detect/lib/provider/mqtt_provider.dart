import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/service/mqtt_service.dart';
import 'package:flutter/material.dart';

class MqttProvider extends ChangeNotifier {
  final MqttService _service = MqttService();
  final Set<String> _subscribedTopics = {};

  DeviceProvider? _deviceProvider;

  void setDeviceProvider(DeviceProvider provider) {
    _deviceProvider = provider;
  }

  bool isConnected = false;

  Future<void> init() async {
    if (isConnected && _service.isConnected) {
      return;
    }

    _subscribedTopics.clear();
    await _service.connect();
    isConnected = true;
    notifyListeners();
  }

  void subscribe(String topic) {
    if (_subscribedTopics.contains(topic)) {
      return;
    }
    _subscribedTopics.add(topic);
    _service.subscribe(topic);
    print("MQTT subscribed: $topic");

    _service.listen(topic).listen((msg) async {
      print("MQTT received: topic=$topic msg=$msg");

      if (topic.contains("esp32/fall_detection/status")) {
        if (_isCurrentDeviceMessage(msg)) {
          await _deviceProvider?.getStatus();
        }
      }

      if (topic.contains("esp32/fall_detection/events")) {
        if (_isCurrentDeviceMessage(msg)) {
          await _deviceProvider?.getHistory();
        }
      }
    });
  }

  bool _isCurrentDeviceMessage(String msg) {
    final deviceCode = _deviceProvider?.deviceCode;
    if (deviceCode == null || deviceCode.isEmpty) {
      return false;
    }

    final messageDeviceCode = msg.split(',').first.trim();
    return messageDeviceCode == deviceCode;
  }

  void publish(String topic, String msg) {
    _service.publish(topic, msg);
  }
}
