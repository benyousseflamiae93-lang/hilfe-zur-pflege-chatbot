/// Central configuration for all external service endpoints.
/// Change URLs here if your services run on different ports or hosts.
class AppConfig {
  AppConfig._();

  // ── Typebot ──────────────────────────────────────────────────────────────────
  /// Base URL of your self-hosted Typebot instance.
  static const String typebotBaseUrl = 'http://localhost:8081';

  /// The public bot-ID taken from the viewer URL path.
  static const String typebotBotId = 'chatbot-hilfe-zur-pflege-27nk7p7';

  /// Optional Typebot API key (leave null for public bots).
  static const String? typebotApiKey = null;

  // ── Ollama ───────────────────────────────────────────────────────────────────
  /// Base URL of the local Ollama service.
  static const String ollamaBaseUrl = 'http://localhost:11434';

  /// Ollama model used for translation (llama3, mistral, …).
  static const String ollamaModel = 'mistral';

  // ── Timeouts ─────────────────────────────────────────────────────────────────
  static const Duration typebotTimeout = Duration(seconds: 180);
  static const Duration translationTimeout = Duration(seconds: 180);

  // ── Typebot flow parameters ───────────────────────────────────────────────────
  static const String antragFlow = 'antrag';
  static const String frageFlow = 'frage';
}
