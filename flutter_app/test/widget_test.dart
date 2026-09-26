import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/main.dart';
import 'package:my_app/providers/locale_provider.dart';
import 'package:my_app/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const HilfezurPflegeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title text renders
    expect(find.text('Hilfe zur Pflege'), findsWidgets);
  });
}
