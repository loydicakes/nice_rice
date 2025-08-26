// lib/tab.dart
import 'package:flutter/material.dart';

// Your pages
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';

class AppShell extends StatefulWidget {
  /// Which tab to open first (0 = Home, 1 = Automation, 2 = Analytics)
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _pillHeight = 60;
  static const double _pillHorizontalMargin = 16;
  static const double _pillBottomGap = 12; // distance from bottom safe area

  late int _index;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

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
    final view = MediaQuery.of(context);
    final safeBottom = view.padding.bottom; // iOS home indicator / Android insets
    final reservedBottomSpace =
        _pillHeight + _pillBottomGap + safeBottom + 8; // keep pages clear

    return Scaffold(
      // Lets the page content draw under the floating pill (for nice translucency)
      extendBody: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // PAGES — with extra bottom padding so content never sits under the pill
          Padding(
            padding: EdgeInsets.only(bottom: reservedBottomSpace),
            child: PageView(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                HomePage(),
                AutomationPage(),
                AnalyticsPage(),
              ],
            ),
          ),

          // FLOATING PILL NAV
          Positioned(
            left: _pillHorizontalMargin,
            right: _pillHorizontalMargin,
            bottom: _pillBottomGap + safeBottom,
            child: _FloatingPillNav(
              height: _pillHeight,
              index: _index,
              onSelect: _onTapTab,
            ),
          ),
        ],
      ),
      // No bottomNavigationBar — we’re drawing our own floating one above.
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.height,
    required this.index,
    required this.onSelect,
  });

  final double height;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white, // solid pill
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x11000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                spreadRadius: 2,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
              navigationBarTheme: const NavigationBarThemeData(
                height: 60,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                backgroundColor: Colors.transparent,
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: Colors.transparent,
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded,
                      color: Color.fromARGB(50, 0, 0, 0)),
                  selectedIcon: Icon(Icons.home_rounded,
                      color: Color.fromARGB(255, 45, 79, 43)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_rounded,
                      color: Color.fromARGB(50, 0, 0, 0)),
                  selectedIcon: Icon(Icons.auto_awesome_rounded,
                      color: Color.fromARGB(255, 45, 79, 43)),
                  label: 'Automation',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_rounded,
                      color: Color.fromARGB(50, 0, 0, 0)),
                  selectedIcon: Icon(Icons.analytics_rounded,
                      color: Color.fromARGB(255, 45, 79, 43)),
                  label: 'Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
