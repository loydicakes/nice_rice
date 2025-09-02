// lib/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // for CupertinoPageTransitionsBuilder

/// ─────────────────────────────────────────────────────────────────────────
/// 1) Simple global controller + scope
/// ─────────────────────────────────────────────────────────────────────────
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void setDark(bool value) {
    final next = value ? ThemeMode.dark : ThemeMode.light;
    if (next != _mode) {
      _mode = next;
      notifyListeners();
    }
  }
}

/// Inherited wrapper so any widget can read/update the theme without prop-drilling.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found. Wrap your app with ThemeScope.');
    return scope!.notifier!;
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// 2) Brand tokens (from your HomePage constants)
/// ─────────────────────────────────────────────────────────────────────────
class Brand {
  // Light
  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color darkGreen = Color(0xFF2F6F4F);
  static const Color tileBorder = Color(0xFF7C7C7C);
  static const Color progressBgLight = Color(0xFFE5EBE6);

  // Dark (tuned for contrast + depth)
  static const Color darkBg = Color(0xFF0E1311);
  static const Color darkSurface = Color(0xFF1A201D);
  static const Color darkTileBorder = Color(0xFF404A45);
  static const Color progressBgDark = Color(0xFF243329);
}

/// ─────────────────────────────────────────────────────────────────────────
/// 3) App themes (Material 3), incl. page transitions
/// ─────────────────────────────────────────────────────────────────────────
class AppThemes {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Brand.darkGreen,
        brightness: Brightness.light,
      ).copyWith(
        // map tokens to semantic roles you’ll reuse across widgets
        background: Brand.bgGrey,
        surface: Colors.white,
        surfaceVariant: Brand.bgGrey,           // for tile backgrounds
        outline: Brand.tileBorder,              // for tile borders
        tertiaryContainer: Brand.progressBgLight, // for progress tracks
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Brand.bgGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Brand.bgGrey,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Brand.darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Brand.darkGreen,           // LinearProgressIndicator value color
        linearTrackColor: Brand.progressBgLight,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Brand.darkGreen,
        brightness: Brightness.dark,
      ).copyWith(
        background: Brand.darkBg,
        surface: Brand.darkSurface,
        surfaceVariant: const Color(0xFF141A17), // darker tile fill
        outline: Brand.darkTileBorder,
        tertiaryContainer: Brand.progressBgDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: Brand.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Brand.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Brand.darkSurface,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Brand.darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Brand.darkGreen,
        linearTrackColor: Brand.progressBgDark,
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// 4) Convenience extensions for clean UI code
///    (so you can write context.brand, context.tileFill, etc.)
/// ─────────────────────────────────────────────────────────────────────────
extension NiceColors on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;

  /// Brand accent (your darkGreen)
  Color get brand => cs.primary;

  /// Tile background (bgGrey in light, dark fill in dark)
  Color get tileFill => cs.surfaceVariant;

  /// Tile/card border color
  Color get tileStroke => cs.outline;

  /// LinearProgressIndicator track background
  Color get progressTrack => cs.tertiaryContainer;

  /// App bar/system bar background (matches scaffold)
  Color get appBarBg =>
      Theme.of(this).appBarTheme.backgroundColor ??
      Theme.of(this).scaffoldBackgroundColor;
}
