import 'package:flutter/material.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({super.key});

  @override
  State<PageHeader> createState() => _PageHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PageHeaderState extends State<PageHeader> {
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
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
        right: 12,
        child: CompositedTransformFollower(
          link: _profileLink,
          offset: const Offset(-160, 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 200,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
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
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 40),
          Image.asset('assets/images/2.png', height: 90), // logo
          const SizedBox(width: 8),
          Image.asset('assets/images/3.png', height: 22), // app name
        ],
      ),
      actions: [
        CompositedTransformTarget(
          link: _profileLink,
          child: IconButton(
            tooltip: 'Profile',
            onPressed: _toggleProfilePopup,
            icon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
