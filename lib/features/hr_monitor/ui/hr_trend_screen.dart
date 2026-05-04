import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../providers/hr_monitor_provider.dart';
import 'hr_display_utils.dart';
import 'hr_trend_chart.dart';

class HrTrendScreen extends ConsumerWidget {
  const HrTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(hrMonitorProvider);
    final bpm = monitor.displayBpm;
    final color = HrDisplayUtils.zoneColor(bpm);
    final samples = monitor.recentBpmSamples;

    final min =
        samples.isEmpty ? null : samples.reduce((a, b) => a < b ? a : b);
    final max =
        samples.isEmpty ? null : samples.reduce((a, b) => a > b ? a : b);
    final avg = samples.isEmpty
        ? null
        : (samples.reduce((a, b) => a + b) / samples.length).round();

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.surface,
        foregroundColor: context.palette.textPrimary,
        title: const Text('Heart Rate Trend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: color),
                const SizedBox(width: 8),
                Text(
                  bpm?.toString() ?? '--',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  HrDisplayUtils.statusLabel(bpm),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              monitor.connectedDeviceName == 'Not connected'
                  ? 'No active device'
                  : 'Device: ${monitor.connectedDeviceName}',
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.glassBorder),
              ),
              child: HrTrendChart(
                samples: samples,
                color: color,
                height: 120,
                placeholder:
                    'Connect and stay still for a few seconds to draw trend',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricTile(label: 'Min', value: min?.toString() ?? '--'),
                const SizedBox(width: 8),
                _MetricTile(label: 'Avg', value: avg?.toString() ?? '--'),
                const SizedBox(width: 8),
                _MetricTile(label: 'Max', value: max?.toString() ?? '--'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.palette.glassBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
