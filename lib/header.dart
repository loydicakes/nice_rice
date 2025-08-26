// lib/header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ Auth & profile data
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({
    super.key,
    this.logoScale = 1.2,
    this.logoPadding = const EdgeInsets.only(left: 16, right: 8),
    this.profileIconSize = 18,
    this.toolbarTopPadding = 30,

    /// Optional theming hooks (safe defaults)
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final double logoScale;
  final EdgeInsets logoPadding;
  final double profileIconSize;
  final double toolbarTopPadding;

  /// Optional (for the Dark mode toggle)
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<PageHeader> createState() => _PageHeaderState();

  /// Dynamically adjust header height with the top padding
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + toolbarTopPadding);
}

class _PageHeaderState extends State<PageHeader> {
  static const bgGrey = Color(0xFFF5F5F5);
  static const darkGreen = Color(0xFF2F6F4F);

  final LayerLink _profileLink = LayerLink();
  OverlayEntry? _profilePopup;

  // ------- Helpers: user + name fetch -------
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<String?> _fetchFirstName() async {
    final u = _user;
    if (u == null) return null;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = doc.data();
      final first = (data?['firstName'] as String?)?.trim();
      if (first != null && first.isNotEmpty) return first;
      // fallbacks
      if (u.displayName != null && u.displayName!.trim().isNotEmpty) {
        return u.displayName!.split(' ').first;
      }
      if (u.email != null && u.email!.contains('@')) {
        return u.email!.split('@').first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _openProfilePopup() {
  if (_profilePopup != null) return;
  final overlay = Overlay.of(context);

  _profilePopup = OverlayEntry(
    builder: (_) {
      final mq = MediaQuery.of(context);
      final safeTop = mq.padding.top;
      final screenW = mq.size.width;
      final screenH = mq.size.height;

      // Space below the header where we can show the panel
      final topOffset = widget.preferredSize.height + safeTop + 8;

      // Panel constraints
      final panelWidth = screenW - 24;          // 12px margin on each side
      final clampedWidth = panelWidth.clamp(220.0, 280.0);
      final availableHeight = screenH - topOffset - 12.0; // keep 12px bottom gap

      return Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleProfilePopup,
              behavior: HitTestBehavior.opaque,
            ),
          ),

          // Panel anchored to top-right, width/height constrained
          Positioned(
            right: 12,
            top: topOffset,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: clampedWidth,
                // Height is limited to available space; inner content scrolls if needed
                maxHeight: availableHeight > 200 ? availableHeight : 200,
                minWidth: 220,
                minHeight: 0,
              ),
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: _ProfilePanel(
                  onClose: _toggleProfilePopup,
                  isDarkMode: widget.isDarkMode,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(_profilePopup!);
}

  void _closeProfilePopup() {
    _profilePopup?.remove();
    _profilePopup = null;
  }

  void _toggleProfilePopup() {
    if (_profilePopup == null) {
      _openProfilePopup();
    } else {
      _closeProfilePopup();
    }
  }

  @override
  void dispose() {
    _closeProfilePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: bgGrey,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: widget.preferredSize.height,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: bgGrey,
      ),
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(top: widget.toolbarTopPadding),
        child: Row(
          children: [
            Padding(
              padding: widget.logoPadding,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Transform.scale(
                  scale: widget.logoScale,
                  child: Image.asset(
                    'assets/images/2.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Text(
              'NiceRice',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
              top: widget.toolbarTopPadding,
            ),
            child: InkWell(
              onTap: _toggleProfilePopup,
              borderRadius: BorderRadius.circular(24),
              child: FutureBuilder<String?>(
                future: _fetchFirstName(),
                builder: (context, snap) {
                  // Show user photo if signed-in, else generic icon
                  final signedIn = _user != null;
                  final photo = _user?.photoURL;
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkGreen, width: 2),
                      image: signedIn && photo != null
                          ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: signedIn && photo != null
                        ? null
                        : Icon(Icons.person, color: darkGreen, size: widget.profileIconSize),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============ PROFILE PANEL ============

class _ProfilePanel extends StatefulWidget {
  const _ProfilePanel({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onClose,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;
  final VoidCallback onClose;

  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  static const bgGrey = Color(0xFFF5F5F5);
  static const darkGreen = Color(0xFF2F6F4F);

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<String> _displayName() async {
    final u = _user;
    if (u == null) return "Hello, Farmer!";
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = doc.data();
      final first = (data?['firstName'] as String?)?.trim();
      if (first != null && first.isNotEmpty) return "Hello, $first!";
      if (u.displayName != null && u.displayName!.trim().isNotEmpty) {
        return "Hello, ${u.displayName!.split(' ').first}!";
      }
      if (u.email != null && u.email!.contains('@')) {
        return "Hello, ${u.email!.split('@').first}!";
      }
      return "Hello!";
    } catch (_) {
      return "Hello!";
    }
  }

  void _goLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
    widget.onClose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // After logout, send back to landing
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/landing', (r) => false);
    }
  }

  // Stubs for edit actions (only for signed-in)
  void _editPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit photo (signed-in only) – TODO: implement picker')),
    );
  }

  void _editName() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit name (signed-in only) – TODO: implement form')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _user != null;
    final photo = _user?.photoURL;

    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgGrey,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: avatar + name
            Row(
              children: [
                GestureDetector(
                  onTap: signedIn ? _editPhoto : null,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: signedIn && photo != null
                          ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: darkGreen, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: signedIn && photo != null
                        ? null
                        : Icon(Icons.person, color: darkGreen, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _displayName(),
                    builder: (context, snap) {
                      final text = snap.data ?? (signedIn ? "Hello!" : "Hello, Farmer!");
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: darkGreen,
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20, color: Colors.black87),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Signed-in actions
            if (signedIn) ...[
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: Text("Edit name", style: GoogleFonts.poppins(fontSize: 13)),
                onTap: _editName,
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.image_outlined, color: Colors.black87),
                title: Text("Edit photo", style: GoogleFonts.poppins(fontSize: 13)),
                onTap: _editPhoto,
              ),
            ],

            // Guest CTAs (register / sign in)
            if (!signedIn) ...[
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.app_registration, color: Colors.black87),
                title: Text("Register here", style: GoogleFonts.poppins(fontSize: 13)),
                onTap: _goLogin,
              ),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.login, color: Colors.black87),
                title: Text("Sign in for free", style: GoogleFonts.poppins(fontSize: 13)),
                onTap: _goLogin,
              ),
            ],

            // Dark mode toggle (works if you pass onThemeChanged)
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("Dark mode", style: GoogleFonts.poppins(fontSize: 13)),
              value: widget.isDarkMode,
              onChanged: (v) {
                if (widget.onThemeChanged != null) {
                  widget.onThemeChanged!(v);
                } else {
                  // Safe fallback if not wired yet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Provide onThemeChanged to apply dark mode')),
                  );
                }
                setState(() {}); // just to rebuild the switch immediately
              },
            ),

            const Divider(height: 1),

            // Logout (only if signed-in)
            if (signedIn)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: Text("Log out", style: GoogleFonts.poppins(fontSize: 13)),
                onTap: _logout,
              ),
          ],
        ),
      ),
    );
  }
}
