import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

Future<void> signInAnon() async {
  final cred = await FirebaseAuth.instance.signInAnonymously();
  debugPrint('Signed in: ${cred.user?.uid}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Auth Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await signInAnon();
            },
            child: const Text('Sign in Anonymously'),
          ),
        ),
      ),
    );
  }
}
