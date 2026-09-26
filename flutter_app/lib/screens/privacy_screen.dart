import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

/// Privacy / Datenschutz screen explaining data handling.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _items = [
    ('privacy_local_llm', 'privacy_local_llm_desc', Icons.memory_rounded, Color(0xFF1A56DB)),
    ('privacy_rag', 'privacy_rag_desc', Icons.storage_rounded, Color(0xFF8B5CF6)),
    ('privacy_no_ext', 'privacy_no_ext_desc', Icons.block_rounded, Color(0xFFEF4444)),
    ('privacy_gdpr', 'privacy_gdpr_desc', Icons.verified_rounded, Color(0xFF10B981)),
    ('privacy_local', 'privacy_local_desc', Icons.lock_rounded, Color(0xFF0EA5E9)),
  ];

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: const AppDrawer(),
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Hero badge
                    _buildHeroBadge(context, isDark),
                    const SizedBox(height: 20),
                    // Privacy items
                    ..._items.asMap().entries.map(
                      (e) => _PrivacyItem(
                        titleKey: e.value.$1,
                        descKey: e.value.$2,
                        icon: e.value.$3,
                        color: e.value.$4,
                        index: e.key,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Disclaimer note
                    _buildNote(context, isDark),
                  ],
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
          AppStrings.t(context, 'privacy_title'),
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

  Widget _buildHeroBadge(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.shield_rounded, color: AppTheme.primaryBlue, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(context, 'privacy_subtitle'),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNote(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.t(context, 'privacy_note'),
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF92400E), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
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
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, titleKey),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppStrings.t(context, descKey),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
