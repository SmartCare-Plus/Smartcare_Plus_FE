/// Voice input button for accessibility text fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/services/voice_transcription_service.dart';

class VoiceInputButton extends ConsumerStatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.controller,
    required this.fieldLabel,
    this.onTextInserted,
    this.transformTranscript,
    this.replaceText = false,
  });

  final TextEditingController controller;
  final String fieldLabel;
  final VoidCallback? onTextInserted;
  final String Function(String text)? transformTranscript;
  final bool replaceText;

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton> {
  bool _isListening = false;
  bool _isTranscribing = false;

  @override
  void dispose() {
    if (_isListening) {
      ref.read(voiceTranscriptionServiceProvider).cancel();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    final voice = ref.read(voiceTranscriptionServiceProvider);

    if (_isListening) {
      setState(() {
        _isListening = false;
        _isTranscribing = true;
      });
      try {
        final transcript = await voice.stopAndTranscribe();
        _insertTranscript(transcript);
      } catch (e) {
        _showMessage('$e');
      } finally {
        if (mounted) setState(() => _isTranscribing = false);
      }
      return;
    }

    final status = await voice.startListening();
    if (!mounted) return;
    switch (status) {
      case VoiceInputStatus.ready:
        setState(() => _isListening = true);
        break;
      case VoiceInputStatus.permissionDenied:
        _showMessage('Microphone permission is required for voice input.');
        break;
      case VoiceInputStatus.unavailable:
        _showMessage('Voice input is not available on this device.');
        break;
      case VoiceInputStatus.error:
        _showMessage('Unable to start voice input right now.');
        break;
    }
  }

  void _insertTranscript(String transcript) {
    final transformed =
        widget.transformTranscript?.call(transcript) ?? transcript.trim();
    if (transformed.isEmpty) {
      _showMessage('No speech detected. Please try again.');
      return;
    }

    final value = widget.controller.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    if (widget.replaceText) {
      widget.controller.value = TextEditingValue(
        text: transformed,
        selection: TextSelection.collapsed(offset: transformed.length),
      );
    } else {
      final prefix = text.substring(0, start);
      final suffix = text.substring(end);
      final needsSpace = prefix.isNotEmpty &&
          !RegExp(r'\s$').hasMatch(prefix) &&
          !RegExp(r'^(\s|[,.!?;:])').hasMatch(transformed);
      final insertion = needsSpace ? ' $transformed' : transformed;
      widget.controller.value = TextEditingValue(
        text: '$prefix$insertion$suffix',
        selection:
            TextSelection.collapsed(offset: prefix.length + insertion.length),
      );
    }
    widget.onTextInserted?.call();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _isListening || _isTranscribing;
    return Semantics(
      button: true,
      label: _isListening
          ? 'Stop voice input for ${widget.fieldLabel}'
          : 'Start voice input for ${widget.fieldLabel}',
      child: IconButton(
        tooltip: _isListening
            ? 'Stop voice input'
            : _isTranscribing
                ? 'Transcribing...'
                : 'Voice input',
        onPressed: _isTranscribing ? null : _toggle,
        icon: _isTranscribing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isListening ? Icons.stop_circle_outlined : Icons.mic_none,
                color: active ? AppColors.neonRed : AppColors.neonCyan,
              ),
      ),
    );
  }
}
