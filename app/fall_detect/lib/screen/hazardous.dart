import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HazardousWidget extends StatefulWidget {
  const HazardousWidget({super.key});

  @override
  State<HazardousWidget> createState() => _HazardousWidgetState();
}

class _HazardousWidgetState extends State<HazardousWidget> {
  double slideValue = 0;
  final double trackWidth = 250; // 🔥 chỉnh độ dài tại đây

  Future<void> callEmergency() async {
    final url = Uri(scheme: 'tel', path: '115');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> callFamily() async {
    final url = Uri(scheme: 'tel', path: '0332775136');
    await launchUrl(url, mode: LaunchMode.externalApplication);
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

              const Icon(Icons.warning, size: 100, color: Colors.red),

              const SizedBox(height: 20),

              const Text(
                'CẢNH BÁO NGUY HIỂM',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 20),

              /// Card info
              Container(
                height: 300,
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Thiết bị phát hiện nguy hiểm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset('assets/image/a1.png', width: 200, height: 200),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: callEmergency,
                    child: const Row(
                      children: [
                        Icon(Icons.call),
                        SizedBox(width: 5),
                        Text('Cấp cứu'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: callFamily,
                    child: const Row(
                      children: [
                        Icon(Icons.message),
                        SizedBox(width: 5),
                        Text('Người thân'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// 🔥 SLIDER CUSTOM ĐẸP
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  /// Background track (to + bo góc)
                  Container(
                    width: trackWidth,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Text(
                          "Trượt để tắt cảnh báo",
                          style: TextStyle(fontWeight: FontWeight.bold,),
                        ),
                      ),
                    ),
                  ),

                  /// Slider thật (ẩn thumb)
                  SizedBox(
                    width: trackWidth,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 0,
                        activeTrackColor: Colors.red,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.transparent,
                        overlayColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: slideValue,
                        onChanged: (value) {
                          setState(() {
                            slideValue = value;
                          });
                        },
                        onChangeEnd: (value) {
                          if (value > 0.9) {
                            Navigator.pushNamed(context, '/hub');
                          } else {
                            setState(() {
                              slideValue = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  /// Icon di chuyển theo slider
                  Positioned(
                    left: slideValue * (trackWidth - 50),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          slideValue += details.delta.dx / trackWidth;
                          slideValue = slideValue.clamp(0, 1);
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        if (slideValue > 0.9) {
                          Navigator.pushNamed(context, '/hub');
                        } else {
                          setState(() => slideValue = 0);
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.dangerous_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
