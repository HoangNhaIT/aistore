import 'package:flutter/material.dart';

class NfcWaveAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const NfcWaveAnimation({
    super.key,
    this.size = 180.0,
    this.color = const Color(0xFF007AFF),
  });

  @override
  State<NfcWaveAnimation> createState() => _NfcWaveAnimationState();
}

class _NfcWaveAnimationState extends State<NfcWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WavePainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.nfc,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final value = (animationValue + (i * 0.33)) % 1.0;
      final radius = 36 + (maxRadius - 36) * value;
      final opacity = (1.0 - value).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
