import 'package:fall_detect/service/audioservice.dart';
import 'package:fall_detect/widget/hazardous_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/auth_provider.dart';

class HazardousWidget extends StatefulWidget {
  const HazardousWidget({super.key});

  @override
  State<HazardousWidget> createState() => _HazardousWidgetState();
}

class _HazardousWidgetState extends State<HazardousWidget> {
  Future<void> callEmergency() async {
    final url = Uri(scheme: 'tel', path: '115');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> callFamily() async {
    final authProvider = context.read<AuthProvider>();
    final phones = [
      authProvider.relativePhone1,
      authProvider.relativePhone2,
    ].where((phone) => phone.isNotEmpty).toList();

    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có số điện thoại người thân')),
      );
      return;
    }

    for (final phone in phones) {
      final url = Uri(scheme: 'tel', path: phone);
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không thể gọi số người thân')),
    );
  }

  @override
  void initState() {
    super.initState();
    AudioService.playAlarm(50);
  }

  Future<void> dismissAlarm() async {
    await AudioService.stopAlarm();
    if (!mounted) return;
    Navigator.pushNamed(context, '/hub');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 221, 141, 136),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              const WarningHeader(),
              const SizedBox(height: 20),
              const HazardousDeviceCard(),
              const SizedBox(height: 20),
              EmergencyActions(
                onCallEmergency: callEmergency,
                onCallFamily: callFamily,
              ),
              const SizedBox(height: 30),
              DismissAlarmSlider(onDismiss: dismissAlarm),
            ],
          ),
        ),
      ),
    );
  }
}
