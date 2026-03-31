import 'package:flutter/material.dart';

class HazardousWidget extends StatefulWidget {
  const HazardousWidget({super.key});

  @override
  State<HazardousWidget> createState() => _HazardousWidgetState();
}

class _HazardousWidgetState extends State<HazardousWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 100, color: Colors.red),
          SizedBox(height: 20),
          Text('CẢNH BÁO NGUY HIỂM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          SizedBox(height: 20),
          Text('Người dùng có dấu hiệu bị ngã. Vui lòng kiểm tra ngay!', style: TextStyle(fontSize: 16, color: Colors.black)),
        ],
      ),
    );
  }
}