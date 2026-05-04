import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class HrTrendChart extends StatelessWidget {
  final List<int> samples;
  final Color color;
  final double height;
  final String placeholder;

  const HrTrendChart({
    super.key,
    required this.samples,
    required this.color,
    this.height = 34,
    this.placeholder = 'Trend appears after a few readings',
  });

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            placeholder,
            style: TextStyle(
              fontSize: 10,
              color: context.palette.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    final visible = samples.length <= 24
        ? samples
        : samples.sublist(samples.length - 24, samples.length);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HrTrendPainter(
          samples: visible,
          color: color,
        ),
      ),
    );
  }
}

class _HrTrendPainter extends CustomPainter {
  final List<int> samples;
  final Color color;

  _HrTrendPainter({
    required this.samples,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final minValue = samples.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = samples.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxValue - minValue).abs();
    final effectiveRange = range < 1 ? 1.0 : range;
    final stepX = size.width / (samples.length - 1);

    final linePath = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = stepX * i;
      final normalized = (samples[i] - minValue) / effectiveRange;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HrTrendPainter oldDelegate) {
    if (oldDelegate.color != color) return true;
    if (oldDelegate.samples.length != samples.length) return true;
    for (var i = 0; i < samples.length; i++) {
      if (oldDelegate.samples[i] != samples[i]) return true;
    }
    return false;
  }
}
