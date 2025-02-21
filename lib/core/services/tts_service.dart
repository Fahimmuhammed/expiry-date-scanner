import 'dart:developer';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  TTSService() {
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speak Out the Text
  Future<void> speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Stop Speaking
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Check if Speech Recognition is Available
  Future<bool> isListening() async {
    return _isListening;
  }

  /// Start Listening for Voice Command
  Future<void> startListening(Function(String) onResult) async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done') {
          _isListening = false;
        }
      },
      onError: (error) {
        log('Speech Recognition Error: $error');
        _isListening = false;
      },
    );

    if (available) {
      _isListening = true;
      _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: 'en_US',
      );
    }
  }

  /// Stop Listening
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
  }
}
