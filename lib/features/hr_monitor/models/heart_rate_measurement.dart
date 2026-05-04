class HeartRateMeasurement {
  const HeartRateMeasurement({
    required this.bpm,
    required this.flags,
    required this.rawPayload,
    required this.usesUint16Format,
    required this.contactSupported,
    required this.contactDetected,
    required this.energyExpended,
    required this.rrIntervalsMs,
  });

  final int bpm;
  final int flags;
  final List<int> rawPayload;
  final bool usesUint16Format;
  final bool contactSupported;
  final bool contactDetected;
  final int? energyExpended;
  final List<double> rrIntervalsMs;

  String get flagsHex => '0x${flags.toRadixString(16).padLeft(2, '0')}';

  String get rawHex {
    return rawPayload
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  String get contactState {
    if (!contactSupported) {
      return 'unsupported';
    }
    return contactDetected ? 'detected' : 'not_detected';
  }
}
