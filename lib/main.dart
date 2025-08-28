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
import 'package:nice_rice/pages/homepage/home_page.dart';


// Theme controller
import 'theme_controller.dart';

final ThemeController _theme = ThemeController();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ThemeScope(
      controller: _theme,
      child: const BootstrapApp(),
    ),
  );
  _init();
}

Future<void> _init() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          // Page transitions belong in ThemeData (already set in AppThemes)
          home: const SplashScreen(),
          routes: {
            '/landing': (_) => const LandingPage(),
            '/login': (_) => const LoginPage(),
            '/main': (ctx) {
              final int? initial = ModalRoute.of(ctx)?.settings.arguments as int?;
              return AppShell(initialIndex: initial ?? 0);
            },
            // optional direct route
            '/home': (_) => HomePage(),
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
