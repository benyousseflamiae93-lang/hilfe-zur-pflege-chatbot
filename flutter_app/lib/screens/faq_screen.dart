import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

/// FAQ screen with animated ExpansionTiles.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;
    final faqs = [
      ('faq_q1', 'faq_a1'),
      ('faq_q2', 'faq_a2'),
      ('faq_q3', 'faq_a3'),
      ('faq_q4', 'faq_a4'),
      ('faq_q5', 'faq_a5'),
      ('faq_q6', 'faq_a6'),
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: const AppDrawer(),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _FaqItem(
                    question: AppStrings.t(context, faqs[i].$1),
                    answer: AppStrings.t(context, faqs[i].$2),
                    index: i,
                  ),
                  childCount: faqs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
        title: Text(
          AppStrings.t(context, 'faq_title'),
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.fromLTRB(60, 0, 20, 16),
      ),
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer, required this.index});
  final String question;
  final String answer;
  final int index;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + widget.index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppTheme.primaryBlue.withOpacity(0.4)
                : (isDark ? AppTheme.darkBorder : AppTheme.cardBorder),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(_expanded ? 0.08 : 0.04),
              blurRadius: _expanded ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            title: Text(
              widget.question,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            iconColor: AppTheme.primaryBlue,
            collapsedIconColor: AppTheme.textHint,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            children: [
              Text(
                widget.answer,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.7,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
