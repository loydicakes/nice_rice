// lib/tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// Your pages
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';

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
              child: Theme(
                data: Theme.of(context).copyWith(
                  // Optional: globally nudge density a bit more compact.
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -2,
                  ),
                  navigationBarTheme: NavigationBarThemeData(
                    height: 60, // ↓ tighter bar brings icon/label closer
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return const TextStyle(
                        fontSize: 12,
                        height: 0.82, // ↓ tighter label line-height
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(50, 0, 0, 0),
                      ).copyWith(
                        color: selected
                            ? Color.fromARGB(255, 45, 79, 43)
                            : Color.fromARGB(50, 0, 0, 0),
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(size: selected ? 40 : 39);
                    }),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: Colors.transparent,
                  selectedIndex: _index,
                  onDestinationSelected: _onTapTab,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(
                        Icons.home_rounded,
                        color: Color.fromARGB(50, 0, 0, 0),
                      ),
                      selectedIcon: Icon(
                        Icons.home_rounded,
                        color: Color.fromARGB(255, 45, 79, 43),
                      ),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.auto_awesome_rounded,
                        color: Color.fromARGB(50, 0, 0, 0),
                      ),
                      selectedIcon: Icon(
                        Icons.auto_awesome_rounded,
                        color: Color.fromARGB(255, 45, 79, 43),
                      ),
                      label: 'Automation',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        Icons.analytics_rounded,
                        color: Color.fromARGB(50, 0, 0, 0),
                      ),
                      selectedIcon: Icon(
                        Icons.analytics_rounded,
                        color: Color.fromARGB(255, 45, 79, 43),
                      ),
                      label: 'Analytics',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
