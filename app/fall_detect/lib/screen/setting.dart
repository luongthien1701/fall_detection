import 'package:flutter/material.dart';

class SettingWidget extends StatefulWidget {
  const SettingWidget({super.key});

  @override
  State<SettingWidget> createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text('Cài đặt sẽ được cập nhật sau'),
      ),
    );
  }
}