// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Screens you already have
import 'pages/landingpage/landing_page.dart';
import 'pages/login/login.dart';
import 'pages/landingpage/splash_screen.dart';
import 'pages/homepage/home_page.dart';
import 'tab.dart'; // AppShell
import 'header.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp()); // show something instantly
  _init(); // do the heavy work in the background
}

Future<void> _init() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// NOTE: MyApp is unused because you boot BootstrapApp above.
// You can delete MyApp if you want only one MaterialApp.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nice Rice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF5F5F5)),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/landing': (_) => const LandingPage(),
        '/login': (_) => const LoginPage(),

        // Build AppShell with optional initialIndex
        '/main': (ctx) {
          final int? initial = ModalRoute.of(ctx)?.settings.arguments as int?;
          return AppShell(initialIndex: initial ?? 0); // default to Home tab
        },

        // optional: direct route to Home (not used in this flow)
        '/home': (_) => const HomePage(),
      },
    );
  }
}

/// This is the app you actually launch in main().
class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/landing': (_) => const LandingPage(),
        '/login': (_) => const LoginPage(),

        // Build AppShell with optional initialIndex here too
        '/main': (ctx) {
          final int? initial = ModalRoute.of(ctx)?.settings.arguments as int?;
          return AppShell(initialIndex: initial ?? 0);
        },
      },
    );
  }
}

/// Top-level scaffold that hosts the fixed header (like tab.dart hosts tabs).
/// Ensure `AppShell` does NOT set an AppBar to avoid double headers.
class AppWithHeader extends StatelessWidget {
  const AppWithHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(), // <- from pages/header/header.dart
      // If AppShell uses its own Scaffold for bottom nav, that's fine.
      // Just keep AppShell.appBar == null.
      body: const AppShell(),
    );
  }
}
