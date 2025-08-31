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
  // Base pill sizing/placement (we'll adapt height at runtime)
  static const double _pillBaseHeight = 64;
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
    final mq = MediaQuery.of(context);
    final cs = Theme.of(context).colorScheme;
    final safeBottom = mq.padding.bottom;

    // Make the pill a bit taller when the user has larger text sizes.
    final textScale = mq.textScaler.scale(1.0); // 1.0..N
    final pillEffectiveHeight =
        _pillBaseHeight + (textScale - 1.0) * 10.0 /* add up to +10px */;

    // Reserve space so content never sits under the floating pill
    final reservedBottomSpace =
        pillEffectiveHeight + _pillBottomGap + safeBottom + 8;

    // Colors for nav icons/labels
    final selectedColor = context.brand;
    final unselectedColor = cs.onSurface.withOpacity(0.60);

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
                  // pass the *effective* height
                  height: pillEffectiveHeight,
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

    final items = <_PillItemData>[
      _PillItemData(icon: Icons.home_rounded, label: 'Home'),
      _PillItemData(icon: Icons.auto_awesome_rounded, label: 'Automation'),
      if (showAnalytics) _PillItemData(icon: Icons.analytics_rounded, label: 'Analytics'),
    ];

    // Cap text scaling inside the pill to avoid overflows on huge sizes.
    final outerScaler = MediaQuery.of(context).textScaler;
    final cappedScaler = TextScaler.linear(
      outerScaler.scale(1.0).clamp(1.0, 1.2),
    );

    // Derive inner metrics from the pill height (robust across devices)
    final iconSize   = height.clamp(52.0, 80.0) * 0.38;              // ~20–30
    final labelBoxH  = (height * 0.28).clamp(12.0, 18.0);            // text box height
    final vGap       = (height * 0.08).clamp(4.0, 8.0);              // space between icon/label
    final innerPadV  = (height * 0.18).clamp(8.0, 12.0);             // vertical padding inside pill
    final innerPadH  = 8.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: cappedScaler),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Blur behind the pill
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: SizedBox(height: height),
              ),
              // Translucent background with subtle border/shadow
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: innerPadH, vertical: innerPadV),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(items.length, (i) {
                      final d = items[i];
                      final selected = i == index;
                      return Expanded(
                        child: _PillTab(
                          data: d,
                          selected: selected,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          onTap: () => onSelect(i),
                          iconSize: iconSize,
                          labelBoxHeight: labelBoxH,
                          vGap: vGap,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.data,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
    required this.iconSize,
    required this.labelBoxHeight,
    required this.vGap,
  });

  final _PillItemData data;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  final double iconSize;
  final double labelBoxHeight;
  final double vGap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    final fontSize = (labelBoxHeight * 0.86).clamp(10.0, 14.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, color: color, size: iconSize),
            SizedBox(height: vGap),
            SizedBox(
              height: labelBoxHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: color,
                    letterSpacing: .1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillItemData {
  final IconData icon;
  final String label;
  const _PillItemData({required this.icon, required this.label});
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.data,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final _PillItemData data;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, color: color, size: 22),
            const SizedBox(height: 6),
            // Keep label from overflowing vertically or horizontally
            SizedBox(
              height: 16, // fixed label box; prevents vertical overflow
              child: FittedBox(
                fit: BoxFit.scaleDown, // scales down on very small screens
                child: Text(
                  data.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.0, // tight, predictable metrics
                    color: color,
                    letterSpacing: .1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
