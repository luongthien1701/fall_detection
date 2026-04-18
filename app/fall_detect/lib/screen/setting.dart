import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/provider/auth_provider.dart';

class SettingWidget extends StatefulWidget {
  const SettingWidget({super.key});

  @override
  State<SettingWidget> createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  double volume = 70;
  bool ison = true;
  @override
  void initState() {
    super.initState();
    loadvolume();
    loadDeviceState();
  }

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔊 ÂM THANH
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitle(Icons.volume_up, "Âm thanh"),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Âm lượng", style: TextStyle(fontSize: 16)),
                      Text("${volume.toInt()}%"),
                    ],
                  ),

                  Slider(
                    value: volume,
                    min: 0,
                    max: 100,
                    activeColor: Colors.green,
                    onChanged: (value) async {
                      setState(() {
                        volume = value;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setDouble('volume', value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ⚡ THIẾT BỊ
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitle(Icons.flash_on, "Thiết bị"),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bật/Tắt thiết bị",
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: ison,
                        activeColor: Colors.green,
                        onChanged: (value) async {
                          setState(() {
                            ison = value;
                          });
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setBool('device_on', value);
                          // Send command to server
                          String command = value ? "on" : "off";
                          bool success = await context
                              .read<DeviceProvider>()
                              .controlDevice(command);
                          if (!success) {
                            // Revert if failed
                            setState(() {
                              ison = !value;
                            });
                            prefs.setBool('device_on', ison);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Không thể điều khiển thiết bị"),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 👤 TÀI KHOẢN
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTitle(Icons.person, "Tài khoản"),
                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showLogoutDialog();
                      },
                      child: const Text(
                        "Đăng xuất",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card chung
  Widget buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: child,
    );
  }

  Widget buildTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: xử lý logout
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  void loadvolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      volume = prefs.getDouble('volume') ?? 70;
    });
  }

  void loadDeviceState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ison = prefs.getBool('device_on') ?? true;
    });
  }
}
