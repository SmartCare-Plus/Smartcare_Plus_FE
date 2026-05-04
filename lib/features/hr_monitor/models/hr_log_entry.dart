enum HrLogLevel { info, warning, error }

class HrLogEntry {
  const HrLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final HrLogLevel level;
  final String message;

  String toExportLine() {
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] $message';
  }
}
