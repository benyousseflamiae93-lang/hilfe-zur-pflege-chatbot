import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

/// About screen — app description, technology stack, contact info.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _techs = [
    ('Flutter 3.x', Icons.phone_android_rounded, Color(0xFF06B6D4)),
    ('Typebot', Icons.chat_bubble_rounded, Color(0xFF8B5CF6)),
    ('RAG-Architektur', Icons.storage_rounded, Color(0xFF10B981)),
    ('Lokales LLM', Icons.memory_rounded, Color(0xFF1A56DB)),
    ('Python Backend', Icons.code_rounded, Color(0xFFF59E0B)),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // App logo card
                    _buildLogoCard(isDark),
                    const SizedBox(height: 24),
                    // Description
                    _buildDescription(context, isDark),
                    const SizedBox(height: 24),
                    // Tech stack
                    _buildTechSection(context, isDark),
                    const SizedBox(height: 24),
                    // Contact
                    _buildContact(context, isDark),
                    const SizedBox(height: 32),
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
          AppStrings.t(context, 'about_title'),
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

  Widget _buildLogoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF0F3D9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Hilfe zur Pflege',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 4),
          Text(
            'Landkreis Hildesheim',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
      ),
      child: Text(
        AppStrings.t(context, 'about_desc'),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          height: 1.7,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTechSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppStrings.t(context, 'about_tech_title').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textHint,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _techs.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: t.$3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.$3.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.$2, color: t.$3, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    t.$1,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.$3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContact(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.t(context, 'about_contact').toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textHint,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_city_rounded, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.t(context, 'app_lk'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.t(context, 'about_dept'),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
