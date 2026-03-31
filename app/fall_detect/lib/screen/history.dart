import 'package:flutter/material.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              const Text(
                'Lịch sử sự kiện',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 50),
            Container(
              width: 350,
              height: 150,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 39, 39, 39),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.only(top: 50),
              child: Column(
                children: [
                  Text(
                    'Sự kiện gần đây',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Không có sự kiện nào được phát hiện',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
