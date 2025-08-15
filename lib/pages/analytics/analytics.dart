import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pushNamed('/details', arguments: 'Analytics Details'),
          child: const Text('Open Analytics Details'),
        ),
      ),
    );
  }
}
