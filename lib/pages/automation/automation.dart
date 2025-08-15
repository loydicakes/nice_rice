import 'package:flutter/material.dart';

class AutomationPage extends StatelessWidget {
  const AutomationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pushNamed('/details', arguments: 'Automation Details'),
          child: const Text('Open Automation Details'),
        ),
      ),
    );
  }
}
