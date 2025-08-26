// lib/pages/home_page/home_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nice_rice/pages/automation/automation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Randomized storage metrics (temp/humidity/moisture)
  final _rand = Random();
  double _tempC = 60;
  double _humidity = 38;
  double _moisture = 13;
  Timer? _sensorTimer;

  @override
  void initState() {
    super.initState();
    _sensorTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _tempC = 55 + _rand.nextDouble() * 10; // 55–65 °C
        _humidity = 30 + _rand.nextDouble() * 15; // 30–45 %
        _moisture = 13 + _rand.nextInt(6).toDouble(); // 13–18 %
      });
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    super.dispose();
  }

  // ── Moisture → Status
  String _statusText(double m) {
    if (m >= 13 && m <= 14) return "Safe";
    if (m >= 15 && m <= 16) return "Warning";
    if (m >= 17 && m <= 18) return "At risk";
    return m < 13 ? "Safe" : "At risk";
  }

  Color _statusColor(String s) {
    switch (s) {
      case "Safe":
        return const Color(0xFF2E7D32);
      case "Warning":
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final now = DateTime.now();
    const themeGreen = Color(0xFF2F6F4F);
    final w = MediaQuery.of(context).size.width;
    // Make grid tiles tall enough on narrow screens
    final gridAspect = w < 380 ? 1.1 : 1.25; // width/height ratio

    return Scaffold(
      // No AppBar here — header is provided globally in main.dart
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ───────── Connection Card ─────────
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Device illustration
                    Container(
                      width: 72,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFEA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_iphone,
                        size: 40,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(now),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(now),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 140,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {},
                              child: const Text("Connect"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ───────── Operation Progress (separate container) ─────────
            ValueListenableBuilder<bool>(
              valueListenable: AutomationPage.isActive,
              builder: (_, active, __) {
                if (!active) return const SizedBox.shrink();
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Drying Chamber",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<double>(
                              valueListenable: AutomationPage.progress,
                              builder: (_, p, __) {
                                final pct = (p * 100)
                                    .clamp(0, 100)
                                    .toStringAsFixed(0);
                                return Text(
                                  "In progress $pct%",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 10,
                            child: ValueListenableBuilder<double>(
                              valueListenable: AutomationPage.progress,
                              builder: (_, p, __) => LinearProgressIndicator(
                                value: p.clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFE5EBE6),
                                valueColor: const AlwaysStoppedAnimation(
                                  themeGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ───────── Storage Chamber ─────────
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Storage Chamber",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                        childAspectRatio: gridAspect, // taller tiles
                      ),
                      children: [
                        _MetricTile(
                          icon: Icons.thermostat_outlined,
                          label: "Temperature",
                          value: "${_tempC.toStringAsFixed(0)}°C",
                          color: themeGreen,
                        ),
                        _MetricTile(
                          icon: Icons.water_drop_outlined,
                          label: "Humidity",
                          value: "${_humidity.toStringAsFixed(0)}%",
                          color: const Color(0xFF5B7F72),
                        ),
                        _MetricTile(
                          icon: Icons.eco_outlined,
                          label: "Moisture Content",
                          value: "${_moisture.toStringAsFixed(0)}%",
                          color: const Color(0xFF6E8C7A),
                        ),
                        _StatusTile(
                          status: _statusText(_moisture),
                          color: _statusColor(_statusText(_moisture)),
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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

// ───────── Tiles (overflow-safe) ─────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          // FittedBox prevents "BOTTOM OVERFLOWED" on tiny screens
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
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
  const _StatusTile({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: color, size: 20),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
          const Spacer(),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              "Storage Status",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
