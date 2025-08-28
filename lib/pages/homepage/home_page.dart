// lib/pages/homepage/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nice_rice/header.dart';
import 'package:nice_rice/theme_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ─── Fake sensor stream ────────────────────────────────────────────────────
  final _rand = Random();
  Timer? _sensorTimer;
  Timer? _clockTimer;

  // live values
  double _tempC = 60;
  double _humidity = 38;
  double _moisture = 15;

  // rolling history for stats (keep last N samples)
  final List<double> _moistureHistory = [];
  static const int _historyCap = 24; // ~ last 24 samples

  @override
  void initState() {
    super.initState();

    // seed history so stats render immediately
    for (int i = 0; i < 6; i++) {
      final m = 13 + _rand.nextInt(6).toDouble(); // 13–18
      _moistureHistory.add(m);
    }

    // sensor updates
    _sensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _tempC = 55 + _rand.nextDouble() * 10; // 55–65
        _humidity = 30 + _rand.nextDouble() * 15; // 30–45
        _moisture = 13 + _rand.nextInt(6).toDouble(); // 13–18

        _moistureHistory.add(_moisture);
        if (_moistureHistory.length > _historyCap) {
          _moistureHistory.removeAt(0);
        }
      });
    });

    // real-time clock tick (if you show time)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  // ─── Domain helpers ────────────────────────────────────────────────────────
  String _statusText(double m) {
    if (m >= 13 && m <= 14) return "Safe";
    if (m >= 15 && m <= 16) return "Warning";
    if (m >= 17 && m <= 18) return "At risk";
    return m < 13 ? "Safe" : "At risk";
  }

  Color _statusColor(String s) {
    switch (s) {
      case "Safe":
        return const Color(0xFF46cc0d);
      case "Warning":
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFFC62828);
    }
  }

  double get _avgMoisture {
    if (_moistureHistory.isEmpty) return _moisture;
    final sum = _moistureHistory.fold<double>(0, (a, b) => a + b);
    return sum / _moistureHistory.length; // keep as percentage points (not 0–1)
  }

  double get _minMoisture =>
      _moistureHistory.isEmpty ? _moisture : _moistureHistory.reduce(min);

  double get _maxMoisture =>
      _moistureHistory.isEmpty ? _moisture : _moistureHistory.reduce(max);

  /// Change = last - first (percentage points).
  /// Negative → falling, Positive → rising, ~0 → steady.
  double get _change {
    if (_moistureHistory.length < 2) return 0;
    final first = _moistureHistory.first;
    final last = _moistureHistory.last;
    return (last - first);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    return "$h:$m $ampm";
  }

  TextStyle _textStyle(
    BuildContext context, {
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        height: height,
      );

  // ─── Responsive helpers ────────────────────────────────────────────────────

  /// Returns a scale factor relative to a 375px-wide phone, clamped for sanity.
  double _scaleForWidth(double width) {
    return (width / 375).clamp(0.85, 1.25).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ThemeScope.of(context); // for header toggle
    final now = DateTime.now();

    return Scaffold(
      appBar: PageHeader(
        isDarkMode: theme.isDark,
        onThemeChanged: theme.setDark,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;

            // Breakpoints
            final bool isCompact = maxW < 420;     // small phones
            final bool isTablet = maxW >= 700;     // tablets and up

            final scale = _scaleForWidth(maxW);

            // Scaled dimensions
            final double imgHeight = (120 * scale).clamp(96, 160).toDouble();
            final double imgWidth = imgHeight * 0.8;
            final double dateFs = (18 * scale).clamp(14, 24).toDouble();
            final double timeFs = (14 * scale).clamp(12, 20).toDouble();
            final double btnVPad = (12 * scale).clamp(8, 18).toDouble();
            const double btnHPad = 20.0;

            // Grid config (normal aspect since status tile is shorter now)
            final int gridCols = isTablet ? 3 : 2;
            final double gridAspect = isTablet ? 1.18 : (isCompact ? 0.95 : 1.05);

            // Content max width for very wide layouts
            final double contentMaxWidth = isTablet ? 800.0 : 600.0;

            final status = _statusText(_moisture);
            final statusColor = _statusColor(status);

            // change label text (kept for future but not displayed in tile)
            final changeArrow = _change < -0.2 ? "⬇︎" : (_change > 0.2 ? "⬆︎" : "→");
            final changeWord =
                _change < -0.2 ? "falling" : (_change > 0.2 ? "rising" : "steady");
            final changePretty =
                "${_change >= 0 ? "+" : ""}${_change.toStringAsFixed(1)}%";

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ───────── Header card (image + date/time + connect) ─────────
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (ctx, box) {
        // Image width adapts to available card width, but stays within sane bounds.
        final double imgW = (box.maxWidth * 0.28).clamp(92.0, 160.0).toDouble();
        final double imgH = (imgW * 1.25).clamp(110.0, 200.0).toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image is hard-bounded, clipped, and cannot spill
            SizedBox(
              width: imgW,
              height: imgH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  "assets/images/pon.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Date / time / Connect stays to the right and wraps nicely on small screens
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      context,
                      size: (18 * _scaleForWidth(box.maxWidth)).clamp(14, 22).toDouble(),
                      weight: FontWeight.w700,
                      color: context.brand,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle(
                      context,
                      size: (14 * _scaleForWidth(box.maxWidth)).clamp(12, 18).toDouble(),
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button won’t force overflow; it shrinks and wraps if space is tight
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 120),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: (12 * _scaleForWidth(box.maxWidth)).clamp(8, 16).toDouble(),
                          ),
                        ),
                        onPressed: () {},
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Connect",
                            style: _textStyle(
                              context,
                              size: (16 * _scaleForWidth(box.maxWidth)).clamp(13, 20).toDouble(),
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
),


                      const SizedBox(height: 14),

                      // ───────── Drying Chamber ─────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Drying Chamber",
                                    style: _textStyle(
                                      context,
                                      size: (15 * scale).clamp(13, 18).toDouble(),
                                      weight: FontWeight.w700,
                                      color: context.brand,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "%",
                                    style: _textStyle(
                                      context,
                                      size: (13 * scale).clamp(11, 16).toDouble(),
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: 0.0,
                                  minHeight: (10 * scale).clamp(8, 14).toDouble(),
                                  backgroundColor: context.progressTrack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ───────── Storage Chamber ─────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Storage Chamber",
                                  style: _textStyle(
                                    context,
                                    size: (16 * scale).clamp(14, 20).toDouble(),
                                    weight: FontWeight.w700,
                                    color: context.brand,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCols,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: gridAspect,
                                ),
                                children: [
                                  _MetricTile(
                                    icon: Icons.thermostat_outlined,
                                    label: "Temperature",
                                    value: "${_tempC.toStringAsFixed(0)}ºC",
                                    scale: scale,
                                  ),
                                  _MetricTile(
                                    icon: Icons.water_drop_outlined,
                                    label: "Humidity",
                                    value: "${_humidity.toStringAsFixed(0)}%",
                                    scale: scale,
                                  ),
                                  _MetricTile(
                                    icon: Icons.eco_outlined,
                                    label: "Moisture Content",
                                    value: "${_moisture.toStringAsFixed(1)}%",
                                    scale: scale,
                                  ),
                                  // ⬇️ Simplified status tile (no bullets)
                                  _StatusTile(
                                    status: status,
                                    color: statusColor,
                                    scale: scale,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Tiles ───────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double scale;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: context.tileFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tileStroke),
      ),
      padding: EdgeInsets.all((14 * scale).clamp(10, 18).toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.brand, size: (18 * scale).clamp(16, 22).toDouble()),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: (28 * scale).clamp(22, 34).toDouble(),
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: (13 * scale).clamp(11, 16).toDouble(),
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String status;
  final Color color;
  final double scale;

  const _StatusTile({
    required this.status,
    required this.color,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: context.tileFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tileStroke),
      ),
      padding: EdgeInsets.all((14 * scale).clamp(10, 18).toDouble()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.storage_outlined, color: color, size: (18 * scale).clamp(16, 22).toDouble()),
          ),
          const SizedBox(height: 8),
          Text(
            status, // e.g., "At risk", "Safe", "Warning"
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: (20 * scale).clamp(16, 26).toDouble(),
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Storage Status",
            style: GoogleFonts.poppins(
              fontSize: (13 * scale).clamp(11, 16).toDouble(),
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
