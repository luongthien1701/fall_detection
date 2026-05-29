import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/provider/mqtt_provider.dart';
import 'package:fall_detect/screen/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HubWidget extends StatefulWidget {
  const HubWidget({super.key});

  @override
  State<HubWidget> createState() => _HubWidgetState();
}

class _HubWidgetState extends State<HubWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectMqtt();
      loaddata();
    });
  }

  void _connectMqtt() async {
    final authProvider = context.read<AuthProvider>();
    final mqttProvider = context.read<MqttProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    deviceProvider.setDeviceCode(authProvider.deviceCode);
    mqttProvider.setDeviceProvider(deviceProvider);

    await mqttProvider.init();
    mqttProvider.subscribe('esp32/fall_detection/status');
  }

  void loaddata() async {
    final authProvider = context.read<AuthProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    deviceProvider.setDeviceCode(authProvider.deviceCode);
    await deviceProvider.getStatus();
    await deviceProvider.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeWidget();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
