class HrMonitorConfig {
  const HrMonitorConfig._();

  // Sampling and connection behavior
  static const int maxLogEntries = 1000;
  static const int maxRecentBpmSamples = 30;
  static const int maxReconnectAttempts = 5;
  static const int staleReadingSeconds = 10;
  static const int maxStaleResubscribeAttempts = 1;
  static const int initialSubscribeDelayMs = 700;
  static const int maxSubscribeRetryAttempts = 3;
  static const int subscribeRetryDelayMs = 800;
  static const int liveReadingWindowSeconds = 15;
  static const double smoothingAlpha = 0.35;

  // Risk alert thresholds
  static const int sustainedRiskAlertSeconds = 5;
  static const int lowRiskThreshold = 60;
  static const int highRiskThreshold = 100;
  static const int elevatedStatusThreshold = 120;

  // UI display scaling
  static const int progressMinBpm = 40;
  static const int progressRangeBpm = 140;

  // Optional color zone breakpoints
  static const int zoneCriticalLowThreshold = 45;
  static const int zoneLowThreshold = 55;
  static const int zoneBelowNormalThreshold = 65;
  static const int zoneNormalUpperThreshold = 90;
  static const int zoneMildUpperThreshold = 105;
  static const int zoneElevatedUpperThreshold = 120;
  static const int zoneHighUpperThreshold = 135;
}
