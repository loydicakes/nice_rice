// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Your pages
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';
import 'pages/login/login.dart'; // <-- add this

import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Optional: keep for your existing HomePage button if desired
Future<void> signInAnon() async {
  final cred = await FirebaseAuth.instance.signInAnonymously();
  debugPrint('Signed in: ${cred.user?.uid}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nice Rice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
      home: const AuthGate(), // <-- use AuthGate now
    );
  }
}

// SWITCHER between Login and AppShell based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          // Signed OUT → show LoginPage
          return const LoginPage();
        }
        // Signed IN → show your tabbed app
        return const AppShell();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapTab(int i) {
    setState(() => _index = i);
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children: const [HomePage(), AutomationPage(), AnalyticsPage()],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white),
              ),
              child: NavigationBar(
                height: 65,
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: Colors.transparent,
                selectedIndex: _index,
                onDestinationSelected: _onTapTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(
                      Icons.home,
                      color: Color.fromARGB(255, 45, 79, 43),
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_motion_outlined),
                    selectedIcon: Icon(
                      Icons.auto_awesome_motion,
                      color: Colors.white,
                    ),
                    label: 'Automation',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics, color: Colors.white),
                    label: 'Analytics',
                  ),
                ],
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
