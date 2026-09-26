/// Chat message bubble widget.
///
/// • User messages → right-aligned gradient bubble
/// • Bot messages  → left-aligned white/dark card with avatar,
///                   timestamp, Copy button, and Listen/Stop button
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentlySpeaking,
    required this.onListen,
  });

  final ChatMessage message;
  final bool isCurrentlySpeaking;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) => message.isUser
      ? _UserBubble(message: message)
      : _BotBubble(
          message: message,
          isCurrentlySpeaking: isCurrentlySpeaking,
          onListen: onListen,
        );
}

// ── User bubble ───────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: Colors.white,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(message.timestamp),
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}

// ── Bot bubble ────────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  const _BotBubble({
    required this.message,
    required this.isCurrentlySpeaking,
    required this.onListen,
  });
  final ChatMessage message;
  final bool isCurrentlySpeaking;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final links = _extractLinks(message.text);
    final displayText = _cleanDisplayMessage(message.text);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 64, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          height: 1.65,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      // Interactive Action Buttons for Download / Links
                      for (final link in links) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openUrl(context, link.url),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E3A8A).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      link.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new_rounded,
                                      color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Action row
                Row(
                  children: [
                    Text(
                      _fmt(message.timestamp),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                    const Spacer(),
                    _Chip(
                      icon: Icons.copy_rounded,
                      label: 'Kopieren',
                      onTap: () => _copy(context),
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      icon: isCurrentlySpeaking
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      label: isCurrentlySpeaking ? 'Stopp' : 'Anhören',
                      color: isCurrentlySpeaking
                          ? AppTheme.errorRed
                          : AppTheme.primaryBlue,
                      onTap: onListen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kopiert!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        await Process.run('open', [url]);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link in Zwischenablage kopiert!')),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link kopiert: $url')),
        );
      }
    }
  }
}

// ── Link Extractor Helpers ────────────────────────────────────────────────────

class _ExtractedLink {
  const _ExtractedLink({required this.title, required this.url});
  final String title;
  final String url;
}

List<_ExtractedLink> _extractLinks(String text) {
  final links = <_ExtractedLink>[];
  
  // 1. Markdown link pattern [Title](URL)
  final mdRegex = RegExp(r'\[([^\]]+)\]\((https?://[^\s\)]+)\)');
  for (final match in mdRegex.allMatches(text)) {
    final title = match.group(1) ?? 'Link öffnen';
    final url = match.group(2) ?? '';
    if (url.isNotEmpty) {
      links.add(_ExtractedLink(title: title, url: url));
    }
  }

  // 2. Direct HTTP/HTTPS URLs (if not already matched via Markdown)
  if (links.isEmpty) {
    final urlRegex = RegExp(r'https?://[^\s\)]+');
    for (final match in urlRegex.allMatches(text)) {
      final url = match.group(0) ?? '';
      if (url.isNotEmpty) {
        String title = 'Antrag herunterladen (PDF)';
        if (url.contains('download_pdf')) {
          title = 'Ausgefüllten Antrag herunterladen (PDF)';
        }
        links.add(_ExtractedLink(title: title, url: url));
      }
    }
  }
  return links;
}

String _cleanDisplayMessage(String text) {
  return text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\((https?://[^\s\)]+)\)'),
    (match) => match.group(1) ?? '',
  ).trim();
}

// ── Micro-chip button ─────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textHint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
