// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Screens
import 'pages/landingpage/landing_page.dart';
import 'pages/login/login.dart';
import 'pages/landingpage/splash_screen.dart';
import 'tab.dart'; // AppShell
import 'header.dart';
import 'pages/homepage/home_page.dart';

// Theme controller
import 'theme_controller.dart';

final ThemeController _theme = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase BEFORE runApp so SplashScreen can use it safely.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ThemeScope(controller: _theme, child: const BootstrapApp()));
}

/// Single app entry that owns MaterialApp + theming.
class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.light(),
          darkTheme: AppThemes.dark(),
          themeMode: theme.mode,
          // ✅ SplashScreen is now the first screen again.
          home: const SplashScreen(),
          routes: {
            '/landing': (_) => const LandingPage(),
            '/login': (_) => const LoginPage(),
            '/main': (ctx) {
              final int? initial =
                  ModalRoute.of(ctx)?.settings.arguments as int?;
              return AppShell(initialIndex: initial ?? 0);
            },
            '/home': (_) => const HomePage(),
          },
        );
      },
    );
  }
}

/// Optional scaffold that always includes the header.
/// Ensure AppShell doesn’t add its own AppBar to avoid duplicates.
class AppWithHeader extends StatelessWidget {
  const AppWithHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      appBar: PageHeader(
        isDarkMode: theme.isDark,
        onThemeChanged: theme.setDark,
      ),
      body: const AppShell(),
    );
  }
}
