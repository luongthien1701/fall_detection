import 'package:flutter/material.dart';

class DeviceHeader extends StatelessWidget {
  const DeviceHeader({
    super.key,
    required this.onAdd,
    required this.onSettings,
  });

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
          const SizedBox(width: 8),
          _HeaderIconButton(icon: Icons.add_circle_outline, onPressed: onAdd),
          const SizedBox(width: 12),
          _HeaderIconButton(icon: Icons.more_vert, onPressed: onSettings),
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

class NoDeviceView extends StatelessWidget {
  const NoDeviceView({super.key, required this.onAdd});

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

class DeviceCameraCard extends StatelessWidget {
  const DeviceCameraCard({
    super.key,
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

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child});

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

class SettingsTitle extends StatelessWidget {
  const SettingsTitle({super.key, required this.icon, required this.text});

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

class DetailTile extends StatelessWidget {
  const DetailTile({
    super.key,
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
