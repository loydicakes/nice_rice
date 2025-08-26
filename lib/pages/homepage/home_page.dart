// lib/pages/home_page/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nice_rice/header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Colors
  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color darkGreen = Color(0xFF2F6F4F);
  static const Color tileBorder = Color(0xFF7C7C7C);

  // Randomized storage metrics (temp/humidity/moisture)
  final _rand = Random();
  double _tempC = 60;
  double _humidity = 38;
  double _moisture = 13;
  Timer? _sensorTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // Fake sensor updates
    _sensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _tempC = 55 + _rand.nextDouble() * 10; // 55–65 °C
        _humidity = 30 + _rand.nextDouble() * 15; // 30–45 %
        _moisture = 13 + _rand.nextInt(6).toDouble(); // 13–18 %
      });
    });
    // Keep time real-time even if sensors pause
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

  // Moisture → Status
  String _statusText(double m) {
    if (m >= 13 && m <= 14) return "Safe";
    if (m >= 15 && m <= 16) return "Warning";
    if (m >= 17 && m <= 18) return "At risk";
    return m < 13 ? "Safe" : "At risk";
  }

  Color _statusColor(String s) {
    switch (s) {
      case "Safe":
        return const Color(0xFF46cc0d); // green
      case "Warning":
        return const Color(0xFFF9A825); // amber
      default:
        return const Color(0xFFC62828); // red
    }
  }

  TextStyle _textStyle({
    double? size,
    FontWeight? weight,
    Color color = darkGreen,
    double? height,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final now = DateTime.now();
    final w = MediaQuery.of(context).size.width;

    // Make tiles taller to avoid overflow
    final gridAspect = w < 380 ? 0.86 : 0.98; // width/height ratio (smaller => taller)

    return Scaffold(
      appBar: const PageHeader(), 
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ───────── Phone + Date/Time + Connect (single card) ─────────
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Left: phone placeholder (swap with your asset anytime)
                    Container(
                      width: 96,
                      height: 120,
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.phone_android_outlined,
                        size: 60,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: date/time + connect
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(now),
                              style: _textStyle(size: 16, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_formatTime(now),
                              style: _textStyle(size: 13, weight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                // TODO: hook up to your connect flow
                              },
                              child: Text(
                                "Connect",
                                style: _textStyle(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ───────── Drying Chamber (0% progress, with blank % label) ─────────
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Drying Chamber",
                            style: _textStyle(size: 15, weight: FontWeight.w700)),
                        const Spacer(),
                        // Placeholder for machine-driven percentage — left intentionally blank, only "%" visible
                        Text("%", style: _textStyle(size: 13, weight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 0.0, // start at 0%
                        minHeight: 10,
                        backgroundColor: Color(0xFFE5EBE6),
                        valueColor: AlwaysStoppedAnimation(darkGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ───────── Storage Chamber ─────────
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Storage Chamber",
                        style: _textStyle(size: 16, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: gridAspect,
                      ),
                      children: [
                        _MetricTile(
                          icon: Icons.thermostat_outlined,
                          label: "Temperature",
                          value: "${_tempC.toStringAsFixed(0)}ºC",
                          textStyle: _textStyle,
                        ),
                        _MetricTile(
                          icon: Icons.water_drop_outlined,
                          label: "Humidity",
                          value: "${_humidity.toStringAsFixed(0)}%",
                          textStyle: _textStyle,
                        ),
                        _MetricTile(
                          icon: Icons.eco_outlined,
                          label: "Moisture Content",
                          value: "${_moisture.toStringAsFixed(0)}%",
                          textStyle: _textStyle,
                        ),
                        _StatusTile(
                          status: _statusText(_moisture),
                          color: _statusColor(_statusText(_moisture)),
                          labelStyle:
                              _textStyle(size: 13, weight: FontWeight.w600),
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

  String _formatDate(DateTime dt) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    return "$h:$m $ampm";
  }
}

// ───────── Tiles ─────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle Function({double? size, FontWeight? weight, Color color, double? height}) textStyle;

  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color border = Color(0xFF7C7C7C);
  static const Color darkGreen = Color(0xFF2F6F4F);

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Single layer: pure F5F5F5 with 7C7C7C border
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // helps avoid overflow
        children: [
          Icon(icon, color: darkGreen, size: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textStyle(size: 28, weight: FontWeight.w800),
            ),
          ),
          Text(label, style: textStyle(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String status;
  final Color color; // dynamic (safe/warning/at risk)
  final TextStyle labelStyle;

  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color border = Color(0xFF7C7C7C);

  const _StatusTile({
    required this.status,
    required this.color,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Single layer: pure F5F5F5 with 7C7C7C border
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // avoids overflow
        children: [
          Icon(Icons.storage_outlined, color: color, size: 18),
          Center(
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Align(alignment: Alignment.bottomLeft, child: Text("Storage Status", style: labelStyle)),
        ],
      ),
    );
  }
}
