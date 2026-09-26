import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  // Load persisted preferences before rendering.
  await Future.wait([localeProvider.load(), themeProvider.load()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const HilfezurPflegeApp(),
    ),
  );
}

/// Root application widget for "Hilfe zur Pflege – Landkreis Hildesheim".
class HilfezurPflegeApp extends StatelessWidget {
  const HilfezurPflegeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: 'Hilfe zur Pflege – Landkreis Hildesheim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
