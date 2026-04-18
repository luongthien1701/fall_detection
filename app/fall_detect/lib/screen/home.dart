import 'package:fall_detect/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  String timeAgo(double ts) {
    final now = DateTime.now();
    final time = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());

    final diff = now.difference(time);

    if (diff.inSeconds < 60) return "gần đây";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Fall Detection',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        
      ),
      body: Center(
        child: deviceProvider.isLoading
            ? const CircularProgressIndicator() // 🔥 loading ở đây
            : Column(
                children: [
                  Container(
                    width: 350,
                    height: 150,
                    margin: const EdgeInsets.only(top: 50),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 39, 39, 39),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Thông tin thiết bị đeo',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// STATUS
                        Text(
                          'Trạng thái: ${deviceProvider.device?.status == "online" ? "Đang hoạt động" : "Ngoại tuyến"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: (deviceProvider.device?.status == "online")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TIME
                        Text(
                          'Cập nhật: ${deviceProvider.device != null ? timeAgo(deviceProvider.device!.lastUpdate) : "Chưa có dữ liệu"}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  Container(
                    width: 350,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 39, 39, 39),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: const [
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
      
    );
  }
}
