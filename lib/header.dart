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
    this.logoScale = 1.2,
    this.logoPadding = const EdgeInsets.only(left: 16, right: 8),
    this.profileIconSize = 18,
    this.toolbarTopPadding = 30,

    /// Dark mode toggle (provided by caller)
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final double logoScale;
  final EdgeInsets logoPadding;
  final double profileIconSize;
  final double toolbarTopPadding;

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<PageHeader> createState() => _PageHeaderState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + toolbarTopPadding);
}

class _PageHeaderState extends State<PageHeader> {
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

        final topOffset = widget.preferredSize.height + safeTop + 8;

        // Panel constraints
        final panelWidth = screenW - 24; // 12px margin on each side
        final clampedWidth = panelWidth.clamp(220.0, 280.0);
        final availableHeight = screenH - topOffset - 12.0;

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
                  maxHeight: availableHeight > 200 ? availableHeight : 200,
                  minWidth: 220,
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
    final brightness = theme.brightness;

    return AppBar(
      backgroundColor:
          theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: widget.preferredSize.height,
      systemOverlayStyle: (brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
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
                color: context.brand, // brand color adapts to theme
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
                  final signedIn = _user != null;
                  final photo = _user?.photoURL;
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.brand, width: 2),
                      image: signedIn && photo != null
                          ? DecorationImage(
                              image: NetworkImage(photo), fit: BoxFit.cover)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: signedIn && photo != null
                        ? null
                        : Icon(Icons.person,
                            color: context.brand,
                            size: widget.profileIconSize),
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
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/landing', (r) => false);
    }
  }

  void _editPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Edit photo (signed-in only) – TODO: implement picker')),
    );
  }

  void _editName() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Edit name (signed-in only) – TODO: implement form')),
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
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface, // theme-aware panel bg
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
                      final text = snap.data ??
                          (signedIn ? "Hello!" : "Hello, Farmer!");
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

            // Signed-in actions
            if (signedIn) ...[
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.edit, color: cs.onSurface),
                title: Text("Edit name",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface)),
                onTap: _editName,
              ),
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.image_outlined, color: cs.onSurface),
                title: Text("Edit photo",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface)),
                onTap: _editPhoto,
              ),
            ],

            // Guest CTAs (register / sign in)
            if (!signedIn) ...[
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading:
                    Icon(Icons.app_registration, color: cs.onSurface),
                title: Text("Register here",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface)),
                onTap: _goLogin,
              ),
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.login, color: cs.onSurface),
                title: Text("Sign in for free",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface)),
                onTap: _goLogin,
              ),
            ],

            // Dark mode toggle
            SwitchListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8),
              title: Text("Dark mode",
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: cs.onSurface)),
              value: widget.isDarkMode,
              onChanged: (v) {
                if (widget.onThemeChanged != null) {
                  widget.onThemeChanged!(v);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Provide onThemeChanged to apply dark mode')),
                  );
                }
                setState(() {}); // rebuild the switch state
              },
            ),

            Divider(height: 1, color: cs.outline.withOpacity(.4)),

            if (signedIn)
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.logout, color: cs.onSurface),
                title: Text("Log out",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: cs.onSurface)),
                onTap: _logout,
              ),
          ],
        ),
      ),
    );
  }
}
