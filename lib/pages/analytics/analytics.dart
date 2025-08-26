import 'package:flutter/material.dart';
import 'package:nice_rice/header.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: const PageHeader(), 
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Analytics overview will appear here.'),
      ),
    );
  }
}
