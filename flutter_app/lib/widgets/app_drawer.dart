import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../screens/home_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/sources_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/chat_screen.dart';


/// Beautiful side navigation drawer with icons and section grouping.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Drawer(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkSurface
            : Colors.white,
        child: Column(
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    labelKey: 'nav_home',
                    onTap: () => _navigateTo(context, const HomeScreen()),
                  ),
                  const SizedBox(height: 4),
                  _SectionLabel('Chatbot'),
                  _DrawerItem(
                    icon: Icons.assignment_rounded,
                    labelKey: 'nav_antrag',
                    color: AppTheme.primaryBlue,
                    onTap: () {
                      final title = AppStrings.t(context, 'nav_antrag');
                      _navigateTo(
                        context,
                        ChatScreen(
                          title: title,
                          flow: AppConfig.antragFlow,
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_rounded,
                    labelKey: 'nav_frage',
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      final title = AppStrings.t(context, 'nav_frage');
                      _navigateTo(
                        context,
                        ChatScreen(
                          title: title,
                          flow: AppConfig.frageFlow,
                        ),
                      );
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 24),
                  _SectionLabel('Information'),
                  _DrawerItem(
                    icon: Icons.folder_copy_rounded,
                    labelKey: 'nav_documents',
                    onTap: () => _navigateTo(context, const DocumentsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.help_rounded,
                    labelKey: 'nav_faq',
                    onTap: () => _navigateTo(context, const FaqScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.library_books_rounded,
                    labelKey: 'nav_sources',
                    onTap: () => _navigateTo(context, const SourcesScreen()),
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 24),
                  _SectionLabel('App'),
                  _DrawerItem(
                    icon: Icons.lock_rounded,
                    labelKey: 'nav_privacy',
                    onTap: () => _navigateTo(context, const PrivacyScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    labelKey: 'nav_settings',
                    onTap: () => _navigateTo(context, const SettingsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_rounded,
                    labelKey: 'nav_about',
                    onTap: () => _navigateTo(context, const AboutScreen()),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
}

// ─── Drawer Header ───────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.t(context, 'app_title'),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.t(context, 'app_lk'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = color ?? AppTheme.primaryBlue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: itemColor, size: 20),
        ),
        title: Text(
          AppStrings.t(context, labelKey),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        dense: true,
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
      ),
    );
  }
}
