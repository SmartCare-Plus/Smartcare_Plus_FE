import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/hr_monitor_provider.dart';
import '../../../widgets/common/glassmorphic_card.dart';
import '../controllers/hr_monitor_controller.dart';
import '../models/hr_connection_state.dart';
import 'hr_display_utils.dart';
import 'hr_trend_chart.dart';
import 'hr_trend_screen.dart';

class ElderlyHrSection extends ConsumerStatefulWidget {
  const ElderlyHrSection({super.key});

  @override
  ConsumerState<ElderlyHrSection> createState() => _ElderlyHrSectionState();
}

class _ElderlyHrSectionState extends ConsumerState<ElderlyHrSection> {
  Timer? _ticker;
  String? _lastAlertShown;
  bool _isAlertDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = ref.watch(hrMonitorProvider);
    final bpm = monitor.displayBpm;
    final color = HrDisplayUtils.zoneColor(bpm);
    final isLive = HrDisplayUtils.isLive(
      bpm: monitor.currentBpm,
      lastReadingAt: monitor.lastReadingAt,
      isStale: monitor.isStale,
    );

    _handleAlertSnackbar(monitor.healthAlertMessage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeartRateCard(
          monitor: monitor,
          color: color,
          onOpenTrend: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HrTrendScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          _buildSubtitle(monitor, isLive),
          style: TextStyle(
            fontSize: 11,
            color: context.palette.textSecondary,
          ),
        ),
        if (monitor.healthAlertMessage != null) ...[
          const SizedBox(height: 8),
          _SustainedAlertBanner(message: monitor.healthAlertMessage!),
        ],
        const SizedBox(height: 10),
        _buildDeviceConnectCard(monitor),
      ],
    );
  }

  String _buildSubtitle(HrMonitorController monitor, bool isLive) {
    if (isLive) {
      return 'Live reading from ${monitor.connectedDeviceName} · '
          '${HrDisplayUtils.updatedAgoLabel(monitor.lastReadingAt)}';
    }
    if (monitor.hasActiveConnection) {
      return '${monitor.statusMessage} · '
          '${HrDisplayUtils.updatedAgoLabel(monitor.lastReadingAt)}';
    }
    if ((monitor.rememberedDeviceName ?? '').isNotEmpty) {
      return 'Last device: ${monitor.rememberedDeviceName}';
    }
    return 'Connect your wearable to see live heart rate';
  }

  void _handleAlertSnackbar(String? message) {
    if (!mounted) return;
    if (message == null) {
      _lastAlertShown = null;
      return;
    }
    if (_lastAlertShown == message) {
      return;
    }
    _lastAlertShown = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isAlertDialogOpen) return;
      _showBpmAlertDialog(message);
    });
  }

  void _showBpmAlertDialog(String message) {
    if (!mounted) return;
    _isAlertDialogOpen = true;
    final isHigh = message.toLowerCase().contains('high');
    final color = isHigh ? AppColors.neonRed : AppColors.neonOrange;
    final title = isHigh ? 'High Heart Rate Alert' : 'Low Heart Rate Alert';
    final note = isHigh
        ? 'Heart rate has stayed above the normal resting range for several seconds. Please take a short rest and monitor symptoms.'
        : 'Heart rate has stayed below the normal resting range for several seconds. Please sit safely and monitor symptoms.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.palette.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.favorite, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Dismiss',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    ).whenComplete(() {
      _isAlertDialogOpen = false;
    });
  }

  bool _isDeviceConnected(HrMonitorController monitor) {
    return monitor.hasActiveConnection && monitor.connectedDeviceId != '-';
  }

  Widget _buildDeviceConnectCard(HrMonitorController monitor) {
    final isConnected = _isDeviceConnected(monitor);
    final accent = isConnected ? AppColors.neonGreen : AppColors.neonCyan;

    return GestureDetector(
      onTap: _showDeviceConnectionSheet,
      child: GlassmorphicCard(
        glowColor: accent,
        glowIntensity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bluetooth, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Wearable Connected' : 'Connect Device',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected
                        ? monitor.connectedDeviceName
                        : monitor.isBusy
                            ? monitor.statusMessage
                            : (monitor.rememberedDeviceName?.isNotEmpty ??
                                    false)
                                ? 'Last: ${monitor.rememberedDeviceName}'
                                : 'Pair your watch/band for live heart rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _primaryActionLabel(monitor),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _primaryActionLabel(HrMonitorController monitor) {
    if (monitor.isBusy) return 'Scanning';
    if (_isDeviceConnected(monitor)) return 'Manage';
    if (monitor.state == HrConnectionState.disconnected ||
        monitor.state == HrConnectionState.error) {
      return 'Reconnect';
    }
    return 'Connect';
  }

  String _sheetActionLabel(HrMonitorController monitor) {
    if (monitor.isBusy) return 'Scanning...';
    if (_isDeviceConnected(monitor)) return 'Disconnect';
    if (monitor.state == HrConnectionState.disconnected ||
        monitor.state == HrConnectionState.error) {
      return 'Reconnect';
    }
    return 'Scan Devices';
  }

  Future<void> _handlePrimaryDeviceAction(HrMonitorController monitor) async {
    if (monitor.isBusy) return;
    if (_isDeviceConnected(monitor)) {
      await monitor.disconnect();
      return;
    }
    if (monitor.state == HrConnectionState.disconnected ||
        monitor.state == HrConnectionState.error) {
      await monitor.reconnectNow();
      return;
    }
    await monitor.scanAndConnect();
  }

  void _showDeviceConnectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final monitor = ref.watch(hrMonitorProvider);
            final isConnected = _isDeviceConnected(monitor);
            final accent =
                isConnected ? AppColors.neonGreen : AppColors.neonCyan;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.bluetooth_searching,
                              color: accent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Connect Wearable',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.palette.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isConnected
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isConnected
                                  ? 'Connected to ${monitor.connectedDeviceName}'
                                  : monitor.statusMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((monitor.rememberedDeviceName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.watch,
                                color: context.palette.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Remembered: ${monitor.rememberedDeviceName}',
                                style: TextStyle(
                                  color: context.palette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await monitor.forgetRememberedDevice();
                              },
                              child: const Text(
                                'Forget',
                                style: TextStyle(color: AppColors.neonRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Auto-connect on dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.palette.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Try once when this screen opens',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
                        ),
                      ),
                      value: monitor.autoConnectEnabled,
                      activeThumbColor: AppColors.neonCyan,
                      activeTrackColor:
                          AppColors.neonCyan.withValues(alpha: 0.45),
                      onChanged: (enabled) {
                        monitor.setAutoConnectEnabled(enabled);
                      },
                    ),
                    Text(
                      'Supported Devices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SupportedDeviceChip(label: 'Huawei Watch (HR Share)'),
                        _SupportedDeviceChip(label: 'Mi Band 10 (HR Share)'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.palette.textSecondary,
                              side: BorderSide(
                                  color: context.palette.glassBorder),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Not now'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: monitor.isBusy
                                ? null
                                : () => _handlePrimaryDeviceAction(monitor),
                            icon: Icon(
                              isConnected
                                  ? Icons.link_off
                                  : Icons.bluetooth_searching,
                              size: 18,
                            ),
                            label: Text(_sheetActionLabel(monitor)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor:
                                  context.palette.surfaceLighter,
                              disabledForegroundColor:
                                  context.palette.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeartRateCard extends StatelessWidget {
  final HrMonitorController monitor;
  final Color color;
  final VoidCallback onOpenTrend;

  const _HeartRateCard({
    required this.monitor,
    required this.color,
    required this.onOpenTrend,
  });

  @override
  Widget build(BuildContext context) {
    final displayBpm = monitor.displayBpm;
    final rawBpm = monitor.currentBpm;
    final status = HrDisplayUtils.statusLabel(displayBpm);
    final progress = HrDisplayUtils.progress(displayBpm);

    return GlassmorphicCard(
      glowColor: color,
      glowIntensity: 0.15,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.favorite, color: color, size: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      displayBpm?.toString() ?? '--',
                      key: ValueKey<String>(displayBpm?.toString() ?? '--'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Heart Rate (BPM)',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              if (displayBpm != null && rawBpm != null && displayBpm != rawBpm)
                Text(
                  'raw $rawBpm',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.palette.textSecondary,
                  ),
                ),
              IconButton(
                onPressed: onOpenTrend,
                icon: const Icon(Icons.show_chart, size: 18),
                color: context.palette.textSecondary,
                splashRadius: 18,
                tooltip: 'Open detailed trend',
              ),
            ],
          ),
          HrTrendChart(
            samples: monitor.recentBpmSamples,
            color: color,
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(end: progress),
            builder: (context, animatedProgress, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animatedProgress,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SustainedAlertBanner extends StatelessWidget {
  final String message;

  const _SustainedAlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isHigh = message.toLowerCase().contains('high');
    final color = isHigh ? AppColors.neonRed : AppColors.neonOrange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportedDeviceChip extends StatelessWidget {
  final String label;

  const _SupportedDeviceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.palette.glassBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}
