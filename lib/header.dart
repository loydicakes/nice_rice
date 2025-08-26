// lib/header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({
    super.key,
    this.logoScale = 1.2,                            // zoom level for the logo
    this.logoPadding = const EdgeInsets.only(left: 16, right: 8),
    this.profileIconSize = 18,                       // inner person icon size
    this.toolbarTopPadding = 12,                     // ❗ extra space above content
  });

  final double logoScale;
  final EdgeInsets logoPadding;
  final double profileIconSize;
  final double toolbarTopPadding;

  @override
  State<PageHeader> createState() => _PageHeaderState();

  // Keep the default height so the bottom edge doesn't move
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PageHeaderState extends State<PageHeader> {
  static const bgGrey = Color(0xFFF5F5F5);
  static const darkGreen = Color(0xFF2F6F4F);

  final LayerLink _profileLink = LayerLink();
  OverlayEntry? _profilePopup;

  void _toggleProfilePopup() {
    if (_profilePopup != null) {
      _profilePopup!.remove();
      _profilePopup = null;
      return;
    }
    final overlay = Overlay.of(context);
    _profilePopup = OverlayEntry(
      builder: (_) => Positioned(
        // position under the AppBar + status bar; no extra top padding here
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
        right: 12,
        child: CompositedTransformFollower(
          link: _profileLink,
          offset: const Offset(-160, 8),
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 200,
              height: 160,
              decoration: BoxDecoration(
                color: bgGrey, // solid #F5F5F5
                borderRadius: BorderRadius.circular(16),
              ),
              // Add profile content later
            ),
          ),
        ),
      ),
    );
    overlay.insert(_profilePopup!);
  }

  @override
  void dispose() {
    _profilePopup?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: bgGrey,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // keep default height so bottom edge doesn't shift
      toolbarHeight: kToolbarHeight,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: bgGrey,
      ),
      titleSpacing: 0,
      title: Padding(
        // 👉 this creates space above the content without changing the bar height
        padding: EdgeInsets.only(top: widget.toolbarTopPadding),
        child: Row(
          children: [
            // Logo container with adjustable padding + zoom
            Padding(
              padding: widget.logoPadding,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Transform.scale(
                  scale: widget.logoScale,
                  child: Image.asset(
                    'assets/images/2.png', // your NR logo
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              'NiceRice',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700, // bold
                color: darkGreen,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
      actions: [
        CompositedTransformTarget(
          link: _profileLink,
          child: Padding(
            padding: EdgeInsets.only(
              right: 12,
              top: widget.toolbarTopPadding, // keep visual alignment with title
            ),
            child: InkWell(
              onTap: _toggleProfilePopup,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 36, // slightly smaller circle
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: darkGreen, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person,
                  color: darkGreen,
                  size: widget.profileIconSize, // smaller inner icon
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
