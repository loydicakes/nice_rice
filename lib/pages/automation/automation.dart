// lib/pages/automation/automation.dart
import 'dart:async';
import 'dart:math';
import 'dart:math' as math show pi;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nice_rice/header.dart';

// ⬇️ Import the history repository (from analytics.dart)
import 'package:nice_rice/pages/analytics/analytics.dart' show OperationHistory;

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  // HomePage reads these directly (for the Drying Chamber progress)
  static final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  static final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ───────────────── THEME TOKENS (match HomePage) ─────────────────
  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color darkGreen = Color(0xFF2F6F4F);
  static const Color tileBorder = Color(0xFF7C7C7C);
  static const Color amber = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  TextStyle _txt({
    double? size,
    FontWeight? weight,
    Color color = darkGreen,
    double? height,
    TextDecoration? deco,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: deco,
      );

  ButtonStyle get _pillPrimary => ElevatedButton.styleFrom(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );

  ButtonStyle get _pillWarn => ElevatedButton.styleFrom(
        backgroundColor: amber,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );

  ButtonStyle get _pillDanger => ElevatedButton.styleFrom(
        backgroundColor: danger,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );

  ButtonStyle get _pillOutline => OutlinedButton.styleFrom(
        foregroundColor: darkGreen,
        side: const BorderSide(color: darkGreen, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );

  // ───────────────── TIMER / SIM DATA ─────────────────
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 0, seconds: 0);
  Duration _initial = const Duration(minutes: 0, seconds: 0);
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

  // ───────────────── HELPERS ─────────────────
  String _fmtTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: _txt(size: 18, weight: FontWeight.w700, color: Colors.black87)),
        content: Text(message, style: _txt(size: 14, weight: FontWeight.w400, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: _txt(size: 14, weight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: _pillPrimary,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text("Confirm", style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white)),
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

    int minutes = 0;
    int seconds = 0;
    final minC = TextEditingController();
    final secC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Set Timer", style: _txt(size: 18, weight: FontWeight.w700, color: Colors.black87)),
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
            child: Text("Cancel", style: _txt(size: 14, weight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: _pillPrimary,
            onPressed: () {
              minutes = int.tryParse(minC.text) ?? 0;
              seconds = int.tryParse(secC.text) ?? 0;
              Navigator.pop(ctx);
            },
            child: Text("OK", style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Size size = MediaQuery.of(context).size;
    final Color dotColor =
        Color.lerp(Colors.green, danger, _progress) ?? Colors.green;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: const PageHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
           Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 140), // 🔧 lock height
                        child: _MetricBox(
                          label: "Moisture Content",
                          value: "${_moisture.toStringAsFixed(1)}%",
                          bg: bgGrey,
                          border: tileBorder,
                          textBuilder: _txt,
                          icon: Icons.water_drop_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 140), // 🔧 same height
                        child: _MetricBox(
                          label: "Temperature",
                          value: "${_temperature.toStringAsFixed(1)}°C",
                          bg: bgGrey,
                          border: tileBorder,
                          textBuilder: _txt,
                          icon: Icons.thermostat_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ───────── Timer Card (rounded, soft, roomy) ─────────
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Automation Timer",
                          style: _txt(size: 16, weight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),

                    // Circular timer with moving dot + gradient trail
                    SizedBox(
                      width: size.width * 0.75,
                      height: size.width * 0.75,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.square(size.width * 0.75),
                            painter: _TimerRingPainter(_progress),
                          ),
                          // Moving dot (starts at 12 o’clock)
                          Transform.rotate(
                            angle: 2 * math.pi * _progress,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: dotColor.withOpacity(0.45),
                                      blurRadius: 10,
                                      spreadRadius: 2,
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
                                style: _txt(size: 48, weight: FontWeight.w800, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                style: _pillOutline,
                                onPressed: _setTime,
                                child: Text("Set", style: _txt(size: 14, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Buttons Row (pill buttons, consistent spacing)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: _pillDanger,
                            onPressed: () {
                              if (!(_isRunning || _isPaused)) return;
                              _confirm(
                                title: "Stop Timer",
                                message: "You are about to stop the operation.",
                                onConfirm: _stopTimer,
                              );
                            },
                            child: Text("Stop", style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: _pillWarn,
                            onPressed: () {
                              if (_timer != null && _timer!.isActive) {
                                _pauseTimer();
                              } else if (_isPaused) {
                                _resumeTimer();
                              }
                            },
                            child: Text(_isPaused ? "Resume" : "Pause",
                                style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: _pillPrimary,
                            onPressed: () {
                              if (_isRunning) {
                                Fluttertoast.showToast(
                                  msg: "Operation is ongoing, stop first to restart",
                                );
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

                                  // Create an operation record for Analytics history
                                  _currentOpId = OperationHistory.instance.startOperation();
                                  OperationHistory.instance.logReading(_currentOpId!, _moisture);

                                  _startTimer();
                                },
                              );
                            },
                            child: Text("Start",
                                style: _txt(size: 14, weight: FontWeight.w700, color: Colors.white)),
                          ),
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
    );
  }
}

/// Metric tile styled like HomePage tiles
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

  static const Color darkGreen = Color(0xFF2F6F4F);

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: darkGreen, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textBuilder(size: 28, weight: FontWeight.w800, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: textBuilder(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Paints the circular timer ring with theme gradient
/// - Base track (subtle grey)
/// - Progress arc with darkGreen → amber → red sweep
class _TimerRingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  _TimerRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final base = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [Color(0xFF2F6F4F), Color(0xFFF9A825), Color(0xFFC62828)],
        stops: const [0.0, 0.6, 1.0],
        transform: const GradientRotation(-math.pi / 2), // start at 12 o’clock
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
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
  bool shouldRepaint(covariant _TimerRingPainter old) => old.progress != progress;
}
