import 'package:fall_detect/provider/auth_provider.dart';
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
    final hasName = authProvider.firstname.trim().isNotEmpty;
    final hasPhone = authProvider.appPhone.trim().isNotEmpty;
    final hasRelativePhone =
        authProvider.relativePhone1.trim().isNotEmpty ||
        authProvider.relativePhone2.trim().isNotEmpty;

    if (hasName && hasPhone && hasRelativePhone) return;

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
              child: _DeviceHeader(
                onAdd: showConnectDeviceDialog,
                onSettings: openAppSettings,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(
                child: hasDevice
                    ? _DeviceCameraCard(
                        deviceCode: deviceCode,
                        isOnline: isOnline,
                        isLoading: deviceProvider.isLoading,
                        backgroundColor: deviceBackgroundColor,
                        onOpen: openDeviceDetail,
                        onAlarm: isOnline ? triggerBuzzer : null,
                      )
                    : _NoDeviceView(onAdd: showConnectDeviceDialog),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.onAdd, required this.onSettings});

  final VoidCallback onAdd;
  final VoidCallback onSettings;

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
          _HeaderIconButton(icon: Icons.more_vert, onPressed: onSettings),
          const SizedBox(width: 8),
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
    required this.backgroundColor,
    required this.onOpen,
    required this.onAlarm,
  });

  final String deviceCode;
  final bool isOnline;
  final bool isLoading;
  final Color backgroundColor;
  final VoidCallback onOpen;
  final VoidCallback? onAlarm;

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
                Container(
                  height: 180,
                  width: double.infinity,
                  color: backgroundColor,
                  child: Icon(
                    Icons.watch,
                    size: 64,
                    color: Colors.black.withValues(alpha: 0.32),
                  ),
                ),
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
                  color: isOnline ? const Color(0xFFFFC107) : Colors.grey,
                  onTap: onAlarm,
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

class AppSettingsWidget extends StatefulWidget {
  const AppSettingsWidget({
    super.key,
    required this.deviceBackgroundColor,
    required this.onDeviceBackgroundChanged,
    this.requireUserInfo = false,
  });

  final Color deviceBackgroundColor;
  final Future<void> Function(Color color) onDeviceBackgroundChanged;
  final bool requireUserInfo;

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

class _AppSettingsWidgetState extends State<AppSettingsWidget> {
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relativePhone1Controller =
      TextEditingController();
  final TextEditingController _relativePhone2Controller =
      TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;
  late Color _selectedBackgroundColor;

  static const List<Color> _backgroundOptions = [
    Color(0xFFE9EEF5),
    Color(0xFFEAF7EE),
    Color(0xFFFFF3D8),
    Color(0xFFF4E9FF),
    Color(0xFFE7F5FF),
  ];

  @override
  void initState() {
    super.initState();
    _selectedBackgroundColor = widget.deviceBackgroundColor;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final authProvider = context.read<AuthProvider>();
    _firstnameController.text = authProvider.firstname;
    _phoneController.text = authProvider.appPhone;
    _relativePhone1Controller.text = authProvider.relativePhone1;
    _relativePhone2Controller.text = authProvider.relativePhone2;
    _initialized = true;
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _phoneController.dispose();
    _relativePhone1Controller.dispose();
    _relativePhone2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    final firstname = _firstnameController.text.trim();
    final phone = _phoneController.text.trim();
    final relativePhone1 = _relativePhone1Controller.text.trim();
    final relativePhone2 = _relativePhone2Controller.text.trim();

    if (firstname.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và số điện thoại")),
      );
      return;
    }

    if (relativePhone1.isEmpty && relativePhone2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập ít nhất một số điện thoại người thân"),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final message = await context.read<AuthProvider>().updateUserInfo(
      firstname,
      phone,
      relativePhone1,
      relativePhone2,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? "Đã cập nhật thông tin")));

    if (message == null && widget.requireUserInfo) {
      Navigator.pop(context);
    }
  }

  Future<void> _selectBackground(Color color) async {
    setState(() {
      _selectedBackgroundColor = color;
    });
    await widget.onDeviceBackgroundChanged(color);
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    context.read<DeviceProvider>().setDeviceCode(null);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  bool get _hasRequiredInfo {
    return _firstnameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        (_relativePhone1Controller.text.trim().isNotEmpty ||
            _relativePhone2Controller.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.requireUserInfo || _hasRequiredInfo,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !widget.requireUserInfo || _hasRequiredInfo) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng cập nhật thông tin trước")),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              !widget.requireUserInfo || _hasRequiredInfo,
          title: Text(
            widget.requireUserInfo ? "Cập nhật thông tin" : "Cài đặt",
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.requireUserInfo)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFC857)),
                ),
                child: const Text(
                  "Vui lòng nhập thông tin liên hệ và ít nhất một số người thân để dùng khi có báo khẩn cấp.",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsTitle(
                    icon: Icons.palette_outlined,
                    text: "Nền thiết bị",
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: _backgroundOptions.map((color) {
                      final selected =
                          color.toARGB32() ==
                          _selectedBackgroundColor.toARGB32();
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _selectBackground(color),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF1976F3)
                                    : Colors.black12,
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Color(0xFF1976F3),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsTitle(
                    icon: Icons.person_outline,
                    text: "Thông tin",
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _firstnameController,
                    decoration: const InputDecoration(
                      labelText: "Tên",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    obscureText: false,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại người dùng app",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _relativePhone1Controller,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    obscureText: false,
                    decoration: const InputDecoration(
                      labelText: "Số người thân 1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _relativePhone2Controller,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    obscureText: false,
                    decoration: const InputDecoration(
                      labelText: "Số người thân 2",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveUserInfo,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text("Cập nhật thông tin"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
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
