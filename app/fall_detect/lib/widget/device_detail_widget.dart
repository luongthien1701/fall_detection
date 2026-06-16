import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/widget/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceDetailWidget extends StatelessWidget {
  const DeviceDetailWidget({super.key, required this.timeAgo});

  final String Function(double timestamp) timeAgo;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final deviceCode = deviceProvider.deviceCode ?? "";

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Thiết bị $deviceCode"),
          actions: [
            IconButton(
              tooltip: "Làm mới",
              onPressed: () async {
                await deviceProvider.getStatus();
                await deviceProvider.getHistory();
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: "Thông tin"),
              Tab(icon: Icon(Icons.history), text: "Lịch sử"),
              Tab(icon: Icon(Icons.settings), text: "Cài đặt"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DeviceInfoTab(timeAgo: timeAgo),
            const _DeviceHistoryTab(),
            const _DeviceSettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoTab extends StatelessWidget {
  const _DeviceInfoTab({required this.timeAgo});

  final String Function(double timestamp) timeAgo;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final device = deviceProvider.device;
    final isOnline = device?.status == "online";

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DetailTile(
          icon: Icons.power_settings_new,
          title: "Trạng thái thiết bị",
          value: isOnline ? "Đang bật" : "Đang tắt",
          valueColor: isOnline ? Colors.green : Colors.red,
        ),
        DetailTile(
          icon: Icons.schedule,
          title: "Cập nhật gần nhất",
          value: device?.lastUpdate != null
              ? timeAgo(device!.lastUpdate!)
              : "Chưa có dữ liệu",
        ),
      ],
    );
  }
}

class _DeviceHistoryTab extends StatefulWidget {
  const _DeviceHistoryTab();

  @override
  State<_DeviceHistoryTab> createState() => _DeviceHistoryTabState();
}

class _DeviceHistoryTabState extends State<_DeviceHistoryTab> {
  DateTime? selectedDate;

  String formatTime(DateTime time) {
    return DateFormat('HH:mm dd/MM/yyyy').format(time);
  }

  void pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyList = context.watch<DeviceProvider>().history;
    final filteredHistory = selectedDate == null
        ? historyList
        : historyList.where((history) {
            return history.time.year == selectedDate!.year &&
                history.time.month == selectedDate!.month &&
                history.time.day == selectedDate!.day;
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate == null
                      ? "Tất cả sự kiện"
                      : "Ngày ${DateFormat('dd/MM/yyyy').format(selectedDate!)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredHistory.isEmpty
              ? const Center(child: Text("Chưa có lịch sử cảnh báo"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final history = filteredHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Phát hiện té ngã",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(formatTime(history.time)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeviceSettingsTab extends StatefulWidget {
  const _DeviceSettingsTab();

  @override
  State<_DeviceSettingsTab> createState() => _DeviceSettingsTabState();
}

class _DeviceSettingsTabState extends State<_DeviceSettingsTab> {
  double volume = 70;
  bool isTogglingDevice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadSettings();
    });
  }

  String get _deviceCode {
    return context.read<DeviceProvider>().deviceCode ?? "unknown";
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      volume = prefs.getDouble('volume_$_deviceCode') ?? 70;
    });
  }

  Future<bool> _waitForDeviceStatus(
    DeviceProvider provider,
    bool expectedOnline,
  ) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      await Future.delayed(const Duration(seconds: 1));
      await provider.getStatus();

      final isOnline = provider.device?.status == "online";
      if (isOnline == expectedOnline) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final canControl = (deviceProvider.deviceCode ?? "").isNotEmpty;
    final isDeviceOnline = deviceProvider.device?.status == "online";
    final switchValue = isDeviceOnline;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsTitle(icon: Icons.volume_up, text: "Âm thanh"),
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
                  await prefs.setDouble('volume_$_deviceCode', value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsTitle(icon: Icons.flash_on, text: "Thiết bị"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bật/Tắt thiết bị",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: switchValue,
                    activeThumbColor: Colors.green,
                    onChanged: canControl && !isTogglingDevice
                        ? (value) async {
                            final provider = context.read<DeviceProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() {
                              isTogglingDevice = true;
                            });
                            final command = isDeviceOnline ? 'off' : 'on';
                            final loadingNavigator = Navigator.of(context);
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const AlertDialog(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text("Vui lòng đợi vài giây"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            final success = await provider.controlDevice(
                              command,
                            );
                            var statusChanged = false;
                            if (success) {
                              statusChanged = await _waitForDeviceStatus(
                                provider,
                                command == 'on',
                              );
                            }

                            if (!mounted) return;
                            loadingNavigator.pop();
                            setState(() {
                              isTogglingDevice = false;
                            });

                            if (!success) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    command == 'on'
                                        ? "Không thể bật thiết bị, thiết bị có thể không có điện"
                                        : "Không thể tắt thiết bị",
                                  ),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    statusChanged
                                        ? (command == 'on'
                                              ? "Thiết bị đã bật"
                                              : "Thiết bị đã tắt")
                                        : "Thiết bị chưa cập nhật trạng thái, vui lòng thử lại",
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
