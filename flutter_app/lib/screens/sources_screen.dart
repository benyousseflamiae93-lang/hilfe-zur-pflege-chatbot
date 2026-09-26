import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

/// Sources / references screen showing official links as tappable cards.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const _sources = [
    ('src1_title', 'src1_desc', 'src1_url', Icons.account_balance_rounded, Color(0xFF1A56DB)),
    ('src2_title', 'src2_desc', 'src2_url', Icons.gavel_rounded, Color(0xFF8B5CF6)),
    ('src3_title', 'src3_desc', 'src3_url', Icons.description_rounded, Color(0xFF0EA5E9)),
    ('src4_title', 'src4_desc', 'src4_url', Icons.health_and_safety_rounded, Color(0xFF10B981)),
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
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _SourceCard(
                    titleKey: _sources[i].$1,
                    descKey: _sources[i].$2,
                    urlKey: _sources[i].$3,
                    icon: _sources[i].$4,
                    color: _sources[i].$5,
                    index: i,
                  ),
                  childCount: _sources.length,
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
          AppStrings.t(context, 'sources_title'),
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

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.titleKey,
    required this.descKey,
    required this.urlKey,
    required this.icon,
    required this.color,
    required this.index,
  });

  final String titleKey;
  final String descKey;
  final String urlKey;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = AppStrings.t(context, urlKey);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 90),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    child: Text(
                      AppStrings.t(context, titleKey),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.t(context, descKey),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              // URL chip
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('URL kopiert: $url'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, color: color, size: 15),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          url,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded, color: color.withOpacity(0.7), size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
