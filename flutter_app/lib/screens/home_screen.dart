import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../widgets/action_card.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';


/// The main home screen of the Hilfe zur Pflege application.
/// Displays the app identity (logo, title, subtitle) and two action buttons.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  /// Navigate to chat screen with a smooth slide-up transition.
  /// [title] is shown in the AppBar. [flow] is sent to Typebot as a variable.
  void _openChat(BuildContext context, String title, String flow) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          title: title,
          flow: flow,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.watch<LocaleProvider>().isRtl;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const AppDrawer(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x441A56DB),
                blurRadius: 30,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Top row: hamburger + language ──────────────────────
                  Row(
                    children: [
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _LanguageButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Logo ───────────────────────────────────────────────────
                  ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogo(),
                  ),
                  const SizedBox(height: 20),
                  // ── Title ────────────────────────────────────────────────────
                  Text(
                    AppStrings.t(context, 'app_title'),
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.t(context, 'app_lk'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Subtitle ────────────────────────────────────────────────
                  Text(
                    AppStrings.t(context, 'app_subtitle'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.78),
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ────────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring decoration
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
          // Main icon
          const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 36,
          ),
        ],
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Was möchten Sie tun?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // ── Action Buttons ─────────────────────────────────────────────
          ActionCard(
            icon: Icons.assignment_rounded,
            title: AppStrings.t(context, 'nav_antrag'),
            subtitle: AppStrings.t(context, 'home_antrag_subtitle'),
            iconBackgroundColor: AppTheme.primaryBlue,
            delay: const Duration(milliseconds: 200),
            onTap: () => _openChat(
              context,
              AppStrings.t(context, 'nav_antrag'),
              AppConfig.antragFlow,
            ),
          ),
          const SizedBox(height: 14),
          ActionCard(
            icon: Icons.chat_bubble_rounded,
            title: AppStrings.t(context, 'nav_frage'),
            subtitle: AppStrings.t(context, 'home_frage_subtitle'),
            iconBackgroundColor: const Color(0xFF0EA5E9),
            delay: const Duration(milliseconds: 340),
            onTap: () => _openChat(
              context,
              AppStrings.t(context, 'nav_frage'),
              AppConfig.frageFlow,
            ),
          ),

          const SizedBox(height: 32),

          // ── Info Banner ────────────────────────────────────────────────
          _buildInfoBanner(),

          const SizedBox(height: 28),

          // ── Footer ────────────────────────────────────────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── Info Banner ─────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dieser KI-Assistent unterstützt Sie bei Fragen zur Pflegehilfe des Landkreises Hildesheim.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Builder(
      builder: (context) => Column(
        children: [
          const Divider(),
          const SizedBox(height: 14),
          Text(
            AppStrings.t(context, 'home_footer_1'),
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.t(context, 'home_footer_2'),
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Language Globe Button ─────────────────────────────────────────────────────
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  static const _flags = {'de': '🇩🇪', 'en': '🇬🇧', 'fr': '🇫🇷', 'ar': '🇲🇦'};
  static const _langs = [
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
    ('fr', '🇫🇷', 'Français'),
    ('ar', '🇲🇦', 'عربي'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final flag = _flags[provider.locale.languageCode] ?? '🌐';
    return GestureDetector(
      onTap: () => _showPicker(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, LocaleProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.t(context, 'select_language'),
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ..._langs.map((l) => ListTile(
              leading: Text(l.$2, style: const TextStyle(fontSize: 24)),
              title: Text(l.$3, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: provider.locale.languageCode == l.$1
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                provider.setLocale(Locale(l.$1));
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }
}
