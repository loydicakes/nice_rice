// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
import 'pages/login/login.dart'; // Google/Firebase sign-in screen
import 'tab.dart';               // AppShell (the tabbed UI)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Keep this available to call from any page if you still want quick anon auth
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
      // Auth-aware entry point: shows Login when signed out, AppShell when signed in
      home: const AuthGate(),
      // If you still need named routes (e.g., deep links), add them here.
      // routes: {
      //   '/login': (_) => const LoginPage(),
      //   '/main':  (_) => const AppShell(),
      // },
    );
  }
}

/// Switches between Login and the tabbed app based on auth state.
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
          // Signed OUT → show Google/Firebase login
          return const LoginPage();
        }

        // Signed IN → show your tabbed app from tab.dart
        return const AppShell();
      },
    );
  }
}
