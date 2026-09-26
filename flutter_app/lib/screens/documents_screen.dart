import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

/// Required documents screen showing each document as a beautiful card.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _docs = [
    ('doc1_title', 'doc1_desc', Icons.badge_rounded, Color(0xFF1A56DB)),
    ('doc2_title', 'doc2_desc', Icons.medical_information_rounded, Color(0xFF0EA5E9)),
    ('doc3_title', 'doc3_desc', Icons.home_rounded, Color(0xFF8B5CF6)),
    ('doc4_title', 'doc4_desc', Icons.attach_money_rounded, Color(0xFF10B981)),
    ('doc5_title', 'doc5_desc', Icons.account_balance_rounded, Color(0xFFF59E0B)),
    ('doc6_title', 'doc6_desc', Icons.health_and_safety_rounded, Color(0xFFEF4444)),
    ('doc7_title', 'doc7_desc', Icons.description_rounded, Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: const AppDrawer(),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _buildInfoBanner(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _DocumentCard(
                    titleKey: _docs[i].$1,
                    descKey: _docs[i].$2,
                    icon: _docs[i].$3,
                    color: _docs[i].$4,
                    index: i,
                  ),
                  childCount: _docs.length,
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
          AppStrings.t(context, 'docs_title'),
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

  Widget _buildInfoBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.t(context, 'docs_subtitle'),
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.color,
    required this.index,
  });

  final String titleKey;
  final String descKey;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, titleKey),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppStrings.t(context, descKey),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_rounded, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
