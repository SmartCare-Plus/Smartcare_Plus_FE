import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/hr_monitor/controllers/hr_monitor_controller.dart';

/// BLE heart-rate monitor controller provider.
///
/// Kept as a single shared controller so the elderly dashboard can keep
/// streaming state while switching tabs.
final hrMonitorProvider = ChangeNotifierProvider<HrMonitorController>((ref) {
  final controller = HrMonitorController();
  ref.onDispose(controller.dispose);
  return controller;
});
