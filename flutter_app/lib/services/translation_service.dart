/// Local translation service powered by Ollama.
///
/// Calls: POST http://localhost:11434/api/generate
/// No cloud, no external APIs — 100 % local.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class TranslationException implements Exception {
  const TranslationException(this.message);
  final String message;
  @override
  String toString() => 'TranslationException: $message';
}

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final _client = http.Client();

  static const _names = {
    'de': 'German',
    'en': 'English',
    'fr': 'French',
    'ar': 'Arabic',
  };

  static const _welcomeMap = {
    'en': {
      'Willkommen bei Hilfe zur Pflege.': 'Welcome to Care Assistance.',
      'Bitte wählen Sie aus, ob Sie ein Antragsformular des Landkreises Hildesheim benötigen oder Fragen stellen möchten.':
          'Please select whether you need an application form for Hildesheim District or would like to ask questions.',
    },
    'fr': {
      'Willkommen bei Hilfe zur Pflege.': 'Bienvenue sur Aide aux soins.',
      'Bitte wählen Sie aus, ob Sie ein Antragsformular des Landkreises Hildesheim benötigen oder Fragen stellen möchten.':
          'Veuillez sélectionner si vous avez besoin d\'un formulaire de demande du district de Hildesheim ou si vous souhaitez poser des questions.',
    },
    'ar': {
      'Willkommen bei Hilfe zur Pflege.': 'مرحباً بكم في مساعدة التمريض.',
      'Bitte wählen Sie aus, ob Sie ein Antragsformular des Landkreises Hildesheim benötigen oder Fragen stellen möchten.':
          'يرجى تحديد ما إذا كنت بحاجة إلى نموذج طلب مقاطعة هيلدسهايم أو ترغب في طرح أسئلة.',
    },
  };

  /// Translates [text] from [fromLang] to [toLang] using Ollama.
  Future<String> translate({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (fromLang == toLang) return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    // 1. Instant static lookup for standard Typebot welcome messages
    if (fromLang == 'de' && _welcomeMap.containsKey(toLang)) {
      final staticMatch = _welcomeMap[toLang]?[trimmed];
      if (staticMatch != null) return staticMatch;
    }

    final from = _names[fromLang] ?? fromLang;
    final to = _names[toLang] ?? toLang;

    final prompt = '''You are a professional translator.
Translate the following $from text to $to.
IMPORTANT: Return ONLY the translated text. No explanation, no prefix, no quotation marks.

$text''';

    final models = [AppConfig.ollamaModel, 'mistral', 'llama3.2:1b'];

    for (final model in models) {
      try {
        final url = Uri.parse('${AppConfig.ollamaBaseUrl}/api/generate');
        final body = json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {'temperature': 0.1, 'num_predict': 2000},
        });

        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(AppConfig.translationTimeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final translated = (data['response'] as String? ?? '').trim();
          if (translated.isNotEmpty) return translated;
        }
      } catch (_) {
        continue;
      }
    }

    return text;
  }

  Future<String> toGerman(String text, String fromLang) =>
      translate(text: text, fromLang: fromLang, toLang: 'de');

  Future<String> fromGerman(String text, String toLang) =>
      translate(text: text, fromLang: 'de', toLang: toLang);
}
