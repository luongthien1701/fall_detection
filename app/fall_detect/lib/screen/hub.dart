import 'package:fall_detect/model/device.dart';
import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/provider/mqtt_provider.dart';
import 'package:fall_detect/screen/history.dart';
import 'package:fall_detect/screen/home.dart';
import 'package:fall_detect/screen/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HubWidget extends StatefulWidget {
  const HubWidget({super.key});

  @override
  State<HubWidget> createState() => _HubWidgetState();
}

class _HubWidgetState extends State<HubWidget> {
  final pages = [HomeWidget(), HistoryWidget(), SettingWidget()];
  int pageIndex = 0;
  @override
  void initState() {
    super.initState();
    _connectMqtt();

    loaddata();
  }

  void _connectMqtt() async {
    final mqttProvider = context.read<MqttProvider>();
    final deviceProvider = context.read<DeviceProvider>();

    mqttProvider.setDeviceProvider(deviceProvider);

    await mqttProvider.init();
    mqttProvider.subscribe('esp32/device/status');
  }

  void loaddata() async {
    final deviceProvider = context.read<DeviceProvider>();
    await deviceProvider.getStatus();
    await deviceProvider.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 350),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: pages[pageIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    context.read<AuthProvider>().logout();
    super.dispose();
  }
}
