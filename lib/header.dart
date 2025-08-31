import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Auth & profile
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme helpers (context.brand, etc.)
import 'package:nice_rice/theme_controller.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({
    super.key,
    this.logoScale = 1.0,
    this.logoPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.profileIconSize = 18,
    this.toolbarTopPadding = 0, // kept for backward compat (ignored)
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final double logoScale;
  final EdgeInsets logoPadding;
  final double profileIconSize;
  final double toolbarTopPadding; // ignored now (SafeArea used)

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<PageHeader> createState() => _PageHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PageHeaderState extends State<PageHeader> {
  final LayerLink _profileLink = LayerLink();
  OverlayEntry? _profilePopup;

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
      if ((u.displayName ?? '').trim().isNotEmpty) {
        return u.displayName!.split(' ').first;
      }
      final email = u.email;
      if (email != null && email.contains('@')) {
        return email.split('@').first;
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
        final screenW = mq.size.width;

        final maxPanelW = screenW - 24; // side gutters
        final clampedW = maxPanelW.clamp(240.0, 320.0);

        return Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleProfilePopup,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            // Anchor to profile icon (top-right of it)
            CompositedTransformFollower(
              link: _profileLink,
              showWhenUnlinked: false,
              offset: const Offset(-8, 48), // x: nudge left, y: below icon
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: clampedW,
                  // let height adapt to content but avoid overflows
                  maxHeight: mq.size.height * 0.8,
                  minWidth: 240,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final w = MediaQuery.of(context).size.width;
    final logoBox = w.clamp(320.0, 480.0) == w ? 38.0 : 42.0; // gentle scale
    final avatarSize = w < 360 ? 32.0 : 36.0;

    return AppBar(
      backgroundColor:
          theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: kToolbarHeight,
      systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      ),
      titleSpacing: 0,
      title: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Padding(
                padding: widget.logoPadding,
                child: SizedBox(
                  width: logoBox,
                  height: logoBox,
                  child: Transform.scale(
                    scale: widget.logoScale,
                    child: Image.asset(
                      'assets/images/2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Title that never overflows
              Expanded(
                child: Text(
                  'NiceRice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.brand,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        SafeArea(
          bottom: false,
          child: CompositedTransformTarget(
            link: _profileLink,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: _toggleProfilePopup,
                borderRadius: BorderRadius.circular(24),
                child: FutureBuilder<String?>(
                  future: _fetchFirstName(),
                  builder: (context, snap) {
                    final signedIn = _user != null;
                    final photo = _user?.photoURL;
                    return Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.brand, width: 2),
                        image: signedIn && photo != null
                            ? DecorationImage(
                                image: NetworkImage(photo), fit: BoxFit.cover)
                            : null,
                        color: theme.cardColor,
                      ),
                      alignment: Alignment.center,
                      child: signedIn && photo != null
                          ? null
                          : Icon(Icons.person,
                              color: context.brand,
                              size: widget.profileIconSize.clamp(16, 20)),
                    );
                  },
                ),
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
      if ((u.displayName ?? '').trim().isNotEmpty) {
        return "Hello, ${u.displayName!.split(' ').first}!";
      }
      final email = u.email;
      if (email != null && email.contains('@')) {
        return "Hello, ${email.split('@').first}!";
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
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/landing', (r) => false);
    }
  }

  void _editPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit photo – TODO')),
    );
  }

  void _editName() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit name – TODO')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final signedIn = _user != null;
    final photo = _user?.photoURL;

    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
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
                      color: theme.cardColor,
                      image: signedIn && photo != null
                          ? DecorationImage(
                              image: NetworkImage(photo), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: context.brand, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: signedIn && photo != null
                        ? null
                        : Icon(Icons.person, color: context.brand, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _displayName(),
                    builder: (context, snap) {
                      final text =
                          snap.data ?? (signedIn ? "Hello!" : "Hello, Farmer!");
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.brand,
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, size: 20, color: cs.onSurface),
                  tooltip: 'Close',
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outline.withOpacity(.4)),

            if (signedIn) ...[
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.edit, color: cs.onSurface),
                title: Text("Edit name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
                onTap: _editName,
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.image_outlined, color: cs.onSurface),
                title: Text("Edit photo",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
                onTap: _editPhoto,
              ),
            ],

            if (!signedIn) ...[
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.app_registration, color: cs.onSurface),
                title: Text("Register here",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
                onTap: _goLogin,
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.login, color: cs.onSurface),
                title: Text("Sign in for free",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
                onTap: _goLogin,
              ),
            ],

            SwitchListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("Dark mode",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
              value: widget.isDarkMode,
              onChanged: (v) {
                widget.onThemeChanged?.call(v);
                setState(() {});
              },
            ),

            Divider(height: 1, color: cs.outline.withOpacity(.4)),

            if (signedIn)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.logout, color: cs.onSurface),
                title: Text("Log out",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurface)),
                onTap: _logout,
              ),
          ],
        ),
      ),
    );
  }
}
