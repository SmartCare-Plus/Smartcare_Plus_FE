/// SMARTCARE+ voice transcription service.
///
/// Records a short native Android WAV clip and sends it to the backend Gemini
/// STT proxy. Gemini credentials remain server-side only.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/auth_provider.dart';
import 'api_service.dart';

enum VoiceInputStatus { ready, permissionDenied, unavailable, error }

class VoiceTranscriptionService {
  VoiceTranscriptionService(this._ref);

  static const MethodChannel _channel =
      MethodChannel('smartcare_plus/audio_recorder');

  final Ref _ref;
  String? _audioPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<VoiceInputStatus> startListening({
    Duration maxDuration = const Duration(seconds: 8),
  }) async {
    if (!Platform.isAndroid) return VoiceInputStatus.unavailable;

    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) return VoiceInputStatus.permissionDenied;

      if (_isRecording) {
        await cancel();
      }

      final dir = await getTemporaryDirectory();
      _audioPath =
          '${dir.path}/smartcare_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _channel.invokeMethod<void>('start', {'path': _audioPath});
      _isRecording = true;

      return VoiceInputStatus.ready;
    } on MissingPluginException {
      return VoiceInputStatus.unavailable;
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') {
        return VoiceInputStatus.permissionDenied;
      }
      return VoiceInputStatus.error;
    } catch (_) {
      return VoiceInputStatus.error;
    }
  }

  Future<String> stopAndTranscribe({String locale = 'en-US'}) async {
    if (!_isRecording) return '';

    try {
      final path = await _channel.invokeMethod<String>('stop') ?? _audioPath;
      _isRecording = false;
      if (path == null || !await File(path).exists()) {
        throw Exception('No voice sample captured');
      }
      return await _transcribe(path, locale: locale);
    } finally {
      _isRecording = false;
      await _cleanupTempAudio();
    }
  }

  Future<void> cancel() async {
    if (_isRecording) {
      await _channel.invokeMethod<void>('cancel');
    }
    _isRecording = false;
    await _cleanupTempAudio();
  }

  Future<void> openSystemSettings() => openAppSettings();

  Future<String> _transcribe(String path, {required String locale}) async {
    final user = _ref.read(authProvider).firebaseUser;
    final token = await user?.getIdToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/accessibility/speech-to-text'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.fields['locale'] = locale;
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        path,
        filename: 'voice.wav',
      ),
    );

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'Voice transcription failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] is String) {
          detail = decoded['detail'] as String;
        }
      } catch (_) {}
      throw Exception(detail);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['text'] as String? ?? '').trim();
    }
    return '';
  }

  Future<void> _cleanupTempAudio() async {
    final path = _audioPath;
    _audioPath = null;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final voiceTranscriptionServiceProvider = Provider<VoiceTranscriptionService>(
  (ref) => VoiceTranscriptionService(ref),
);
