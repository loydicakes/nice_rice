import 'dart:ui'; // ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pages
import 'package:nice_rice/pages/homepage/home_page.dart';
import 'package:nice_rice/pages/automation/automation.dart';
import 'package:nice_rice/pages/analytics/analytics.dart';

// Theme helpers
import 'package:nice_rice/theme_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class AppShell extends StatefulWidget {
  /// 0 = Home, 1 = Automation, 2 = Analytics (if signed-in)
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
    _controller = PageController(initialPage: _index);
    _authStream = FirebaseAuth.instance.authStateChanges();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _signedIn => _user != null;

  List<Widget> get _pages => _signedIn
      ? const [HomePage(), AutomationPage(), AnalyticsPage()]
      : const [HomePage(), AutomationPage()];

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
    final cs = Theme.of(context).colorScheme;
    final safeBottom = view.padding.bottom;

    // Reserve space so content never sits under the floating pill
    final reservedBottomSpace = _pillHeight + _pillBottomGap + safeBottom + 8;

    // Colors for nav icons/labels
    final selectedColor = context.brand;
    final unselectedColor = cs.onSurface.withOpacity(0.55);

    return StreamBuilder<User?>(
      stream: _authStream,
      initialData: _user,
      builder: (context, snap) {
        _user = snap.data;

        // Sync PageController if tab count changes due to auth switch
        if (_index >= _pages.length) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _jumpTo(_pages.length - 1));
        } else if (_controller.positions.isNotEmpty &&
            _controller.page != _index.toDouble()) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _jumpTo(_index));
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

              // FLOATING PILL NAV (glass + theme-aware)
              Positioned(
                left: _pillHorizontalMargin,
                right: _pillHorizontalMargin,
                bottom: _pillBottomGap + safeBottom,
                child: _FloatingPillNav(
                  height: _pillHeight,
                  index: _index,
                  onSelect: _onTapTab,
                  showAnalytics: _signedIn,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
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
    required this.selectedColor,
    required this.unselectedColor,
  });

  final double height;
  final int index;
  final bool showAnalytics;
  final ValueChanged<int> onSelect;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_rounded, color: unselectedColor),
        selectedIcon: Icon(Icons.home_rounded, color: selectedColor),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_rounded, color: unselectedColor),
        selectedIcon:
            Icon(Icons.auto_awesome_rounded, color: selectedColor),
        label: 'Automation',
      ),
      if (showAnalytics)
        NavigationDestination(
          icon: Icon(Icons.analytics_rounded, color: unselectedColor),
          selectedIcon:
              Icon(Icons.analytics_rounded, color: selectedColor),
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
            // Theme-aware translucent background + subtle border/shadow
            Container(
              height: height,
              decoration: BoxDecoration(
                color: cs.surfaceVariant, // adapts to dark/light
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withOpacity(0.35)),
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
                  navigationBarTheme: NavigationBarThemeData(
                    height: height,
                    backgroundColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return IconThemeData(color: selectedColor);
                      }
                      return IconThemeData(color: unselectedColor);
                    }),
                    labelTextStyle:
                        MaterialStateProperty.resolveWith((states) {
                      final color = states.contains(MaterialState.selected)
                          ? selectedColor
                          : unselectedColor;
                      return GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      );
                    }),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: Colors.transparent,
                  selectedIndex: index.clamp(0, items.length - 1),
                  onDestinationSelected: onSelect,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
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
