import 'package:flutter/material.dart';

import '../../models/training/imported_workout.dart';

/// A compact heart-rate sparkline (time on x, bpm on y).
class HrChart extends StatelessWidget {
  const HrChart({super.key, required this.samples, this.height = 56});

  final List<HrSample> samples;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _HrPainter(samples)),
    );
  }
}

class _HrPainter extends CustomPainter {
  _HrPainter(this.samples);

  final List<HrSample> samples;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final t0 = samples.first.tMs;
    final tSpan = (samples.last.tMs - t0).toDouble();
    if (tSpan <= 0) return;

    var minBpm = samples.first.bpm;
    var maxBpm = samples.first.bpm;
    for (final s in samples) {
      if (s.bpm < minBpm) minBpm = s.bpm;
      if (s.bpm > maxBpm) maxBpm = s.bpm;
    }
    final range = (maxBpm - minBpm).toDouble();
    const pad = 4.0;
    final h = size.height - pad * 2;

    double x(int t) => (t - t0) / tSpan * size.width;
    double y(int bpm) =>
        range == 0 ? size.height / 2 : pad + (1 - (bpm - minBpm) / range) * h;

    final path = Path()..moveTo(x(samples.first.tMs), y(samples.first.bpm));
    for (var i = 1; i < samples.length; i++) {
      path.lineTo(x(samples[i].tMs), y(samples[i].bpm));
    }

    final paint = Paint()
      ..color = const Color(0xFFE8556B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HrPainter old) => old.samples != samples;
}
