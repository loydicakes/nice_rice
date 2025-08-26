// lib/pages/automation/automation.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nice_rice/header.dart';

// ⬇️ Import the history repository (from analytics.dart)
import 'package:nice_rice/pages/analytics/analytics.dart' show OperationHistory;

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});
  // ⬇️ HomePage reads these directly
  static final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  static final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Countdown state
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 0, seconds: 0);
  Duration _initial = const Duration(minutes: 0, seconds: 0);
  bool _isPaused = false;
  bool _isRunning = false;

  // Track the current operation ID for Analytics history
  String? _currentOpId;

  // Simulation values (top card)
  Timer? _sensorTimer;
  final Random _rand = Random();
  double _moisture = 13.7;
  double _temperature = 27.0;

  @override
  void initState() {
    super.initState();
    // Simulate sensor updates every 2 seconds
    _sensorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _moisture = 10 + _rand.nextDouble() * 10; // 10–20 %
        _temperature = 25 + _rand.nextDouble() * 5; // 25–30 °C
      });

      // ⬇️ Log samples to the selected operation ONLY while running
      if (_isRunning && _currentOpId != null) {
        OperationHistory.instance.logReading(_currentOpId!, _moisture);
      }
    });
  }

  void _startTimer() {
    if (_remaining.inSeconds > 0) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });

      // show progress on Home
      AutomationPage.isActive.value = true;
      AutomationPage.progress.value = _progress;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remaining.inSeconds > 0) {
          setState(() {
            _remaining -= const Duration(seconds: 1);
          });
          AutomationPage.progress.value = _progress; // live update
        } else {
          // ── Timer naturally finished ────────────────────────────────────
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _isPaused = false;
          });
          AutomationPage.isActive.value = false; // hide on Home
          AutomationPage.progress.value = 0.0;

          // ⬇️ Close the operation and log a final point for history
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
    AutomationPage.isActive.value = true; // keep bar visible while paused
    AutomationPage.progress.value = _progress; // freeze value
  }

  void _resumeTimer() {
    _startTimer();
    setState(() {
      _isPaused = false;
      _isRunning = true;
    });
    AutomationPage.isActive.value = true;
    AutomationPage.progress.value = _progress;
  }

  void _stopTimer() {
    // ── Manual stop ──────────────────────────────────────────────────────
    _timer?.cancel();
    setState(() {
      _remaining = const Duration(seconds: 0);
      _initial = const Duration(seconds: 0);
      _isPaused = false;
      _isRunning = false;
    });
    AutomationPage.isActive.value = false;
    AutomationPage.progress.value = 0.0;

    // ⬇️ Close the operation and log a final point for history
    if (_currentOpId != null) {
      OperationHistory.instance.logReading(_currentOpId!, _moisture);
      OperationHistory.instance.endOperation(_currentOpId!);
      _currentOpId = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorTimer?.cancel();
    AutomationPage.isActive.value = false; // safety reset
    AutomationPage.progress.value = 0.0;

    // If the page is disposed mid-run, finalize any open op to avoid leaks
    if (_currentOpId != null) {
      OperationHistory.instance.logReading(_currentOpId!, _moisture);
      OperationHistory.instance.endOperation(_currentOpId!);
      _currentOpId = null;
    }
    super.dispose();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // Confirm dialog (used for Start/Stop)
  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text("Confirm"),
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
    final minController = TextEditingController();
    final secController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Timer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Minutes"),
            ),
            TextField(
              controller: secController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Seconds"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              minutes = int.tryParse(minController.text) ?? 0;
              seconds = int.tryParse(secController.text) ?? 0;
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    setState(() {
      _initial = Duration(minutes: minutes, seconds: seconds);
      _remaining = _initial;
    });
  }

  // Progress from 0.0 → 1.0 based on remaining vs initial
  double get _progress {
    final total = _initial.inSeconds;
    if (total <= 0) return 0.0;
    final done = total - _remaining.inSeconds;
    return (done / total).clamp(0.0, 1.0);
    // 0.0 at start, 1.0 when finished
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dotColor =
        Color.lerp(Colors.green, Colors.red, _progress) ?? Colors.green;

    return Scaffold(
      appBar: const PageHeader(), 
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─────────────────── Top Card (Moisture & Temperature)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 180,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Moisture
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "${_moisture.toStringAsFixed(1)}%",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Moisture Content",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Temperature
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "${_temperature.toStringAsFixed(1)}°C",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Temperature",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─────────────────── Timer Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 354,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular timer with moving dot + gradient trail
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Custom painted ring
                              CustomPaint(
                                size: const Size(280, 280),
                                painter: _TimerRingPainter(_progress),
                              ),
                              // Moving dot (starts at 12 o’clock)
                              Transform.rotate(
                                angle:
                                    2 * pi * _progress, // 0 at top, clockwise
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
                                          color: dotColor.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Time text & Set button
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 80),
                                  Text(
                                    _formatTime(_remaining),
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  OutlinedButton(
                                    onPressed:
                                        _setTime, // shows toast itself if running
                                    child: const Text("Set"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Stop Button (with confirmation)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (!(_isRunning || _isPaused)) {
                              // Not running/paused -> do nothing
                              return;
                            }
                            _showConfirmDialog(
                              title: "Stop Timer",
                              message: "You are about to stop the operation.",
                              onConfirm: _stopTimer,
                            );
                          },
                          child: const Text("Stop"),
                        ),

                        // Pause / Resume Button (fixed size)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(100, 48), // lock size
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_timer != null && _timer!.isActive) {
                              _pauseTimer();
                            } else if (_isPaused) {
                              _resumeTimer();
                            }
                          },
                          child: Text(_isPaused ? "Resume" : "Pause"),
                        ),

                        // Start Button (with confirmation & toasts)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_isRunning) {
                              Fluttertoast.showToast(
                                msg:
                                    "Operation is ongoing, stop first to restart",
                              );
                              return;
                            }
                            if (_remaining.inSeconds == 0) {
                              Fluttertoast.showToast(
                                msg: "Please set a timer first",
                              );
                              return;
                            }
                            _showConfirmDialog(
                              title: "Start Timer",
                              message: "You are about to start the operation.",
                              onConfirm: () {
                                Fluttertoast.showToast(
                                  msg: "Operation is ongoing",
                                );

                                // ⬇️ Create an operation record for Analytics history
                                _currentOpId = OperationHistory.instance
                                    .startOperation();
                                // seed an initial point
                                OperationHistory.instance.logReading(
                                  _currentOpId!,
                                  _moisture,
                                );

                                // Restart from current remaining (do NOT reset to _initial)
                                _startTimer();
                              },
                            );
                          },
                          child: const Text("Start"),
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

/// Paints the circular timer ring:
/// - Base track (subtle)
/// - Progress arc with a green→yellow→red sweep gradient
class _TimerRingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  _TimerRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Base track
    final base = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Gradient progress trail (sweep around circle)
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: const [Colors.green, Colors.yellow, Colors.red],
        stops: const [0.0, 0.5, 1.0],
        // Rotate gradient so it begins at top
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw base
    canvas.drawCircle(center, radius, base);

    // Draw progress arc from top (-pi/2) clockwise
    final sweep = 2 * pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
