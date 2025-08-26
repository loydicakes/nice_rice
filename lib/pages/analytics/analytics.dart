// lib/pages/analytics/analytics.dart
import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nice_rice/header.dart';

/// ------------ Data models ------------
class MoistureReading {
  final DateTime t;
  final double value;
  const MoistureReading(this.t, this.value);
}

class OperationRecord {
  final String id; // e.g., timestamp or uuid
  final DateTime startedAt;
  DateTime? endedAt;
  final List<MoistureReading> readings;

  OperationRecord({
    required this.id,
    required this.startedAt,
    List<MoistureReading>? readings,
  }) : readings = readings ?? [];

  Duration? get duration =>
      endedAt == null ? null : endedAt!.difference(startedAt);

  String get displayTitle {
    final df = DateFormat('MMM d, HH:mm');
    final start = df.format(startedAt);
    final dur = duration == null
        ? ''
        : ' • ${duration!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return 'Operation $start$dur';
  }
}

/// ------------ Repository (singleton) ------------
abstract class OperationRepository {
  UnmodifiableListView<OperationRecord> get operations;
  OperationRecord? getById(String id);
}

class OperationHistory implements OperationRepository {
  OperationHistory._();
  static final OperationHistory instance = OperationHistory._();

  final List<OperationRecord> _ops = [];

  String startOperation() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _ops.add(OperationRecord(id: id, startedAt: DateTime.now()));
    return id;
  }

  void logReading(String opId, double moisture, {DateTime? at}) {
    final op = getById(opId);
    if (op == null) return;
    op.readings.add(MoistureReading(at ?? DateTime.now(), moisture));
  }

  void endOperation(String opId) {
    final op = getById(opId);
    if (op == null) return;
    op.endedAt ??= DateTime.now();
  }

  @override
  OperationRecord? getById(String id) =>
      _ops.cast<OperationRecord?>().firstWhere((o) => o!.id == id, orElse: () => null);

  @override
  UnmodifiableListView<OperationRecord> get operations =>
      UnmodifiableListView(_ops.reversed); // newest first
}

/// ------------ Analytics Page (History) ------------
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // THEME TOKENS (match Home/Automation)
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

  String? _selectedOpId;

  @override
  Widget build(BuildContext context) {
    final ops = OperationHistory.instance.operations;
    final OperationRecord? selected = _selectedOpId == null
        ? (ops.isNotEmpty ? ops.first : null)
        : OperationHistory.instance.getById(_selectedOpId!);
    _selectedOpId ??= selected?.id;

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: const PageHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (ops.isEmpty)
              _EmptyState(
                message:
                    'No completed operations yet.\nRun one in Automation to build history.',
                textStyle: _txt(size: 14, weight: FontWeight.w500, color: Colors.black87),
              )
            else ...[
              // Picker
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 20, color: darkGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedOpId!,
                            isExpanded: true,
                            iconEnabledColor: darkGreen,
                            items: ops
                                .map((op) => DropdownMenuItem(
                                      value: op.id,
                                      child: Text(
                                        op.displayTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: _txt(size: 14, weight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedOpId = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick stats row (tiles like Home/Automation)
              if (selected != null && selected.readings.isNotEmpty)
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _StatsRow(selected: selected, txt: _txt),
                  ),
                ),

              const SizedBox(height: 14),

              // Chart
              _SectionCard(
                title: 'Moisture Content',
                titleStyle: _txt(size: 16, weight: FontWeight.w700, color: darkGreen),
                child: (selected == null || selected.readings.length < 2)
                    ? _EmptyState(
                        message: 'Not enough data points.',
                        textStyle: _txt(size: 14, weight: FontWeight.w500, color: Colors.black87),
                      )
                    : _MoistureChart(
                        readings: selected.readings,
                        txt: _txt,
                        lineColor: darkGreen,
                        areaColor: darkGreen.withOpacity(0.20),
                        gridColor: const Color(0xFF000000).withOpacity(0.06),
                        borderColor: const Color(0xFF000000).withOpacity(0.10),
                      ),
              ),

              const SizedBox(height: 12),

              // Info footer
              if (selected != null)
                _InfoFooter(
                  op: selected,
                  txt: _txt,
                ),

              const SizedBox(height: 12),

              // Interpretation card with colored headline icon
              _InterpretationCard(
                op: selected,
                txt: _txt,
                ok: darkGreen,
                warn: amber,
                danger: danger,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------ UI Parts ------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final TextStyle titleStyle;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final TextStyle textStyle;
  const _EmptyState({required this.message, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final OperationRecord selected;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color color,
    double? height,
    TextDecoration? deco,
  }) txt;

  static const Color bgGrey = Color(0xFFF5F5F5);
  static const Color border = Color(0xFF7C7C7C);
  static const Color darkGreen = Color(0xFF2F6F4F);

  const _StatsRow({required this.selected, required this.txt});

  @override
  Widget build(BuildContext context) {
    final vals = selected.readings.map((e) => e.value).toList();
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final minV = vals.reduce((a, b) => a < b ? a : b);
    final maxV = vals.reduce((a, b) => a > b ? a : b);

    Widget tile(String label, String value, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgGrey,
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
                child: Text(value, style: txt(size: 24, weight: FontWeight.w800, color: Colors.black87)),
              ),
              const SizedBox(height: 2),
              Text(label, style: txt(size: 13, weight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile("Average", "${avg.toStringAsFixed(1)}%", Icons.timeline_outlined),
        const SizedBox(width: 12),
        tile("Min", "${minV.toStringAsFixed(1)}%", Icons.trending_down_outlined),
        const SizedBox(width: 12),
        tile("Max", "${maxV.toStringAsFixed(1)}%", Icons.trending_up_outlined),
      ],
    );
  }
}

class _MoistureChart extends StatelessWidget {
  final List<MoistureReading> readings;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color color,
    double? height,
    TextDecoration? deco,
  }) txt;
  final Color lineColor;
  final Color areaColor;
  final Color gridColor;
  final Color borderColor;

  const _MoistureChart({
    required this.readings,
    required this.txt,
    required this.lineColor,
    required this.areaColor,
    required this.gridColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final first = readings.first.t;
    final spots = readings
        .map((r) => FlSpot(r.t.difference(first).inSeconds.toDouble(), r.value))
        .toList();

    final yVals = readings.map((e) => e.value).toList();
    final yMin = yVals.reduce((a, b) => a < b ? a : b).floorToDouble();
    final yMax = yVals.reduce((a, b) => a > b ? a : b).ceilToDouble();
    final xMin = 0.0;
    final xMax = spots.isNotEmpty ? spots.last.x : 1.0;

    String xLabel(double x) =>
        DateFormat('HH:mm').format(first.add(Duration(seconds: x.round())));

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: xMin,
          maxX: xMax,
          minY: yMin,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            horizontalInterval: ((yMax - yMin) / 4).clamp(1, 100).toDouble(),
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (xMax - xMin) / 4.0,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(xLabel(v), style: txt(size: 11, weight: FontWeight.w500, color: Colors.black54)),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: ((yMax - yMin) / 5).clamp(1, 100).toDouble(),
                getTitlesWidget: (v, m) =>
                    Text(v.toStringAsFixed(0), style: txt(size: 11, weight: FontWeight.w500, color: Colors.black54)),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: borderColor),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: lineColor,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: areaColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoFooter extends StatelessWidget {
  final OperationRecord op;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color color,
    double? height,
    TextDecoration? deco,
  }) txt;

  const _InfoFooter({required this.op, required this.txt});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm:ss');
    final start = df.format(op.startedAt);
    final end = op.endedAt == null ? '—' : df.format(op.endedAt!);
    final points = op.readings.length;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Text(
          'Started: $start • Ended: $end • Points: $points',
          textAlign: TextAlign.center,
          style: txt(size: 12, weight: FontWeight.w500, color: Colors.black87),
        ),
      ),
    );
  }
}

/// ------------ Interpretation (farmer-friendly) ------------
enum _MoistureStatus { tooDry, ok, tooWet }

class _AnalysisResult {
  final _MoistureStatus status;
  final String headline;
  final List<String> points;
  final String recommendation;
  _AnalysisResult({
    required this.status,
    required this.headline,
    required this.points,
    required this.recommendation,
  });
}

class _InterpretationCard extends StatelessWidget {
  final OperationRecord? op;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color color,
    double? height,
    TextDecoration? deco,
  }) txt;
  final Color ok;
  final Color warn;
  final Color danger;

  const _InterpretationCard({
    required this.op,
    required this.txt,
    required this.ok,
    required this.warn,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    if (op == null || op!.readings.isEmpty) {
      return _SectionCard(
        title: 'Interpretation',
        titleStyle: txt(size: 16, weight: FontWeight.w700),
        child: _EmptyState(
          message: 'No data to interpret.',
          textStyle: txt(size: 14, weight: FontWeight.w500, color: Colors.black87),
        ),
      );
    }

    final analysis = _analyzeOperation(op!);
    final color = switch (analysis.status) {
      _MoistureStatus.tooDry => warn,
      _MoistureStatus.ok => ok,
      _MoistureStatus.tooWet => danger,
    };

    return _SectionCard(
      title: 'Interpretation',
      titleStyle: txt(size: 16, weight: FontWeight.w700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  analysis.headline,
                  style: txt(size: 14, weight: FontWeight.w700, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...analysis.points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(p, style: txt(size: 13, weight: FontWeight.w500, color: Colors.black87))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.recommendation,
            style: txt(size: 13, weight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

_AnalysisResult _analyzeOperation(OperationRecord op) {
  final r = op.readings;
  final n = r.length;
  final values = r.map((e) => e.value).toList();
  final avg = values.reduce((a, b) => a + b) / n;
  final minV = values.reduce((a, b) => a < b ? a : b);
  final maxV = values.reduce((a, b) => a > b ? a : b);
  final first = values.first;
  final last = values.last;
  final delta = last - first;

  final trend = delta.abs() < 1.0 ? 'stable' : (delta > 0 ? 'rising' : 'falling');

  final dur = op.duration;
  final durText = (dur == null)
      ? '—'
      : '${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  const low = 12.0;
  const high = 18.0;

  final status = avg < low
      ? _MoistureStatus.tooDry
      : (avg > high ? _MoistureStatus.tooWet : _MoistureStatus.ok);

  final headline = switch (status) {
    _MoistureStatus.tooDry => 'Soil is DRY overall',
    _MoistureStatus.ok => 'Moisture is within the target range',
    _MoistureStatus.tooWet => 'Soil is TOO WET overall',
  };

  final points = <String>[
    'Average moisture: ${avg.toStringAsFixed(1)}%',
    'Range: ${minV.toStringAsFixed(1)}% – ${maxV.toStringAsFixed(1)}%',
    'Trend: $trend (Δ ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%)',
    'Duration: $durText',
    'Samples: $n',
  ];

  final recommendation = switch (status) {
    _MoistureStatus.tooDry =>
        'Recommendation: Consider watering soon to lift moisture above $low%.',
    _MoistureStatus.ok =>
        'Recommendation: Conditions look good (target is $low–$high%). Maintain current routine.',
    _MoistureStatus.tooWet =>
        'Recommendation: Reduce watering or allow drying until moisture falls below $high%.',
  };

  return _AnalysisResult(
    status: status,
    headline: headline,
    points: points,
    recommendation: recommendation,
  );
}
