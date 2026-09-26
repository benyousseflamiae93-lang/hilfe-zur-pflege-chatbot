/// Animated "KI denkt nach…" typing indicator shown while
/// waiting for the Typebot/RAG/translation pipeline.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.label = 'KI denkt nach…',
  });

  final String label;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _bounces;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _bounces = _controllers
        .map((c) => Tween<double>(begin: 0, end: -7)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 60, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar
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
          // Bubble
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                color:
                    isDark ? AppTheme.darkBorder : AppTheme.cardBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _bounces[i],
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounces[i].value),
                        child: child,
                      ),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryBlue.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
