import 'package:flutter/material.dart';
import '../../main.dart' show signInAnon; // optional: reuse your sign-in

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Home content here'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/details', arguments: 'Home Details'),
            child: const Text('Open Home Details (slides)'),
          ),
          const SizedBox(height: 16),
          // Keep your Firebase test button if you like:
          OutlinedButton(
            onPressed: () async => await signInAnon(),
            child: const Text('Sign in Anonymously'),
          ),
        ],
      ),
    );
  }
}
