import 'package:fall_detect/screen/history.dart';
import 'package:flutter/material.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              const Text(
                'Fall Detection App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0, top: 20),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/hazardous');
              },
            ),
          ),
        ],
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
                    'Thông tin thiết bị đeo',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Trạng thái: Đang hoạt động',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Cập nhật: 2 giờ trước',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            Container(
              width: 350,
              height: 300,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 39, 39, 39),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Trạng thái người dùng',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Icon(
                    Icons.accessibility_sharp,
                    size: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 50),
                  Text(
                    'AN TOÀN',
                    style: TextStyle(fontSize: 20, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/history');
        },
        child: const Icon(Icons.history),
      ),
    );
  }
}
