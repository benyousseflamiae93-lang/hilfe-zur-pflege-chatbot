/// Native Flutter chat screen.
///
/// Replaces the old WebView embed with a full-featured chat UI backed by
/// the Typebot REST API.  Ollama handles local translation for non-German
/// users; flutter_tts reads bot answers aloud.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Entry point. Wraps its own [ChatProvider] so each chat session is
/// independent and destroyed when the user navigates back.
class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.title,
    required this.flow,
  });

  /// Label shown in the AppBar (already translated by the caller).
  final String title;

  /// Typebot flow variable value ('antrag' or 'frage').
  final String flow;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: _ChatBody(title: title, flow: flow),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ChatBody extends StatefulWidget {
  const _ChatBody({required this.title, required this.flow});
  final String title;
  final String flow;

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  String get _locale =>
      context.read<LocaleProvider>().locale.languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final provider = context.read<ChatProvider>();
    provider.updateLocale(_locale);
    await provider.initialize(flow: widget.flow, locale: _locale);
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    final provider = context.read<ChatProvider>();
    await provider.sendMessage(text.trim());
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isDark ? AppTheme.darkBackground : const Color(0xFFF0F4FA),
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(child: _buildList(context)),
            _buildInput(context, isDark),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.headerGradient,
          boxShadow: [
            BoxShadow(
              color: Color(0x331A56DB),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () {
                context.read<ChatProvider>().stopSpeaking();
                Navigator.of(context).pop();
              },
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(AppStrings.t(context, 'app_lk'),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75))),
              ],
            ),
            centerTitle: true,
            actions: [
              Consumer<ChatProvider>(
                builder: (_, p, __) => IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 22),
                  tooltip: AppStrings.t(context, 'chat_new_chat'),
                  onPressed: p.isBusy ? null : () => p.reset(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Message list ─────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        if (provider.isInitializing) return _loadingState(context);
        if (provider.hasError) return _errorState(context, provider);

        final msgs = provider.messages;
        final showTyping = provider.isBusy;
        final showChoices = !provider.isBusy &&
            (provider.currentInput?.isChoice ?? false);

        final itemCount =
            msgs.length + (showTyping ? 1 : 0) + (showChoices ? 1 : 0);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: itemCount,
          itemBuilder: (context, i) {
            if (i < msgs.length) {
              final msg = msgs[i];
              return MessageBubble(
                message: msg,
                isCurrentlySpeaking:
                    provider.speakingMessageId == msg.id,
                onListen: () =>
                    provider.toggleSpeak(msg.text, msg.id),
              );
            }
            if (showTyping && i == msgs.length) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());
              return TypingIndicator(label: provider.statusLabel);
            }
            if (showChoices) {
              return _choiceButtons(context, provider);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  // ─── Choice buttons ───────────────────────────────────────────────────────────

  Widget _choiceButtons(BuildContext context, ChatProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(58, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: provider.currentInput!.choices.map((choice) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  _send(choice.content);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    choice.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Input area ───────────────────────────────────────────────────────────────

  Widget _buildInput(BuildContext context, bool isDark) {
    return Consumer<ChatProvider>(
      builder: (_, provider, __) {
        final disabled = provider.isBusy;

        // Hide text input when choice buttons are shown
        if (!disabled && (provider.currentInput?.isChoice ?? false)) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color:
                    isDark ? AppTheme.darkBorder : AppTheme.cardBorder,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text field
                  Expanded(
                    child: Container(
                      constraints:
                          const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCard
                            : const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.cardBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !disabled,
                        maxLines: null,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              AppStrings.t(context, 'chat_placeholder'),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.darkTextHint
                                : AppTheme.textHint,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: disabled ? null : _send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send / loading button
                  _SendButton(
                    isLoading: disabled,
                    onTap: () => _send(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Loading / error states ───────────────────────────────────────────────────

  Widget _loadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppStrings.t(context, 'chat_loading'),
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(AppStrings.t(context, 'chat_loading_sub'),
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, ChatProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.errorRed, size: 32),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.t(context, 'chat_error_title'),
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(AppStrings.t(context, 'chat_error_body'),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(provider.errorMessage,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.textHint),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => provider.reset(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppStrings.t(context, 'chat_retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Send Button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isLoading ? AppTheme.textHint : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.38),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: onTap,
              padding: EdgeInsets.zero,
            ),
    );
  }
}
