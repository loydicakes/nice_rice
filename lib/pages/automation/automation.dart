// lib/pages/automation/automation.dart
import 'dart:async';
import 'dart:math';
import 'dart:math' as math show pi;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:nice_rice/header.dart';
import 'package:nice_rice/theme_controller.dart'; // ThemeScope + context.brand

// Import the history repository (declared in analytics.dart)
import 'package:nice_rice/pages/analytics/analytics.dart' show OperationHistory;

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  /// Exposed notifiers (read by HomePage to mirror Drying Chamber progress)
  static final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  static final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ---------------------- Timers / State ----------------------
  Timer? _timer;
  Duration _remaining = const Duration(seconds: 0);
  Duration _initial = const Duration(seconds: 0);
  bool _isPaused = false;
  bool _isRunning = false;
  String? _currentOpId;

  // Simulated sensors
  Timer? _sensorTimer;
  final Random _rand = Random();
  double _moisture = 13.7;
  double _temperature = 27.0;

  @override
  void initState() {
    super.initState();
    // Simulate sensor updates every 2s
    _sensorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _moisture = 10 + _rand.nextDouble() * 10; // 10–20 %
        _temperature = 25 + _rand.nextDouble() * 5; // 25–30 °C
      });

      // Log samples to Analytics only while running
      if (_isRunning && _currentOpId != null) {
        OperationHistory.instance.logReading(_currentOpId!, _moisture);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorTimer?.cancel();

    AutomationPage.isActive.value = false;
    AutomationPage.progress.value = 0.0;

    if (_currentOpId != null) {
      OperationHistory.instance.logReading(_currentOpId!, _moisture);
      OperationHistory.instance.endOperation(_currentOpId!);
      _currentOpId = null;
    }
    super.dispose();
  }

  // ---------------------- Helpers ----------------------
  double _scaleForWidth(double width) => (width / 375).clamp(0.85, 1.25);

  String _fmtTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final cs = Theme.of(context).colorScheme;
    TextStyle t(double sz, {FontWeight? w, Color? c}) =>
        GoogleFonts.poppins(fontSize: sz, fontWeight: w, color: c ?? cs.onSurface);

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: t(18, w: FontWeight.w700)),
        content: Text(message, style: t(14, c: cs.onSurface.withOpacity(0.85))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: t(14, w: FontWeight.w600, c: context.brand)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text("Confirm", style: t(14, w: FontWeight.w700, c: cs.onPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _setTime() async {
    if (_isRunning) {
      Fluttertoast.showToast(msg: "Operation is ongoing, stop first to reset");
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final minC = TextEditingController();
    final secC = TextEditingController();

    TextStyle t(double sz, {FontWeight? w, Color? c}) =>
        GoogleFonts.poppins(fontSize: sz, fontWeight: w, color: c ?? cs.onSurface);

    int minutes = 0;
    int seconds = 0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Set Timer", style: t(18, w: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Minutes"),
            ),
            TextField(
              controller: secC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Seconds"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: t(14, w: FontWeight.w600, c: context.brand)),
          ),
          ElevatedButton(
            onPressed: () {
              minutes = int.tryParse(minC.text) ?? 0;
              seconds = int.tryParse(secC.text) ?? 0;
              Navigator.pop(ctx);
            },
            child: Text("OK", style: t(14, w: FontWeight.w700, c: cs.onPrimary)),
          ),
        ],
      ),
    );

    setState(() {
      _initial = Duration(minutes: minutes, seconds: seconds);
      _remaining = _initial;
    });
  }

  double get _progress {
    final total = _initial.inSeconds;
    if (total <= 0) return 0.0;
    final done = total - _remaining.inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  void _startTimer() {
    if (_remaining.inSeconds > 0) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });

      AutomationPage.isActive.value = true;
      AutomationPage.progress.value = _progress;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remaining.inSeconds > 0) {
          setState(() {
            _remaining -= const Duration(seconds: 1);
          });
          AutomationPage.progress.value = _progress;
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _isPaused = false;
          });
          AutomationPage.isActive.value = false;
          AutomationPage.progress.value = 0.0;

          if (_currentOpId != null) {
            OperationHistory.instance.logReading(_currentOpId!, _moisture);
            OperationHistory.instance.endOperation(_currentOpId!);
            _currentOpId = null;
          }
        }
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
    AutomationPage.isActive.value = true;
    AutomationPage.progress.value = _progress;
  }

  void _resumeTimer() {
    _startTimer();
    setState(() {
      _isPaused = false;
      _isRunning = true;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = const Duration(seconds: 0);
      _initial = const Duration(seconds: 0);
      _isPaused = false;
      _isRunning = false;
    });
    AutomationPage.isActive.value = false;
    AutomationPage.progress.value = 0.0;

    if (_currentOpId != null) {
      OperationHistory.instance.logReading(_currentOpId!, _moisture);
      OperationHistory.instance.endOperation(_currentOpId!);
      _currentOpId = null;
    }
  }

  // ---------------------- Build ----------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeScope = ThemeScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PageHeader(
        isDarkMode: themeScope.isDark,
        onThemeChanged: themeScope.setDark,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final bool isTablet = maxW >= 700;
            final double scale = _scaleForWidth(maxW);

            // Content max width on wide screens
            final double contentMaxWidth = isTablet ? 860.0 : 600.0;

            // Scaled sizes
            final double cardPad   = (16 * scale).clamp(12, 22).toDouble();
            final double tileMinH  = (140 * scale).clamp(120, 180).toDouble();
            final double timerSide = (maxW * (isTablet ? 0.55 : 0.75)).clamp(240, 520).toDouble();
            final double ringTrack = (8 * scale).clamp(6, 12).toDouble();
            final double ringStroke= (12 * scale).clamp(10, 16).toDouble();
            final double dotSize   = (18 * scale).clamp(14, 24).toDouble();
            final double timerText = (48 * scale).clamp(36, 64).toDouble();

            // ------------------ Buttons styles (theme-aware) ------------------
            final ButtonStyle startStyle = ElevatedButton.styleFrom(
              backgroundColor: context.brand,
              foregroundColor: cs.onPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: (22 * scale).clamp(16, 28).toDouble(),
                vertical: (14 * scale).clamp(10, 18).toDouble(),
              ),
              minimumSize: Size(0, (44 * scale).clamp(40, 52).toDouble()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            );

            final ButtonStyle pauseResumeStyle = ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: (22 * scale).clamp(16, 28).toDouble(),
                vertical: (14 * scale).clamp(10, 18).toDouble(),
              ),
              minimumSize: Size(0, (44 * scale).clamp(40, 52).toDouble()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            );

            final ButtonStyle stopStyle = ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: (22 * scale).clamp(16, 28).toDouble(),
                vertical: (14 * scale).clamp(10, 18).toDouble(),
              ),
              minimumSize: Size(0, (44 * scale).clamp(40, 52).toDouble()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            );

            final ButtonStyle setStyle = OutlinedButton.styleFrom(
              foregroundColor: context.brand,
              side: BorderSide(color: context.brand, width: (1.2 * scale).clamp(1, 1.6).toDouble()),
              padding: EdgeInsets.symmetric(
                horizontal: (22 * scale).clamp(16, 28).toDouble(),
                vertical: (12 * scale).clamp(9, 16).toDouble(),
              ),
              minimumSize: Size(0, (40 * scale).clamp(36, 48).toDouble()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            );

            // ------------------ Sub-widgets ------------------
            TextStyle t(double sz, {FontWeight? w, Color? c}) =>
                GoogleFonts.poppins(fontSize: sz, fontWeight: w, color: c ?? cs.onSurface);

            Widget metricRow() {
              return Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      minHeight: tileMinH,
                      pad: cardPad,
                      icon: Icons.water_drop_outlined,
                      label: "Moisture Content",
                      value: "${_moisture.toStringAsFixed(1)}%",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      minHeight: tileMinH,
                      pad: cardPad,
                      icon: Icons.thermostat_outlined,
                      label: "Temperature",
                      value: "${_temperature.toStringAsFixed(1)}°C",
                    ),
                  ),
                ],
              );
            }

            Widget controlsRow() {
              Widget label(String text) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      softWrap: false,
                      style: t((14 * scale).clamp(12, 18).toDouble(), w: FontWeight.w700, c: Colors.white),
                    ),
                  );

              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: stopStyle,
                      onPressed: () {
                        if (!(_isRunning || _isPaused)) return;
                        _confirm(
                          title: "Stop Timer",
                          message: "You are about to stop the operation.",
                          onConfirm: _stopTimer,
                        );
                      },
                      child: label("Stop"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: pauseResumeStyle,
                      onPressed: () {
                        if (_timer != null && _timer!.isActive) {
                          _pauseTimer();
                        } else if (_isPaused) {
                          _resumeTimer();
                        }
                      },
                      child: label(_isPaused ? "Resume" : "Pause"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: startStyle,
                      onPressed: () {
                        if (_isRunning) {
                          Fluttertoast.showToast(msg: "Operation is ongoing, stop first to restart");
                          return;
                        }
                        if (_remaining.inSeconds == 0) {
                          Fluttertoast.showToast(msg: "Please set a timer first");
                          return;
                        }
                        _confirm(
                          title: "Start Timer",
                          message: "You are about to start the operation.",
                          onConfirm: () {
                            Fluttertoast.showToast(msg: "Operation is ongoing");
                            _currentOpId = OperationHistory.instance.startOperation();
                            OperationHistory.instance.logReading(_currentOpId!, _moisture);
                            _startTimer();
                          },
                        );
                      },
                      child: label("Start"),
                    ),
                  ),
                ],
              );
            }

            final dotColor =
                Color.lerp(Colors.green, const Color(0xFFC62828), _progress) ?? Colors.green;

            // ------------------ Layout ------------------
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ───────── Metrics Card ─────────
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(cardPad),
                          child: metricRow(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ───────── Timer Card ─────────
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(cardPad),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Automation Timer",
                                  style: t((16 * scale).clamp(14, 20).toDouble(), w: FontWeight.w700, c: context.brand),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Circular timer with moving dot + gradient trail
                              SizedBox(
                                width: timerSide,
                                height: timerSide,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: Size.square(timerSide),
                                      painter: _TimerRingPainter(
                                        context: context,
                                        progress: _progress,
                                        track: ringTrack,
                                        stroke: ringStroke,
                                      ),
                                    ),
                                    // Moving dot (starts at 12 o’clock)
                                    Transform.rotate(
                                      angle: 2 * math.pi * _progress,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          width: dotSize,
                                          height: dotSize,
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: dotColor.withOpacity(0.45),
                                                blurRadius: (10 * scale).clamp(6, 14).toDouble(),
                                                spreadRadius: (2 * scale).clamp(1, 3).toDouble(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Center readout & Set
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _fmtTime(_remaining),
                                          style: t(timerText, w: FontWeight.w800),
                                        ),
                                        SizedBox(height: (12 * scale).clamp(8, 16).toDouble()),
                                        OutlinedButton(
                                          style: setStyle,
                                          onPressed: _setTime,
                                          child: Text(
                                            "Set",
                                            maxLines: 1,
                                            softWrap: false,
                                            style: t((14 * scale).clamp(12, 18).toDouble(), w: FontWeight.w700, c: context.brand),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: (16 * scale).clamp(12, 22).toDouble()),
                              controlsRow(),
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

  // ------- Metric card wrapper -------
  Widget _metricCard({
    required double minHeight,
    required double pad,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: _MetricBox(
        label: label,
        value: value,
        bg: cs.surfaceVariant,
        border: cs.outline,
        icon: icon,
        // 👇 matches the expected named-parameter signature
        textBuilder: ({
          double? size,
          FontWeight? weight,
          Color color = const Color(0x00000000), // sentinel; use onSurface if transparent
          double? height,
          TextDecoration? deco,
        }) {
          final effective =
              color == const Color(0x00000000) ? cs.onSurface : color;
          return GoogleFonts.poppins(
            fontSize: size,
            fontWeight: weight,
            color: effective,
            height: height,
            decoration: deco,
          );
        },
      ),
    );
  }
}

/// Metric tile styled like HomePage tiles, but theme-aware
class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color border;
  final IconData icon;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color color,
    double? height,
    TextDecoration? deco,
  }) textBuilder;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.bg,
    required this.border,
    required this.textBuilder,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 375).clamp(0.85, 1.25).toDouble();

    return Container(
      padding: EdgeInsets.all((14 * scale).clamp(10, 18).toDouble()),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: (18 * scale).clamp(16, 22).toDouble()),
          SizedBox(height: (6 * scale).clamp(4, 10).toDouble()),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: textBuilder(
                size: (28 * scale).clamp(22, 34).toDouble(),
                weight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          SizedBox(height: (2 * scale).clamp(2, 6).toDouble()),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textBuilder(
              size: (13 * scale).clamp(11, 16).toDouble(),
              weight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the circular timer ring with theme colors:
/// - Base track uses onSurface (low opacity)
/// - Progress arc sweeps brand → amber → red
class _TimerRingPainter extends CustomPainter {
  final BuildContext context;
  final double progress; // 0.0 → 1.0
  final double track;
  final double stroke;

  _TimerRingPainter({
    required this.context,
    required this.progress,
    this.track = 8,
    this.stroke = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cs = Theme.of(context).colorScheme;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final base = Paint()
      ..color = cs.onSurface.withOpacity(0.18)
      ..strokeWidth = track
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [context.brand, Colors.amber.shade700, const Color(0xFFC62828)],
        stops: const [0.0, 0.6, 1.0],
        transform: const GradientRotation(-math.pi / 2), // start at 12 o’clock
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Base ring
    canvas.drawCircle(center, radius, base);

    // Progress arc
    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.track != track || old.stroke != stroke;
}
