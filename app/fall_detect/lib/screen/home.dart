import 'package:fall_detect/provider/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void openDeviceDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeviceDetailWidget(timeAgo: timeAgo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final deviceCode = deviceProvider.deviceCode;
    final hasDevice = deviceCode != null && deviceCode.isNotEmpty;

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
              child: _DeviceHeader(
                onAdd: () => Navigator.pushNamed(context, '/device-connect'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(
                child: hasDevice
                    ? _DeviceCameraCard(
                        deviceCode: deviceCode,
                        isOnline: deviceProvider.device?.status == "online",
                        isLoading: deviceProvider.isLoading,
                        onOpen: openDeviceDetail,
                      )
                    : _NoDeviceView(
                        onAdd: () =>
                            Navigator.pushNamed(context, '/device-connect'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(28, 54, 24, 24),
      decoration: const BoxDecoration(color: Color(0xFF1976F3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "Thiết bị",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 12),
          _HeaderIconButton(icon: Icons.add_circle_outline, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 32),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }
}

class _NoDeviceView extends StatelessWidget {
  const _NoDeviceView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Color(0xFF1976F3), size: 42),
          ),
          const SizedBox(height: 18),
          const Text(
            "Chưa có thiết bị nào",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "Bấm dấu + để nhập mã thiết bị",
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Thêm thiết bị"),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCameraCard extends StatelessWidget {
  const _DeviceCameraCard({
    required this.deviceCode,
    required this.isOnline,
    required this.isLoading,
    required this.onOpen,
  });

  final String deviceCode;
  final bool isOnline;
  final bool isLoading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Thiết bị $deviceCode",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Cài đặt thiết bị",
                  onPressed: onOpen,
                  icon: const Icon(Icons.settings_outlined, size: 34),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onOpen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _CameraPreview(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF1976F3),
                    size: 48,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 8,
                  child: Text(
                    isOnline ? "ONLINE" : "OFFLINE",
                    style: TextStyle(
                      color: isOnline ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DeviceAction(
                  icon: Icons.notifications_active,
                  label: "Thông báo\nbáo động",
                  color: const Color(0xFFFFC107),
                ),
                _DeviceAction(
                  icon: isOnline ? Icons.toggle_on : Icons.toggle_off,
                  label: isOnline ? "Thiết bị\nđang bật" : "Thiết bị\nđang tắt",
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                _DeviceAction(
                  icon: isLoading ? Icons.sync : Icons.video_library,
                  label: "Thông số\nchi tiết",
                  color: const Color(0xFF8D8BF7),
                  onTap: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.95,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        childAspectRatio: 1.95,
        children: const [
          _PreviewPane(color: Color(0xFFB9D7E8), icon: Icons.living),
          _PreviewPane(color: Color(0xFFC9D6D8), icon: Icons.chair),
          _PreviewPane(color: Color(0xFFDCE8F3), icon: Icons.door_front_door),
          _PreviewPane(color: Color(0xFFE0E0E0), icon: Icons.accessibility_new),
        ],
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 6,
            child: Text(
              "2026-05-29 10:27:00",
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: 42,
              color: Colors.black.withValues(alpha: 0.36),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceAction extends StatelessWidget {
  const _DeviceAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final latestHistory = deviceProvider.history.isNotEmpty
        ? deviceProvider.history.first
        : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _DetailTile(
          icon: Icons.power_settings_new,
          title: "Trạng thái thiết bị",
          value: isOnline ? "Đang bật" : "Đang tắt",
          valueColor: isOnline ? Colors.green : Colors.red,
        ),
        _DetailTile(
          icon: Icons.schedule,
          title: "Cập nhật gần nhất",
          value: device?.lastUpdate != null
              ? timeAgo(device!.lastUpdate!)
              : "Chưa có dữ liệu",
        ),
        _DetailTile(
          icon: Icons.speed,
          title: "Gia tốc cảnh báo gần nhất",
          value: latestHistory != null
              ? latestHistory.value.toStringAsFixed(2)
              : "Chưa có cảnh báo",
        ),
        _DetailTile(
          icon: Icons.accessibility_new,
          title: "Trạng thái người dùng",
          value: latestHistory == null ? "AN TOÀN" : "CÓ CẢNH BÁO",
          valueColor: latestHistory == null ? Colors.green : Colors.red,
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
                          Text(
                            history.value.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
  bool isOn = true;

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
      isOn = prefs.getBool('device_on_$_deviceCode') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final deviceOnline = deviceProvider.device?.status == 'online';
    final switchValue = deviceOnline ? isOn : false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsTitle(icon: Icons.volume_up, text: "Âm thanh"),
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
        _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsTitle(icon: Icons.flash_on, text: "Thiết bị"),
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
                    onChanged: deviceOnline
                        ? (value) async {
                            final provider = context.read<DeviceProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() {
                              isOn = value;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                              'device_on_$_deviceCode',
                              value,
                            );
                            final command = value ? 'on' : 'off';
                            final success = await provider.controlDevice(
                              command,
                            );

                            if (!mounted) return;
                            if (!success) {
                              setState(() {
                                isOn = !value;
                              });
                              await prefs.setBool(
                                'device_on_$_deviceCode',
                                isOn,
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Không thể điều khiển thiết bị",
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsTitle extends StatelessWidget {
  const _SettingsTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
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
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
