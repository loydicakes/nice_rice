import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Your top-level pages (match your folders under lib/pages/)
import 'pages/homepage/home_page.dart';
import 'pages/automation/automation.dart';
import 'pages/analytics/analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Optional: keep this helper available to call from pages
Future<void> signInAnon() async {
  final cred = await FirebaseAuth.instance.signInAnonymously();
  debugPrint('Signed in: ${cred.user?.uid}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jendela Rumah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        // Enforce SLIDE-ONLY transitions (Cupertino style) across the app.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// AppShell = Bottom navigation + PageView (swipe) + per-tab Navigator (deep stacks)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _controller = PageController();
  int _currentIndex = 0;

  // One Navigator per tab keeps independent back stacks.
  final _homeNavKey = GlobalKey<NavigatorState>();
  final _autoNavKey = GlobalKey<NavigatorState>();
  final _anaNavKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final currentKey = <GlobalKey<NavigatorState>>[
      _homeNavKey,
      _autoNavKey,
      _anaNavKey,
    ][_currentIndex];

    if (currentKey.currentState?.canPop() ?? false) {
      currentKey.currentState!.pop();
      return false; // handled inside tab
    }
    return true; // allow system back to exit
  }

  void _onTapTab(int index) {
    setState(() => _currentIndex = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PageView(
          controller: _controller,
          physics: const BouncingScrollPhysics(), // swipe between tabs
          onPageChanged: (i) => setState(() => _currentIndex = i),
          children: [
            _TabNavigator(navigatorKey: _homeNavKey, tab: _Tab.home),
            _TabNavigator(navigatorKey: _autoNavKey, tab: _Tab.automation),
            _TabNavigator(navigatorKey: _anaNavKey, tab: _Tab.analytics),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTapTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_motion_outlined),
              selectedIcon: Icon(Icons.auto_awesome_motion),
              label: 'Automation',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Per-tab Navigator ----------------

enum _Tab { home, automation, analytics }

class _TabNavigator extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final _Tab tab;

  const _TabNavigator({required this.navigatorKey, required this.tab});

  @override
  State<_TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<_TabNavigator>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // preserve each tab's stack & state

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Navigator(
      key: widget.navigatorKey,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = switch (widget.tab) {
              _Tab.home => const HomePage(),
              _Tab.automation => const AutomationPage(),
              _Tab.analytics => const AnalyticsPage(),
            };
            break;
          case '/details':
            page = _DetailsPage(
              title: settings.arguments as String? ?? 'Details',
            );
            break;
          default:
            page = const _NotFoundPage();
        }
        // MaterialPageRoute picks up the app's PageTransitionsTheme → slide-only
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}

// ---------------- Example deeper pages (optional) ----------------

class _DetailsPage extends StatelessWidget {
  final String title;
  const _DetailsPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const _DeepPage(),
                settings: const RouteSettings(name: '/deep'),
              ),
            );
          },
          child: const Text('Go deeper (slide)'),
        ),
      ),
    );
  }
}

class _DeepPage extends StatelessWidget {
  const _DeepPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Another level down')));
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Route not found')));
  }
}
