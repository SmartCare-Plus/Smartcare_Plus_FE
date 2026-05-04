import '../models/heart_rate_measurement.dart';

int? parseHeartRateMeasurement(List<int> payload) {
  return parseHeartRatePacket(payload)?.bpm;
}

HeartRateMeasurement? parseHeartRatePacket(List<int> payload) {
  if (payload.length < 2) {
    return null;
  }

  final flags = payload[0];
  var index = 1;

  final usesUint16 = (flags & 0x01) != 0;

  int bpm;
  if (usesUint16) {
    if (payload.length < index + 2) {
      return null;
    }
    bpm = payload[index] | (payload[index + 1] << 8);
    index += 2;
  } else {
    bpm = payload[index];
    index += 1;
  }

  final contactBits = (flags >> 1) & 0x03;
  final contactSupported = contactBits == 0x02 || contactBits == 0x03;
  final contactDetected = contactBits == 0x03;

  int? energyExpended;
  if ((flags & 0x08) != 0) {
    if (payload.length < index + 2) {
      return null;
    }
    energyExpended = payload[index] | (payload[index + 1] << 8);
    index += 2;
  }

  final rrIntervalsMs = <double>[];
  if ((flags & 0x10) != 0) {
    while (payload.length >= index + 2) {
      final rrRaw = payload[index] | (payload[index + 1] << 8);
      rrIntervalsMs.add(rrRaw * 1000 / 1024);
      index += 2;
    }
  }

  return HeartRateMeasurement(
    bpm: bpm,
    flags: flags,
    rawPayload: List<int>.from(payload),
    usesUint16Format: usesUint16,
    contactSupported: contactSupported,
    contactDetected: contactDetected,
    energyExpended: energyExpended,
    rrIntervalsMs: rrIntervalsMs,
  );
}
