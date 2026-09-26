/// Typebot REST API service.
///
/// Calls the self-hosted Typebot v2 Chat API:
///   POST /api/v1/typebots/{botId}/startChat
///   POST /api/v1/typebots/{botId}/continueChat
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../utils/app_config.dart';

// ── Exception ─────────────────────────────────────────────────────────────────

class TypebotException implements Exception {
  const TypebotException(this.message);
  final String message;
  @override
  String toString() => 'TypebotException: $message';
}

// ── Result types ──────────────────────────────────────────────────────────────

class TypebotStartResult {
  const TypebotStartResult({
    required this.sessionId,
    required this.messages,
    this.input,
  });
  final String sessionId;
  final List<String> messages;
  final TypebotInputInfo? input;
}

class TypebotContinueResult {
  const TypebotContinueResult({
    required this.messages,
    this.input,
    this.hasEnded = false,
  });
  final List<String> messages;
  final TypebotInputInfo? input;
  final bool hasEnded;
}

// ── Service ───────────────────────────────────────────────────────────────────

class TypebotService {
  TypebotService._();
  static final TypebotService instance = TypebotService._();

  final _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AppConfig.typebotApiKey != null)
          'Authorization': 'Bearer ${AppConfig.typebotApiKey}',
      };

  String get _base =>
      '${AppConfig.typebotBaseUrl}/api/v1/typebots/${AppConfig.typebotBotId}';

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<TypebotStartResult> startChat({
    Map<String, dynamic>? prefilledVariables,
  }) async {
    final body = json.encode({
      if (prefilledVariables != null) 'prefilledVariables': prefilledVariables,
    });
    final raw = await _post('$_base/startChat', body);

    final sessionId = raw['sessionId'] as String? ??
        raw['conversationId'] as String? ??
        '';
    if (sessionId.isEmpty) {
      throw const TypebotException('No sessionId returned by Typebot');
    }

    return TypebotStartResult(
      sessionId: sessionId,
      messages: _extractMessages(raw['messages']),
      input: _parseInput(raw['input']),
    );
  }

  Future<TypebotContinueResult> continueChat({
    required String sessionId,
    required String message,
  }) async {
    final url = '${AppConfig.typebotBaseUrl}/api/v1/sessions/$sessionId/continueChat';
    final body = json.encode({'message': message});
    final raw = await _post(url, body);

    return TypebotContinueResult(
      messages: _extractMessages(raw['messages']),
      input: _parseInput(raw['input']),
      hasEnded: raw['input'] == null,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(String url, String body) async {
    try {
      final response = await _client
          .post(Uri.parse(url), headers: _headers, body: body)
          .timeout(AppConfig.typebotTimeout);

      if (response.statusCode != 200) {
        throw TypebotException(
          'HTTP ${response.statusCode} – ${response.reasonPhrase}',
        );
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } on TypebotException {
      rethrow;
    } catch (e) {
      throw TypebotException('Connection error: $e');
    }
  }

  static List<String> _extractMessages(dynamic raw) {
    if (raw is! List) return [];
    final result = <String>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] != 'text') continue;
      final content = item['content'];
      if (content is! Map<String, dynamic>) continue;
      final text = _textFromContent(content);
      if (text.isNotEmpty) result.add(text);
    }
    return result;
  }

  static String _textFromContent(Map<String, dynamic> content) {
    // 1. plaintextContent (cleanest)
    final plain = content['plaintextContent'];
    if (plain is String && plain.isNotEmpty) return plain.trim();
    // 2. HTML stripping
    final html = content['html'];
    if (html is String && html.isNotEmpty) return _stripHtml(html).trim();
    // 3. richText recursion
    final rich = content['richText'];
    if (rich is List) return _richToText(rich).trim();
    return '';
  }

  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .trim();

  static String _richToText(List items) {
    final buf = StringBuffer();
    for (final item in items) {
      if (item is! Map) continue;
      final type = item['type'];
      final url = item['url'];
      final children = item['children'];

      if (type == 'a' && url is String && url.isNotEmpty) {
        final linkText = children is List ? _richToText(children) : (item['text'] ?? url);
        buf.write('\n👉 $linkText:\n$url\n');
      } else if (children is List) {
        buf.write(_richToText(children));
      } else {
        final t = item['text'];
        if (t is String) buf.write(t);
      }
      if (type == 'p') buf.write('\n');
    }
    return buf.toString();
  }

  static TypebotInputInfo? _parseInput(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return TypebotInputInfo.fromJson(raw);
  }
}
