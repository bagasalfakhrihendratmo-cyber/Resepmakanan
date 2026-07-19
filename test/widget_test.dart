// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:makanan/main.dart';
import 'package:makanan/providers/recipe_provider.dart';

void main() {
  testWidgets('renders home screen title', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RecipeProvider(autoLoadFavorites: false),
        child: const RecipeApp(),
      ),
    );

    expect(find.text('Resep Masakan'), findsOneWidget);
  });
}
