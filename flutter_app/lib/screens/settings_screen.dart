import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'about_screen.dart';

/// Settings screen with language selector, dark mode toggle, version info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isRtl = localeProvider.isRtl;
    final isDark = themeProvider.isDark;

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
                delegate: SliverChildListDelegate([
                  _sectionLabel(context, AppStrings.t(context, 'settings_language')),
                  const SizedBox(height: 8),
                  _LanguageTile(),
                  const SizedBox(height: 20),
                  _sectionLabel(context, 'Display'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                    title: AppStrings.t(context, 'settings_dark_mode'),
                    subtitle: AppStrings.t(context, 'settings_dark_mode_desc'),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) => themeProvider.toggle(),
                      activeColor: AppTheme.primaryBlue,
                    ),
                    onTap: () => themeProvider.toggle(),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel(context, AppStrings.t(context, 'settings_version')),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    icon: Icons.info_outline_rounded,
                    color: AppTheme.primaryBlue,
                    title: 'Hilfe zur Pflege',
                    subtitle: 'Version $_version',
                    trailing: const SizedBox.shrink(),
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    icon: Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                    title: AppStrings.t(context, 'settings_about'),
                    subtitle: 'IT-Projekt · Landkreis Hildesheim',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppTheme.textHint),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ]),
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
          AppStrings.t(context, 'settings_title'),
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

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textHint,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─── Language Selector Tile ───────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  final _langs = const [
    ('de', '🇩🇪', 'lang_de'),
    ('en', '🇬🇧', 'lang_en'),
    ('fr', '🇫🇷', 'lang_fr'),
    ('ar', '🇲🇦', 'lang_ar'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = context.watch<LocaleProvider>().locale.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
      ),
      child: Column(
        children: _langs.asMap().entries.map((entry) {
          final i = entry.key;
          final (code, flag, nameKey) = entry.value;
          final isSelected = current == code;
          return Column(
            children: [
              ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  AppStrings.t(context, nameKey),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 22)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: i == 0 ? const Radius.circular(14) : Radius.zero,
                    topRight: i == 0 ? const Radius.circular(14) : Radius.zero,
                    bottomLeft: i == _langs.length - 1 ? const Radius.circular(14) : Radius.zero,
                    bottomRight: i == _langs.length - 1 ? const Radius.circular(14) : Radius.zero,
                  ),
                ),
                onTap: () => context.read<LocaleProvider>().setLocale(Locale(code)),
              ),
              if (i < _langs.length - 1)
                Divider(height: 1, indent: 16, endIndent: 16,
                    color: isDark ? AppTheme.darkBorder : AppTheme.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
