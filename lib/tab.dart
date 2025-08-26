// lib/tab.dart
import 'dart:ui'; // for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your pages
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';

class AppShell extends StatefulWidget {
  /// Which tab to open first (0 = Home, 1 = Automation, 2 = Analytics if available)
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Pill sizing/placement
  static const double _pillHeight = 60;
  static const double _pillHorizontalMargin = 16;
  static const double _pillBottomGap = 12;

  late int _index;
  late PageController _controller;

  // track signed-in state and rebuild UI on change
  late final Stream<User?> _authStream;
  User? _user;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: 0);
    _authStream = FirebaseAuth.instance.authStateChanges();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _signedIn => _user != null;

  /// Current pages and destinations depend on auth state
  List<Widget> get _pages => _signedIn
      ? const [HomePage(), AutomationPage(), AnalyticsPage()]
      : const [HomePage(), AutomationPage()];

  List<NavigationDestination> get _destinations => const [
        NavigationDestination(
          icon: Icon(Icons.home_rounded, color: Color.fromARGB(80, 0, 0, 0)),
          selectedIcon: Icon(Icons.home_rounded, color: Color.fromARGB(255, 45, 79, 43)),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_rounded, color: Color.fromARGB(80, 0, 0, 0)),
          selectedIcon: Icon(Icons.auto_awesome_rounded, color: Color.fromARGB(255, 45, 79, 43)),
          label: 'Automation',
        ),
        // The 3rd destination (Analytics) is only used/shown when signed in (see build)
      ];

  /// Clamp index to available tabs
  int _clampIndex(int i) {
    final max = _pages.length - 1;
    if (i < 0) return 0;
    if (i > max) return max;
    return i;
  }

  void _jumpTo(int i) {
    final target = _clampIndex(i);
    _index = target;
    _controller.jumpToPage(target);
    setState(() {});
  }

  void _onTapTab(int i) {
    final target = _clampIndex(i);
    setState(() => _index = target);
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);
    final safeBottom = view.padding.bottom;

    // Reserve space so content never sits under the floating pill
    final reservedBottomSpace = _pillHeight + _pillBottomGap + safeBottom + 8;

    return StreamBuilder<User?>(
      stream: _authStream,
      initialData: _user,
      builder: (context, snap) {
        _user = snap.data;

        // If state changed (e.g., logout removed Analytics), make sure index is valid.
        if (_index >= _pages.length) {
          // Coerce index and jump without animation to avoid flicker.
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(_pages.length - 1));
        } else if (_controller.positions.isNotEmpty &&
            _controller.page != _index.toDouble()) {
          // Keep PageController in sync when auth state flips.
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(_index));
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFF5F5F5),
          body: Stack(
            children: [
              // PAGES
              Padding(
                padding: EdgeInsets.only(bottom: reservedBottomSpace),
                child: PageView(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: _pages,
                ),
              ),

              // FLOATING PILL NAV (transparent/glassy)
              Positioned(
                left: _pillHorizontalMargin,
                right: _pillHorizontalMargin,
                bottom: _pillBottomGap + safeBottom,
                child: _FloatingPillNav(
                  height: _pillHeight,
                  index: _index,
                  onSelect: _onTapTab,
                  // pass whether Analytics is visible
                  showAnalytics: _signedIn,
                  destinations: _destinations,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.height,
    required this.index,
    required this.onSelect,
    required this.showAnalytics,
    required this.destinations,
  });

  final double height;
  final int index;
  final bool showAnalytics;
  final ValueChanged<int> onSelect;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    // Build destination list conditionally
    final items = <NavigationDestination>[
      destinations[0],
      destinations[1],
      if (showAnalytics)
        const NavigationDestination(
          icon: Icon(Icons.analytics_rounded, color: Color.fromARGB(80, 0, 0, 0)),
          selectedIcon: Icon(Icons.analytics_rounded, color: Color.fromARGB(255, 45, 79, 43)),
          label: 'Analytics',
        ),
    ];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Blur whatever is behind the pill
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(height: height),
            ),
            // Semi-transparent background with a faint border and shadow
            Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    spreadRadius: 1,
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
                  selectedIndex: index.clamp(0, items.length - 1),
                  onDestinationSelected: onSelect,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: items,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
