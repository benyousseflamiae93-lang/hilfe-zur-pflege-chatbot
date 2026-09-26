/// State management for the native chat UI.
///
/// Orchestrates:
///   1. Typebot session (startChat / continueChat)
///   2. Local Ollama translation (user-lang ↔ German)
///   3. TTS (speak / stop per-message)
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../services/typebot_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

// ── Chat state enum ───────────────────────────────────────────────────────────

enum ChatState {
  idle,
  initializing,
  translating,   // translating user input to German
  thinking,      // waiting for Typebot / RAG
  translatingResponse, // translating Typebot response back
  error,
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ChatProvider extends ChangeNotifier {
  final _typebot = TypebotService.instance;
  final _translation = TranslationService.instance;
  final _tts = TtsService.instance;

  String? _sessionId;
  String? _flow;
  String _locale = 'de';

  final List<ChatMessage> _messages = [];
  ChatState _state = ChatState.idle;
  String _errorMessage = '';
  TypebotInputInfo? _currentInput;
  String? _speakingMessageId;

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatState get state => _state;
  String get errorMessage => _errorMessage;
  TypebotInputInfo? get currentInput => _currentInput;
  String? get speakingMessageId => _speakingMessageId;

  bool get isInitializing => _state == ChatState.initializing;
  bool get isBusy => _state != ChatState.idle && _state != ChatState.error;
  bool get hasError => _state == ChatState.error;

  /// Human-readable status label displayed in the TypingIndicator.
  String get statusLabel {
    switch (_state) {
      case ChatState.translating:
        return 'Wird übersetzt…';
      case ChatState.thinking:
        return 'KI denkt nach…';
      case ChatState.translatingResponse:
        return 'Antwort wird übersetzt…';
      default:
        return 'KI denkt nach…';
    }
  }

  final Map<String, String> _choiceGermanMap = {};

  // ── Initialise / reset ───────────────────────────────────────────────────────

  Future<void> initialize({
    String? flow,
    String locale = 'de',
  }) async {
    _flow = flow;
    _locale = locale;
    _sessionId = null;
    _messages.clear();
    _currentInput = null;
    _choiceGermanMap.clear();
    _state = ChatState.initializing;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _typebot.startChat(
        prefilledVariables: flow != null ? {'flow': flow} : null,
      );
      _sessionId = result.sessionId;
      _currentInput = await _translateInput(result.input);

      // Translate initial bot messages
      for (final german in result.messages) {
        final display = await _safeFromGerman(german);
        _addBot(display);
      }

      _state = ChatState.idle;
    } on TypebotException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> reset() async {
    if (_sessionId != null) {
      try {
        final url = Uri.parse('http://localhost:8000/reset_chat');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'session_id': _sessionId}),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await initialize(flow: _flow, locale: _locale);
  }

  void updateLocale(String locale) {
    _locale = locale;
  }

  // ── Send a message ────────────────────────────────────────────────────────────

  Future<void> sendMessage(String userText) async {
    if (_sessionId == null || isBusy) return;

    _addUser(userText);

    try {
      // 1. Determine exact message string to send to Typebot
      String germanText;
      final trimmed = userText.trim();
      if (_choiceGermanMap.containsKey(trimmed)) {
        // Exact choice match mapping to Typebot's expected German string
        germanText = _choiceGermanMap[trimmed]!;
      } else if (_locale != 'de') {
        _state = ChatState.translating;
        notifyListeners();
        germanText = await _translation.toGerman(userText, _locale);
      } else {
        germanText = userText;
      }

      // 2. Send to Typebot → RAG → Ollama (backend)
      _state = ChatState.thinking;
      notifyListeners();

      final result = await _typebot.continueChat(
        sessionId: _sessionId!,
        message: germanText,
      );

      final germanResponse = result.messages.join('\n\n').trim();

      // 3. Translate response back (if needed)
      if (germanResponse.isNotEmpty) {
        String displayText = germanResponse;
        if (_locale != 'de') {
          _state = ChatState.translatingResponse;
          notifyListeners();
          displayText = await _safeFromGerman(germanResponse);
        }
        _addBot(displayText);
      }

      _currentInput = await _translateInput(result.input);
      _state = ChatState.idle;
    } on TypebotException catch (e) {
      _addBot('⚠ Verbindungsfehler: ${e.message}');
      _state = ChatState.idle;
    } catch (e) {
      _addBot('⚠ Fehler: $e');
      _state = ChatState.idle;
    }

    notifyListeners();
  }

  Future<TypebotInputInfo?> _translateInput(TypebotInputInfo? input) async {
    if (input == null || !input.isChoice) return input;
    final translatedChoices = <TypebotChoice>[];
    for (final choice in input.choices) {
      final raw = choice.content.trim();
      String translated = raw;
      if (_locale != 'de') {
        if (raw == 'Antrag starten') {
          translated = _getButtonText('nav_antrag');
        } else if (raw == 'Frage stellen') {
          translated = _getButtonText('nav_frage');
        } else {
          translated = await _translation.fromGerman(raw, _locale);
        }
      }
      _choiceGermanMap[translated.trim()] = raw;
      _choiceGermanMap[raw] = raw;
      translatedChoices.add(TypebotChoice(id: choice.id, content: translated));
    }
    return TypebotInputInfo(
      type: input.type,
      choices: translatedChoices,
      placeholder: input.placeholder,
      isLong: input.isLong,
    );
  }

  String _getButtonText(String key) {
    const map = {
      'en': {'nav_antrag': 'Start Application', 'nav_frage': 'Ask a Question'},
      'fr': {'nav_antrag': 'Commencer la demande', 'nav_frage': 'Poser une question'},
      'ar': {'nav_antrag': 'بدء الطلب', 'nav_frage': 'طرح سؤال'},
    };
    return map[_locale]?[key] ?? (key == 'nav_antrag' ? 'Antrag starten' : 'Frage stellen');
  }

  // ── TTS ───────────────────────────────────────────────────────────────────────

  Future<void> toggleSpeak(String text, String messageId) async {
    if (_speakingMessageId == messageId) {
      // Already speaking → stop
      await _tts.stop();
      _speakingMessageId = null;
      notifyListeners();
      return;
    }

    await _tts.stop();
    _speakingMessageId = messageId;
    notifyListeners();

    await _tts.speak(text, _locale, messageId: messageId);

    // Completion handler inside TtsService resets its own state;
    // we mirror it here.
    _speakingMessageId = null;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speakingMessageId = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  Future<String> _safeFromGerman(String text) async {
    if (_locale == 'de') return text;
    return _translation.fromGerman(text, _locale);
  }

  String _uid() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';

  void _addUser(String text) {
    _messages.add(ChatMessage(
      id: _uid(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void _addBot(String text) {
    _messages.add(ChatMessage(
      id: _uid(),
      text: text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
  }
}
