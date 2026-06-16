import 'package:flutter/material.dart';

class WarningHeader extends StatelessWidget {
  const WarningHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.warning, size: 100, color: Colors.red),
        SizedBox(height: 20),
        Text(
          'CẢNH BÁO NGUY HIỂM',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class HazardousDeviceCard extends StatelessWidget {
  const HazardousDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Image.asset('assets/image/a1.png', width: 200, height: 200),
        ],
      ),
    );
  }
}

class EmergencyActions extends StatelessWidget {
  const EmergencyActions({
    super.key,
    required this.onCallEmergency,
    required this.onCallFamily,
  });

  final VoidCallback onCallEmergency;
  final VoidCallback onCallFamily;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _EmergencyButton(
          icon: Icons.call,
          label: 'Cấp cứu',
          onPressed: onCallEmergency,
        ),
        const SizedBox(width: 20),
        _EmergencyButton(
          icon: Icons.message,
          label: 'Người thân',
          onPressed: onCallFamily,
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class DismissAlarmSlider extends StatefulWidget {
  const DismissAlarmSlider({super.key, required this.onDismiss});

  final Future<void> Function() onDismiss;

  @override
  State<DismissAlarmSlider> createState() => _DismissAlarmSliderState();
}

class _DismissAlarmSliderState extends State<DismissAlarmSlider> {
  static const double trackWidth = 250;
  static const double thumbSize = 50;
  double slideValue = 0;

  Future<void> handleSlideEnd(double value) async {
    if (value > 0.9) {
      await widget.onDismiss();
      return;
    }

    setState(() {
      slideValue = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        const _DismissTrack(width: trackWidth),
        _InvisibleSlider(
          width: trackWidth,
          value: slideValue,
          onChanged: (value) {
            setState(() {
              slideValue = value;
            });
          },
          onChangeEnd: handleSlideEnd,
        ),
        Positioned(
          left: slideValue * (trackWidth - thumbSize),
          child: _DismissThumb(
            size: thumbSize,
            onDragUpdate: (details) {
              setState(() {
                slideValue += details.delta.dx / trackWidth;
                slideValue = slideValue.clamp(0, 1);
              });
            },
            onDragEnd: () => handleSlideEnd(slideValue),
          ),
        ),
      ],
    );
  }
}

class _DismissTrack extends StatelessWidget {
  const _DismissTrack({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _InvisibleSlider extends StatelessWidget {
  const _InvisibleSlider({
    required this.width,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double width;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 0,
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.transparent,
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: value,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    );
  }
}

class _DismissThumb extends StatelessWidget {
  const _DismissThumb({
    required this.size,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double size;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: (_) => onDragEnd(),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.dangerous_outlined, color: Colors.white),
      ),
    );
  }
}
