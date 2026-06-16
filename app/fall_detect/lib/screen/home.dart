import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/widget/device_detail_widget.dart';
import 'package:fall_detect/widget/home_settings_widget.dart';
import 'package:fall_detect/widget/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  Color deviceBackgroundColor = const Color(0xFFE9EEF5);
  bool _hasPromptedForRequiredInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDeviceBackground();
    });
  }

  Future<void> loadDeviceBackground() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      deviceBackgroundColor = Color(
        prefs.getInt('device_background_color') ?? 0xFFE9EEF5,
      );
    });
    promptForRequiredInfoIfNeeded();
  }

  Future<void> setDeviceBackground(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('device_background_color', color.toARGB32());
    if (!mounted) return;
    setState(() {
      deviceBackgroundColor = color;
    });
  }

  String timeAgo(double ts) {
    final now = DateTime.now();
    final time = DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt());
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return "gần đây";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }

  void openDeviceDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeviceDetailWidget(timeAgo: timeAgo)),
    );
  }

  Future<void> showConnectDeviceDialog() async {
    final controller = TextEditingController();
    var isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> connectDevice() async {
              final deviceCode = controller.text.trim().toUpperCase();
              if (deviceCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập mã thiết bị")),
                );
                return;
              }

              setDialogState(() {
                isLoading = true;
              });

              final message = await context.read<AuthProvider>().connectDevice(
                deviceCode,
              );

              if (!context.mounted) return;
              setDialogState(() {
                isLoading = false;
              });

              if (message != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
                return;
              }

              final deviceProvider = context.read<DeviceProvider>();
              deviceProvider.setDeviceCode(deviceCode);
              await deviceProvider.getStatus();
              await deviceProvider.getHistory();

              if (!context.mounted) return;
              Navigator.pop(dialogContext);
            }

            return AlertDialog(
              title: const Text("Kết nối thiết bị"),
              content: TextField(
                controller: controller,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Mã thiết bị",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : connectDevice,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Kết nối"),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  void openAppSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppSettingsWidget(
          deviceBackgroundColor: deviceBackgroundColor,
          onDeviceBackgroundChanged: setDeviceBackground,
        ),
      ),
    );
  }

  void promptForRequiredInfoIfNeeded() {
    if (_hasPromptedForRequiredInfo) return;

    final authProvider = context.read<AuthProvider>();
    final hasPhone = authProvider.phone.trim().isNotEmpty;
    final hasRelativePhone =
        authProvider.relativePhone1.trim().isNotEmpty ||
        authProvider.relativePhone2.trim().isNotEmpty;

    if (hasPhone && hasRelativePhone) return;

    _hasPromptedForRequiredInfo = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppSettingsWidget(
          deviceBackgroundColor: deviceBackgroundColor,
          onDeviceBackgroundChanged: setDeviceBackground,
          requireUserInfo: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final deviceCode = deviceProvider.deviceCode;
    final hasDevice = deviceCode != null && deviceCode.isNotEmpty;
    final isOnline = deviceProvider.device?.status == "online";

    Future<void> triggerBuzzer() async {
      final success = await context.read<DeviceProvider>().triggerBuzzer();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Đã gửi lệnh kêu loa" : "Không thể gửi lệnh kêu loa",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: RefreshIndicator(
        onRefresh: () async {
          await deviceProvider.getStatus();
          await deviceProvider.getHistory();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DeviceHeader(
                onAdd: showConnectDeviceDialog,
                onSettings: openAppSettings,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(
                child: hasDevice
                    ? DeviceCameraCard(
                        deviceCode: deviceCode,
                        isOnline: isOnline,
                        isLoading: deviceProvider.isLoading,
                        backgroundColor: deviceBackgroundColor,
                        onOpen: openDeviceDetail,
                        onAlarm: isOnline ? triggerBuzzer : null,
                      )
                    : NoDeviceView(onAdd: showConnectDeviceDialog),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
