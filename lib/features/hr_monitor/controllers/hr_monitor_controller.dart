import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/hr_monitor_config.dart';
import '../models/heart_rate_measurement.dart';
import '../models/hr_connection_state.dart';
import '../models/hr_log_entry.dart';
import '../services/hr_packet_parser.dart';

class HrMonitorController extends ChangeNotifier {
  HrMonitorController({FlutterReactiveBle? ble})
      : _ble = ble ?? FlutterReactiveBle() {
    _log(HrLogLevel.info, 'HR monitor controller initialized.', notify: false);

    _bleStatusSubscription = _ble.statusStream.listen((status) {
      if (_bleStatus == status) {
        return;
      }

      _bleStatus = status;
      _log(
        HrLogLevel.info,
        'BLE adapter state: ${status.name}.',
        notify: false,
      );
      if (!_isDisposed) {
        notifyListeners();
      }
    });

    unawaited(_restorePreferences());
  }

  final FlutterReactiveBle _ble;

  final Uuid _heartRateServiceUuid = Uuid.parse(
    '0000180d-0000-1000-8000-00805f9b34fb',
  );
  final Uuid _heartRateMeasurementUuid = Uuid.parse(
    '00002a37-0000-1000-8000-00805f9b34fb',
  );

  static const int _maxLogEntries = HrMonitorConfig.maxLogEntries;
  static const int _maxRecentBpmSamples = HrMonitorConfig.maxRecentBpmSamples;
  static const int _maxReconnectAttempts = HrMonitorConfig.maxReconnectAttempts;
  static const double _smoothingAlpha = HrMonitorConfig.smoothingAlpha;
  static const int _sustainedRiskAlertSeconds =
      HrMonitorConfig.sustainedRiskAlertSeconds;
  static const int _lowRiskThreshold = HrMonitorConfig.lowRiskThreshold;
  static const int _highRiskThreshold = HrMonitorConfig.highRiskThreshold;

  static const String _prefLastKnownDeviceId = 'hr_last_known_device_id';
  static const String _prefLastKnownDeviceName = 'hr_last_known_device_name';
  static const String _prefAutoConnectEnabled = 'hr_auto_connect_enabled';

  final List<HrLogEntry> _logs = <HrLogEntry>[];
  final List<int> _recentBpmSamples = <int>[];

  StreamSubscription<BleStatus>? _bleStatusSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _hrSubscription;

  Timer? _scanTimeoutTimer;
  Timer? _staleTimer;
  Timer? _reconnectTimer;
  Timer? _subscribeRetryTimer;

  BleStatus _bleStatus = BleStatus.unknown;
  HrConnectionState _state = HrConnectionState.idle;
  String _statusMessage =
      'Tap "Scan & Connect" after enabling Share HR / HR Broadcast on your band.';

  String? _connectedDeviceId;
  String? _connectedDeviceName;
  String? _lastKnownDeviceId;
  int? _currentBpm;
  HeartRateMeasurement? _lastMeasurement;
  int _measurementPacketCount = 0;
  DateTime? _lastReadingAt;
  bool _isStale = false;
  double? _smoothedBpmValue;
  String? _healthAlertMessage;
  DateTime? _riskStartedAt;
  String? _riskType;
  bool _autoConnectEnabled = true;
  String? _rememberedDeviceName;

  int _reconnectAttempt = 0;
  int _subscribeRetryAttempt = 0;
  bool _manualDisconnect = false;
  bool _isDisposed = false;
  bool _isStaleRecoveryInProgress = false;
  int _staleResubscribeAttempt = 0;

  DateTime? _lastMeasurementLogAt;
  int? _lastMeasurementLoggedBpm;

  BleStatus get bleStatus => _bleStatus;
  HrConnectionState get state => _state;
  String get statusMessage => _statusMessage;
  String get connectedDeviceId => _connectedDeviceId ?? '-';
  String get connectedDeviceName => _connectedDeviceName ?? 'Not connected';
  int? get currentBpm => _currentBpm;
  int? get smoothedBpm => _smoothedBpmValue?.round();
  int? get displayBpm {
    if (_currentBpm == null ||
        _isStale ||
        _state != HrConnectionState.streaming) {
      return null;
    }
    return smoothedBpm ?? _currentBpm;
  }

  HeartRateMeasurement? get lastMeasurement => _lastMeasurement;
  int get measurementPacketCount => _measurementPacketCount;
  DateTime? get lastReadingAt => _lastReadingAt;
  bool get isStale => _isStale;
  String? get healthAlertMessage => _healthAlertMessage;
  bool get autoConnectEnabled => _autoConnectEnabled;
  String? get rememberedDeviceName => _rememberedDeviceName;
  Duration? get ageOfLastReading => _lastReadingAt == null
      ? null
      : DateTime.now().difference(_lastReadingAt!);
  List<HrLogEntry> get logs => List<HrLogEntry>.unmodifiable(_logs);
  List<int> get recentBpmSamples => List<int>.unmodifiable(_recentBpmSamples);

  bool get isBusy {
    return _state == HrConnectionState.requestingPermissions ||
        _state == HrConnectionState.scanning ||
        _state == HrConnectionState.connecting;
  }

  bool get hasActiveConnection {
    return _state == HrConnectionState.connecting ||
        _state == HrConnectionState.connected ||
        _state == HrConnectionState.streaming;
  }

  bool get hasLogs => _logs.isNotEmpty;

  Future<void> scanAndConnect() async {
    _manualDisconnect = false;
    _reconnectAttempt = 0;
    await _runConnectionCycle();
  }

  Future<void> reconnectNow() async {
    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _runConnectionCycle();
  }

  /// Best-effort auto-connect used by dashboard entry.
  ///
  /// Behavior is intentionally conservative:
  /// - Attempts only when permissions are already granted
  /// - Does not trigger reconnect backoff if no device is found
  /// - Keeps manual connect/reconnect flow unchanged
  Future<void> autoConnectIfAvailable() async {
    if (_isDisposed || isBusy || hasActiveConnection) {
      return;
    }
    if (!_autoConnectEnabled) {
      return;
    }

    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    if (!scanStatus.isGranted || !connectStatus.isGranted) {
      return;
    }

    if (_bleStatus != BleStatus.ready) {
      return;
    }

    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _clearActiveConnection();
    _updateStatus(
      state: HrConnectionState.scanning,
      message: 'Checking for nearby heart-rate wearable...',
      level: HrLogLevel.info,
    );

    DiscoveredDevice? device;
    try {
      device = await _scanForTargetDevice();
    } catch (_) {
      _updateStatus(
        state: HrConnectionState.idle,
        message:
            'Auto-connect is ready. Open Connect Device to start manual scan.',
        level: HrLogLevel.info,
      );
      return;
    }

    if (device == null) {
      _updateStatus(
        state: HrConnectionState.idle,
        message: 'No wearable found nearby. You can connect anytime.',
        level: HrLogLevel.info,
      );
      return;
    }

    _connectedDeviceId = device.id;
    _connectedDeviceName = _readableName(device.name, device.id);
    _lastKnownDeviceId = device.id;
    _listenToConnection(device);
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _clearActiveConnection();

    _clearRealtimeReading(clearHistory: true);
    _updateStatus(
      state: HrConnectionState.idle,
      message: 'Disconnected.',
      level: HrLogLevel.warning,
    );
  }

  Future<void> setAutoConnectEnabled(bool enabled) async {
    if (_autoConnectEnabled == enabled) return;
    _autoConnectEnabled = enabled;
    if (!_isDisposed) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAutoConnectEnabled, enabled);
    } catch (_) {
      // Ignore persistence failures to keep BLE flow resilient.
    }
  }

  Future<void> forgetRememberedDevice() async {
    _lastKnownDeviceId = null;
    _rememberedDeviceName = null;
    if (!_isDisposed) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefLastKnownDeviceId);
      await prefs.remove(_prefLastKnownDeviceName);
    } catch (_) {
      // Ignore persistence failures to keep BLE flow resilient.
    }
  }

  void clearLogs() {
    _logs.clear();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('BLE Heart Rate Session Log');
    buffer.writeln('GeneratedAt=${DateTime.now().toIso8601String()}');
    buffer.writeln('ConnectionState=${_state.name}');
    buffer.writeln('DeviceName=${_connectedDeviceName ?? ''}');
    buffer.writeln('DeviceId=${_connectedDeviceId ?? ''}');
    buffer.writeln('CurrentBpm=${_currentBpm?.toString() ?? ''}');
    buffer.writeln('PacketCount=$_measurementPacketCount');
    buffer.writeln('LastReadingAt=${_lastReadingAt?.toIso8601String() ?? ''}');
    if (_lastMeasurement != null) {
      buffer.writeln('LastFlags=${_lastMeasurement!.flagsHex}');
      buffer.writeln('LastRawPacket=${_lastMeasurement!.rawHex}');
      buffer.writeln(
        'LastValueFormat=${_lastMeasurement!.usesUint16Format ? 'uint16' : 'uint8'}',
      );
      buffer.writeln(
        'LastEnergyExpended=${_lastMeasurement!.energyExpended?.toString() ?? ''}',
      );
      buffer.writeln(
        'LastRrIntervalsMs=${_lastMeasurement!.rrIntervalsMs.map((v) => v.toStringAsFixed(1)).join(',')}',
      );
      buffer.writeln('LastContactState=${_lastMeasurement!.contactState}');
    }
    buffer.writeln('BleAdapter=${_bleStatus.name}');
    buffer.writeln('---');

    if (_logs.isEmpty) {
      buffer.writeln('[no logs captured]');
      return buffer.toString();
    }

    for (final entry in _logs) {
      buffer.writeln(entry.toExportLine());
    }

    return buffer.toString();
  }

  Future<void> _runConnectionCycle() async {
    if (_isDisposed) {
      return;
    }

    _log(HrLogLevel.info, 'Starting connection cycle.', notify: false);

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _clearActiveConnection();

    final hasPermissions = await _ensurePermissions();
    if (!hasPermissions) {
      return;
    }

    if (_bleStatus != BleStatus.ready) {
      _updateStatus(
        state: HrConnectionState.error,
        message:
            'Bluetooth is not ready. Turn on Bluetooth and keep the watch in Share HR mode.',
        level: HrLogLevel.error,
      );
      _scheduleReconnect();
      return;
    }

    DiscoveredDevice? device;
    try {
      device = await _scanForTargetDevice();
    } catch (error) {
      _updateStatus(
        state: HrConnectionState.error,
        message: 'BLE scan failed: $error',
        level: HrLogLevel.error,
      );
      _scheduleReconnect();
      return;
    }

    if (device == null) {
      _updateStatus(
        state: HrConnectionState.error,
        message:
            'No Huawei/Xiaomi HR-sharing watch found. Enable Share HR and keep screen awake.',
        level: HrLogLevel.warning,
      );
      _scheduleReconnect();
      return;
    }

    _connectedDeviceId = device.id;
    _connectedDeviceName = _readableName(device.name, device.id);
    _lastKnownDeviceId = device.id;

    _listenToConnection(device);
  }

  Future<bool> _ensurePermissions() async {
    _updateStatus(
      state: HrConnectionState.requestingPermissions,
      message: 'Requesting Bluetooth permissions...',
    );

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    final bluetoothReady = scan.isGranted && connect.isGranted;
    if (!bluetoothReady) {
      _updateStatus(
        state: HrConnectionState.error,
        message:
            'Bluetooth scan/connect permissions were denied. Allow them in app settings.',
        level: HrLogLevel.error,
      );
      return false;
    }

    if (!location.isGranted && !location.isLimited) {
      _log(
        HrLogLevel.warning,
        'Location permission not granted. Android 10/11 may still require it for scanning.',
        notify: false,
      );
      _statusMessage =
          'Bluetooth granted. Android 10/11 may also require location for BLE scan.';
      if (!_isDisposed) {
        notifyListeners();
      }
    }

    return true;
  }

  Future<DiscoveredDevice?> _scanForTargetDevice() async {
    _updateStatus(
      state: HrConnectionState.scanning,
      message: 'Scanning for heart-rate watches (service 180D)...',
    );

    final byService = await _scan(
      withServices: <Uuid>[_heartRateServiceUuid],
      timeout: const Duration(seconds: 8),
      acceptUnnamed: true,
    );
    if (byService != null) {
      return byService;
    }

    _updateStatus(
      state: HrConnectionState.scanning,
      message: 'No 180D advert found. Fallback scan by device name...',
      level: HrLogLevel.warning,
    );

    return _scan(
      withServices: const <Uuid>[],
      timeout: const Duration(seconds: 8),
      acceptUnnamed: false,
    );
  }

  Future<DiscoveredDevice?> _scan({
    required List<Uuid> withServices,
    required Duration timeout,
    required bool acceptUnnamed,
  }) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    final completer = Completer<DiscoveredDevice?>();

    _scanSubscription = _ble
        .scanForDevices(
      withServices: withServices,
      scanMode: ScanMode.lowLatency,
    )
        .listen(
      (device) {
        if (!_isTargetWatch(device, acceptUnnamed: acceptUnnamed)) {
          return;
        }

        if (!completer.isCompleted) {
          _log(
            HrLogLevel.info,
            'Found candidate: ${_readableName(device.name, device.id)} '
            '(id=${device.id}, rssi=${device.rssi}).',
            notify: false,
          );
          completer.complete(device);
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    try {
      return await completer.future;
    } finally {
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = null;

      final sub = _scanSubscription;
      _scanSubscription = null;
      if (sub != null) {
        await sub.cancel();
      }
    }
  }

  bool _isTargetWatch(DiscoveredDevice device, {required bool acceptUnnamed}) {
    if (_lastKnownDeviceId != null && device.id == _lastKnownDeviceId) {
      return true;
    }

    final name = device.name.toLowerCase();
    if (name.isEmpty) {
      return acceptUnnamed;
    }

    return name.contains('huawei') ||
        name.contains('hr-a8a') ||
        name.contains('xiaomi') ||
        name.contains('mi band') ||
        name.contains('smart band');
  }

  void _listenToConnection(DiscoveredDevice device) {
    final watchName = _readableName(device.name, device.id);

    _updateStatus(
      state: HrConnectionState.connecting,
      message: 'Connecting to $watchName...',
    );

    _connectionSubscription = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 12),
    )
        .listen(
      (update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _connectedDeviceId = update.deviceId;
          _connectedDeviceName = watchName;
          _rememberedDeviceName = watchName;
          _lastMeasurementLogAt = null;
          _lastMeasurementLoggedBpm = null;
          _lastMeasurement = null;
          _measurementPacketCount = 0;
          _recentBpmSamples.clear();
          _smoothedBpmValue = null;
          _healthAlertMessage = null;
          _riskStartedAt = null;
          _riskType = null;

          _updateStatus(
            state: HrConnectionState.connected,
            message:
                'Connected to $watchName. Waiting for heart-rate packets...',
          );
          _reconnectAttempt = 0;
          unawaited(_persistLastKnownDevice(
              update.deviceId, _readableName(watchName, update.deviceId)));

          _resetSubscriptionRetryState();
          _resetStaleTimer();
          unawaited(_startHeartRateSubscriptionWithWarmup(update.deviceId));
          return;
        }

        if (update.connectionState == DeviceConnectionState.disconnected) {
          _handleUnexpectedDisconnect('Watch disconnected.');
        }
      },
      onError: (Object error) {
        _handleUnexpectedDisconnect('Connection error: $error');
      },
    );
  }

  void _subscribeToHeartRate(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: _heartRateServiceUuid,
      characteristicId: _heartRateMeasurementUuid,
      deviceId: deviceId,
    );

    _hrSubscription?.cancel();
    _hrSubscription = null;

    _hrSubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (payload) {
        final measurement = parseHeartRatePacket(payload);
        if (measurement == null ||
            measurement.bpm < 30 ||
            measurement.bpm > 240) {
          return;
        }

        _currentBpm = measurement.bpm;
        _recentBpmSamples.add(measurement.bpm);
        if (_recentBpmSamples.length > _maxRecentBpmSamples) {
          _recentBpmSamples.removeRange(
              0, _recentBpmSamples.length - _maxRecentBpmSamples);
        }
        _updateSmoothedBpm(measurement.bpm);
        _updateSustainedRiskAlert(measurement.bpm);
        _lastMeasurement = measurement;
        _measurementPacketCount += 1;
        _lastReadingAt = DateTime.now();
        _isStale = false;
        _isStaleRecoveryInProgress = false;
        _staleResubscribeAttempt = 0;
        _resetSubscriptionRetryState();
        _state = HrConnectionState.streaming;
        _statusMessage =
            'Receiving heart rate from ${_connectedDeviceName ?? deviceId}.';
        _reconnectAttempt = 0;
        _logMeasurementSample(measurement);
        _resetStaleTimer();
        if (!_isDisposed) {
          notifyListeners();
        }
      },
      onError: (Object error) {
        _log(
          HrLogLevel.warning,
          'Heart-rate notification failed: $error',
          notify: false,
        );
        _handleSubscriptionError(error, deviceId);
      },
    );
  }

  Future<void> _startHeartRateSubscriptionWithWarmup(String deviceId) async {
    const delayMs = HrMonitorConfig.initialSubscribeDelayMs;
    if (delayMs > 0) {
      await Future<void>.delayed(const Duration(milliseconds: delayMs));
    }

    if (_isDisposed || _manualDisconnect) {
      return;
    }

    if (_connectedDeviceId != deviceId) {
      return;
    }

    _subscribeToHeartRate(deviceId);
  }

  void _logMeasurementSample(HeartRateMeasurement measurement) {
    final now = DateTime.now();

    final isFirst = _lastMeasurementLogAt == null;
    final elapsedEnough = _lastMeasurementLogAt != null &&
        now.difference(_lastMeasurementLogAt!).inSeconds >= 5;
    final changedEnough = _lastMeasurementLoggedBpm != null &&
        (measurement.bpm - _lastMeasurementLoggedBpm!).abs() >= 3;

    if (!(isFirst || elapsedEnough || changedEnough)) {
      return;
    }

    _lastMeasurementLogAt = now;
    _lastMeasurementLoggedBpm = measurement.bpm;

    final parts = <String>[
      'HR sample received: ${measurement.bpm} bpm.',
      'flags=${measurement.flagsHex}',
      'raw=${measurement.rawHex}',
      'format=${measurement.usesUint16Format ? 'uint16' : 'uint8'}',
      'contact=${measurement.contactState}',
    ];
    if (measurement.energyExpended != null) {
      parts.add('energy=${measurement.energyExpended}');
    }
    if (measurement.rrIntervalsMs.isNotEmpty) {
      final rrJoined = measurement.rrIntervalsMs
          .map((value) => value.toStringAsFixed(1))
          .join(',');
      parts.add('rrMs=$rrJoined');
    }

    _log(HrLogLevel.info, parts.join(' '), notify: false);
  }

  void _resetStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer =
        Timer(const Duration(seconds: HrMonitorConfig.staleReadingSeconds), () {
      if (_isDisposed) {
        return;
      }

      if (_state == HrConnectionState.connected ||
          _state == HrConnectionState.streaming) {
        _state = HrConnectionState.connected;
        _clearRealtimeReading();
        _isStale = true;
        _statusMessage =
            'Connected, waiting for fresh heart-rate packets. Recovering stream...';
        _log(HrLogLevel.warning, _statusMessage, notify: false);
        notifyListeners();
        unawaited(_recoverStaleHeartRateStream());
      }
    });
  }

  Future<void> _recoverStaleHeartRateStream() async {
    if (_isDisposed || _manualDisconnect) {
      return;
    }

    final deviceId = _connectedDeviceId;
    if (deviceId == null || deviceId.isEmpty) {
      return;
    }

    if (_isStaleRecoveryInProgress) {
      return;
    }

    _isStaleRecoveryInProgress = true;
    try {
      if (_staleResubscribeAttempt <
          HrMonitorConfig.maxStaleResubscribeAttempts) {
        _staleResubscribeAttempt += 1;
        _log(
          HrLogLevel.warning,
          'No HR packets detected. Re-subscribing to heart-rate notifications '
          '(attempt $_staleResubscribeAttempt/${HrMonitorConfig.maxStaleResubscribeAttempts}).',
          notify: false,
        );
        _updateStatus(
          state: HrConnectionState.connected,
          message:
              'Connected, but stream paused. Trying to recover heart-rate notifications...',
          level: HrLogLevel.warning,
        );
        await _hrSubscription?.cancel();
        _hrSubscription = null;
        _subscribeToHeartRate(deviceId);
        return;
      }

      _staleResubscribeAttempt = 0;
      _handleUnexpectedDisconnect(
        'Heart-rate stream stalled. Reconnecting automatically...',
      );
    } finally {
      _isStaleRecoveryInProgress = false;
    }
  }

  void _handleSubscriptionError(Object error, String deviceId) {
    if (_isDisposed || _manualDisconnect) {
      return;
    }

    if (_connectedDeviceId != deviceId) {
      return;
    }

    final retriable = _isRetriableSubscribeError(error);
    if (retriable &&
        _subscribeRetryAttempt < HrMonitorConfig.maxSubscribeRetryAttempts) {
      _subscribeRetryAttempt += 1;
      const maxAttempts = HrMonitorConfig.maxSubscribeRetryAttempts;
      final retryDelayMs =
          HrMonitorConfig.subscribeRetryDelayMs * _subscribeRetryAttempt;

      _updateStatus(
        state: HrConnectionState.connected,
        message:
            'Connected to ${_connectedDeviceName ?? deviceId}, finalizing heart-rate stream '
            '($_subscribeRetryAttempt/$maxAttempts)...',
        level: HrLogLevel.warning,
      );
      _log(
        HrLogLevel.warning,
        'Retrying heart-rate notification subscription in ${retryDelayMs}ms '
        '(attempt $_subscribeRetryAttempt/$maxAttempts).',
        notify: false,
      );

      _subscribeRetryTimer?.cancel();
      _subscribeRetryTimer = Timer(Duration(milliseconds: retryDelayMs), () {
        if (_isDisposed || _manualDisconnect) {
          return;
        }
        if (_connectedDeviceId != deviceId) {
          return;
        }
        _subscribeToHeartRate(deviceId);
      });
      return;
    }

    _resetSubscriptionRetryState();
    _handleUnexpectedDisconnect(_friendlyHrErrorMessage(error));
  }

  bool _isRetriableSubscribeError(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('characteristic not found') ||
        raw.contains('not discovered') ||
        raw.contains('gatt') ||
        raw.contains('133') ||
        raw.contains('timeout');
  }

  void _updateSmoothedBpm(int bpm) {
    if (_smoothedBpmValue == null) {
      _smoothedBpmValue = bpm.toDouble();
      return;
    }
    _smoothedBpmValue =
        (_smoothedBpmValue! * (1 - _smoothingAlpha)) + (bpm * _smoothingAlpha);
  }

  void _updateSustainedRiskAlert(int bpm) {
    final now = DateTime.now();

    String? currentRisk;
    if (bpm < _lowRiskThreshold) {
      currentRisk = 'low';
    } else if (bpm > _highRiskThreshold) {
      currentRisk = 'high';
    }

    if (currentRisk == null) {
      _riskType = null;
      _riskStartedAt = null;
      _healthAlertMessage = null;
      return;
    }

    if (_riskType != currentRisk) {
      _riskType = currentRisk;
      _riskStartedAt = now;
      _healthAlertMessage = null;
      return;
    }

    _riskStartedAt ??= now;
    final elapsed = now.difference(_riskStartedAt!).inSeconds;
    if (elapsed >= _sustainedRiskAlertSeconds) {
      _healthAlertMessage = currentRisk == 'low'
          ? 'Sustained low heart-rate detected.'
          : 'Sustained high heart-rate detected.';
    }
  }

  void _handleUnexpectedDisconnect(String message) {
    if (_isDisposed) {
      return;
    }

    _staleTimer?.cancel();
    _staleTimer = null;
    _subscribeRetryTimer?.cancel();
    _subscribeRetryTimer = null;
    _subscribeRetryAttempt = 0;

    final hrSub = _hrSubscription;
    _hrSubscription = null;
    if (hrSub != null) {
      unawaited(hrSub.cancel());
    }

    final connSub = _connectionSubscription;
    _connectionSubscription = null;
    if (connSub != null) {
      unawaited(connSub.cancel());
    }

    _clearRealtimeReading();
    _isStaleRecoveryInProgress = false;
    _staleResubscribeAttempt = 0;

    _updateStatus(
      state: HrConnectionState.disconnected,
      message: message,
      level: HrLogLevel.warning,
    );

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _isDisposed) {
      return;
    }

    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _updateStatus(
        state: HrConnectionState.idle,
        message:
            'Connection lost. Auto-reconnect stopped after $_maxReconnectAttempts attempts. You can reconnect from Connect Device.',
        level: HrLogLevel.warning,
      );
      return;
    }

    _reconnectAttempt += 1;
    final delaySeconds = min(30, 1 << min(_reconnectAttempt - 1, 5));

    _log(
      HrLogLevel.warning,
      'Auto-reconnect scheduled in ${delaySeconds}s '
      '(attempt $_reconnectAttempt/$_maxReconnectAttempts).',
      notify: false,
    );
    if (!_isDisposed) {
      notifyListeners();
    }

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_manualDisconnect || _isDisposed) {
        return;
      }

      unawaited(_runConnectionCycle());
    });
  }

  String _friendlyHrErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('characteristic not found') ||
        raw.contains('not discovered') ||
        raw.contains('00002a37')) {
      return 'Connected, but no heart-rate stream. Turn on HR Share / Heart Rate Broadcast on the watch and keep it awake.';
    }
    return 'Heart-rate stream interrupted. Trying to reconnect...';
  }

  void _clearRealtimeReading({bool clearHistory = false}) {
    _currentBpm = null;
    _smoothedBpmValue = null;
    _lastMeasurement = null;
    _lastReadingAt = null;
    _isStale = false;
    _healthAlertMessage = null;
    _riskStartedAt = null;
    _riskType = null;

    if (clearHistory) {
      _recentBpmSamples.clear();
      _measurementPacketCount = 0;
      _lastMeasurementLogAt = null;
      _lastMeasurementLoggedBpm = null;
    }
  }

  Future<void> _clearActiveConnection() async {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    _staleTimer?.cancel();
    _staleTimer = null;
    _subscribeRetryTimer?.cancel();
    _subscribeRetryTimer = null;

    final scanSub = _scanSubscription;
    _scanSubscription = null;
    if (scanSub != null) {
      await scanSub.cancel();
    }

    final hrSub = _hrSubscription;
    _hrSubscription = null;
    if (hrSub != null) {
      await hrSub.cancel();
    }

    final connSub = _connectionSubscription;
    _connectionSubscription = null;
    if (connSub != null) {
      await connSub.cancel();
    }

    _isStaleRecoveryInProgress = false;
    _staleResubscribeAttempt = 0;
    _resetSubscriptionRetryState();
  }

  void _resetSubscriptionRetryState() {
    _subscribeRetryTimer?.cancel();
    _subscribeRetryTimer = null;
    _subscribeRetryAttempt = 0;
  }

  void _updateStatus({
    required HrConnectionState state,
    required String message,
    HrLogLevel level = HrLogLevel.info,
  }) {
    _state = state;
    _statusMessage = message;
    _log(level, message, notify: false);
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _log(HrLogLevel level, String message, {bool notify = true}) {
    if (_isDisposed) {
      return;
    }

    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_logs.isNotEmpty) {
      final last = _logs.last;
      final isDuplicate = last.level == level &&
          last.message == normalized &&
          now.difference(last.timestamp).inMilliseconds < 800;
      if (isDuplicate) {
        return;
      }
    }

    _logs.add(HrLogEntry(timestamp: now, level: level, message: normalized));

    if (_logs.length > _maxLogEntries) {
      _logs.removeRange(0, _logs.length - _maxLogEntries);
    }

    if (notify) {
      notifyListeners();
    }
  }

  String _readableName(String name, String id) {
    if (name.trim().isEmpty) {
      return id;
    }
    return name;
  }

  Future<void> _restorePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastKnownDeviceId = prefs.getString(_prefLastKnownDeviceId);
      _rememberedDeviceName = prefs.getString(_prefLastKnownDeviceName);
      _autoConnectEnabled = prefs.getBool(_prefAutoConnectEnabled) ?? true;
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (_) {
      // Ignore preference restore failures.
    }
  }

  Future<void> _persistLastKnownDevice(String id, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastKnownDeviceId, id);
      await prefs.setString(_prefLastKnownDeviceName, name);
    } catch (_) {
      // Ignore preference persistence failures.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    _reconnectTimer?.cancel();
    _scanTimeoutTimer?.cancel();
    _staleTimer?.cancel();
    _subscribeRetryTimer?.cancel();

    unawaited(_scanSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_hrSubscription?.cancel());
    unawaited(_bleStatusSubscription?.cancel());

    super.dispose();
  }
}
