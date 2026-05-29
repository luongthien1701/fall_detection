import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeviceConnectWidget extends StatefulWidget {
  const DeviceConnectWidget({super.key});

  @override
  State<DeviceConnectWidget> createState() => _DeviceConnectWidgetState();
}

class _DeviceConnectWidgetState extends State<DeviceConnectWidget> {
  final TextEditingController _deviceCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _connectDevice() async {
    final deviceCode = _deviceCodeController.text.trim().toUpperCase();

    if (deviceCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập mã thiết bị")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final message = await context.read<AuthProvider>().connectDevice(
      deviceCode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    context.read<DeviceProvider>().setDeviceCode(deviceCode);
    Navigator.pushReplacementNamed(context, '/hub');
  }

  @override
  void dispose() {
    _deviceCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("Kết nối thiết bị"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.watch, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              TextField(
                controller: _deviceCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Mã thiết bị",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _connectDevice,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Kết nối"),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Đăng xuất"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
