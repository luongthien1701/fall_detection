import 'package:fall_detect/provider/auth_provider.dart';
import 'package:fall_detect/provider/device_provider.dart';
import 'package:fall_detect/widget/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsTitle(
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
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsTitle(
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
