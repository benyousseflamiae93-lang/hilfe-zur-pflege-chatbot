/// Singleton TTS service wrapping flutter_tts.
///
/// Correctly maps locale codes (de / en / fr / ar) to BCP-47 language tags
/// and handles macOS quirks with AVSpeechSynthesizer.
library;

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  String? _currentMessageId;

  static const _langMap = {
    'de': 'de-DE',
    'en': 'en-US',
    'fr': 'fr-FR',
    'ar': 'ar-MA',
  };

  bool get isSpeaking => _isSpeaking;
  String? get currentMessageId => _currentMessageId;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(_onDone);
    _tts.setCancelHandler(_onDone);
    _tts.setErrorHandler((_) => _onDone());
    _initialized = true;
  }

  void _onDone() {
    _isSpeaking = false;
    _currentMessageId = null;
  }

  /// Speaks [text] in the locale matching [localeCode] (de / en / fr / ar).
  /// Stops any ongoing speech first.
  Future<void> speak(
    String text,
    String localeCode, {
    String? messageId,
  }) async {
    await stop();
    await _ensureInit();

    final lang = _langMap[localeCode] ?? 'de-DE';
    try {
      await _tts.setLanguage(lang);
      _isSpeaking = true;
      _currentMessageId = messageId;
      await _tts.speak(text);
    } catch (_) {
      _isSpeaking = false;
      _currentMessageId = null;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    _currentMessageId = null;
  }
}
