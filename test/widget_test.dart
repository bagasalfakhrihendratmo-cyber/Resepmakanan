// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:makanan/main.dart';
import 'package:makanan/providers/recipe_provider.dart';
import 'package:makanan/providers/theme_provider.dart';

void main() {
  testWidgets('renders home screen title', (tester) async {
    // Mock SharedPreferences so ThemeProvider can load the theme without
    // hitting the platform channel (MissingPluginException in tests).
    SharedPreferences.setMockInitialValues({});

    // RecipeApp.build reads both ThemeProvider and RecipeProvider via
    // context.watch, so both providers must be above it (same as main.dart).
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => RecipeProvider(autoLoadFavorites: false),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const RecipeApp(),
      ),
    );

    // Let the splash screen's delayed timers fire (entrance at 400ms &
    // 900ms, skip-button at 2000ms) so none are left pending when the
    // test ends.
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('Resep Nusantara'), findsOneWidget);
  });

  testWidgets('skip button navigates to main screen before 10s',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Widen the viewport: tests use the Ahem font whose glyphs are much
    // wider than real fonts, so MainScreen's header overflows the default
    // 800x600 test surface.
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => RecipeProvider(autoLoadFavorites: false),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const RecipeApp(),
      ),
    );

    // Fire entrance (400/900ms) + skip-button (2000ms) timers.
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('Lewati'), findsOneWidget);

    // Tap skip → exit animation starts immediately (no 10s wait).
    await tester.tap(find.text('Lewati'));
    await tester.pump(); // start exit
    await tester.pump(const Duration(milliseconds: 100)); // 80ms delay
    await tester.pump(const Duration(milliseconds: 800)); // route transition

    // Splash is gone; MainScreen is now visible. ('Cari Resep Favoritmu'
    // is the search tab's empty-state title — unique to MainScreen, while
    // 'Cari Resep' also appears on the favorites empty-state button.)
    expect(find.text('Lewati'), findsNothing);
    expect(find.text('Cari Resep Favoritmu'), findsOneWidget);

    // Fire MainScreen's 5s onboarding timer so no timers are pending.
    await tester.pump(const Duration(seconds: 6));
  });
}
