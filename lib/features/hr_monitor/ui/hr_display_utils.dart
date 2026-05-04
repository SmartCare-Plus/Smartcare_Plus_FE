import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../config/hr_monitor_config.dart';

class HrDisplayUtils {
  const HrDisplayUtils._();

  static bool isLive({
    required int? bpm,
    required DateTime? lastReadingAt,
    required bool isStale,
  }) {
    if (bpm == null || lastReadingAt == null || isStale) return false;
    return DateTime.now().difference(lastReadingAt).inSeconds <=
        HrMonitorConfig.liveReadingWindowSeconds;
  }

  static Color zoneColor(int? bpm) {
    if (bpm == null) return AppColors.neonCyan;
    if (bpm < HrMonitorConfig.zoneCriticalLowThreshold) {
      return AppColors.neonRed;
    }
    if (bpm < HrMonitorConfig.zoneLowThreshold) return AppColors.neonOrange;
    if (bpm < HrMonitorConfig.zoneBelowNormalThreshold) {
      return AppColors.neonBlue;
    }
    if (bpm <= HrMonitorConfig.zoneNormalUpperThreshold) {
      return AppColors.neonGreen;
    }
    if (bpm <= HrMonitorConfig.zoneMildUpperThreshold) {
      return AppColors.neonCyan;
    }
    if (bpm <= HrMonitorConfig.zoneElevatedUpperThreshold) {
      return AppColors.neonPurple;
    }
    if (bpm <= HrMonitorConfig.zoneHighUpperThreshold) {
      return AppColors.neonOrange;
    }
    return AppColors.neonRed;
  }

  static String statusLabel(int? bpm) {
    if (bpm == null) return 'No Data';
    if (bpm < HrMonitorConfig.lowRiskThreshold) return 'Low';
    if (bpm <= HrMonitorConfig.highRiskThreshold) return 'Normal';
    if (bpm <= HrMonitorConfig.elevatedStatusThreshold) return 'Elevated';
    return 'High';
  }

  static double progress(int? bpm) {
    if (bpm == null) return 0.0;
    return ((bpm - HrMonitorConfig.progressMinBpm) /
            HrMonitorConfig.progressRangeBpm)
        .clamp(0.0, 1.0);
  }

  static String updatedAgoLabel(DateTime? lastReadingAt) {
    if (lastReadingAt == null) return 'No recent reading';
    final seconds = DateTime.now().difference(lastReadingAt).inSeconds;
    if (seconds <= 1) return 'updated just now';
    if (seconds < 60) return 'updated ${seconds}s ago';
    final minutes = seconds ~/ 60;
    return 'updated ${minutes}m ago';
  }
}
