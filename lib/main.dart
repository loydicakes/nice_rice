// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Your pages
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';
import 'pages/login/login.dart'; 
import 'pages/signup/signup.dart';

// Landing flow
import 'pages/landingpage/splash_screen.dart';
import 'pages/landingpage/landing_page.dart';

import 'dart:ui'; // for ImageFilter

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Keep this available to call from any page
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

      // Start with Splash → then Landing → then AppShell
      initialRoute: '/signup',
      routes: {
        "/splash": (context) => const SplashScreen(),
        "/landing": (context) => const LandingPage(),
        "/home": (context) => const HomePage(),
        '/main': (context) => const AppShell(),
        "/login": (context) => const LoginPage(),
        "/automation": (context) => const LoginPage(),
        "/signup": (context) => const SignUpPage()
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                    selectedIcon: Icon(Icons.home,
                        color: Color.fromARGB(255, 45, 79, 43)),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_motion_outlined),
                    selectedIcon: Icon(Icons.auto_awesome_motion,
                        color: Colors.white),
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

