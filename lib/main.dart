import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'pages/splash_screen.dart';
import 'providers/recipe_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RecipeApp(),
    ),
  );
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Resep Nusantara',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE8733A),
      brightness: Brightness.light,
      primary: const Color(0xFFE8733A),
      secondary: const Color(0xFF2ECC71),
      tertiary: const Color(0xFFE74C3C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8F6F0),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF8F6F0),
        foregroundColor: const Color(0xFF2C3E50),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2C3E50),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: Colors.grey[500]);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE8733A),
      brightness: Brightness.dark,
      primary: const Color(0xFFFF9A5C),
      secondary: const Color(0xFF4ADE80),
      tertiary: const Color(0xFFF87171),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[400],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: Colors.grey[500]);
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }
}
