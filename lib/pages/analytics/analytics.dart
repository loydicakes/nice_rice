// lib/pages/analytics/analytics.dart
import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nice_rice/header.dart';
import 'package:intl/intl.dart';

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
/// Your automation.dart will call: startOperation(), logReading(), endOperation()
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
    if (op == null) return; // ignore if not found
    op.readings.add(MoistureReading(at ?? DateTime.now(), moisture));
  }

  void endOperation(String opId) {
    final op = getById(opId);
    if (op == null) return;
    op.endedAt ??= DateTime.now();
  }

  @override
  OperationRecord? getById(String id) => _ops
      .cast<OperationRecord?>()
      .firstWhere((o) => o!.id == id, orElse: () => null);

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
  String? _selectedOpId;

  @override
  Widget build(BuildContext context) {
    final ops = OperationHistory.instance.operations;
    final OperationRecord? selected = _selectedOpId == null
        ? (ops.isNotEmpty ? ops.first : null)
        : OperationHistory.instance.getById(_selectedOpId!);

    _selectedOpId ??= selected?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (ops.isEmpty)
              const _EmptyState(
                message:
                    'No completed operations yet.\nRun one in Automation to build history.',
              )
            else ...[
              _OperationPicker(
                ops: ops,
                selectedId: _selectedOpId!,
                onChanged: (id) => setState(() => _selectedOpId = id),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Moisture Content',
                child: selected == null || selected.readings.length < 2
                    ? const _EmptyState(message: 'Not enough data points.')
                    : _MoistureChart(readings: selected.readings),
              ),
              const SizedBox(height: 12),
              _InfoFooter(op: selected),
              const SizedBox(height: 12),
              // 👇 NEW: Farmer-friendly interpretation card
              _InterpretationCard(op: selected),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------ UI Parts ------------
class _OperationPicker extends StatelessWidget {
  final UnmodifiableListView<OperationRecord> ops;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _OperationPicker({
    required this.ops,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.history, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  items: ops
                      .map(
                        (op) => DropdownMenuItem(
                          value: op.id,
                          child: Text(
                            op.displayTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
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
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}

class _MoistureChart extends StatelessWidget {
  final List<MoistureReading> readings;
  const _MoistureChart({required this.readings});

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
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (xMax - xMin) / 4.0,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    xLabel(v),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: ((yMax - yMin) / 5).clamp(1, 100).toDouble(),
                getTitlesWidget: (v, m) => Text(
                  v.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoFooter extends StatelessWidget {
  final OperationRecord? op;
  const _InfoFooter({required this.op});

  @override
  Widget build(BuildContext context) {
    if (op == null) return const SizedBox.shrink();
    final df = DateFormat('MMM d, HH:mm:ss');
    final start = df.format(op!.startedAt);
    final end = op!.endedAt == null ? '—' : df.format(op!.endedAt!);
    final points = op!.readings.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Started: $start • Ended: $end • Points: $points',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// ------------ NEW: Interpretation Card ------------
class _InterpretationCard extends StatelessWidget {
  final OperationRecord? op;
  const _InterpretationCard({required this.op});

  @override
  Widget build(BuildContext context) {
    if (op == null || op!.readings.isEmpty) {
      return const _SectionCard(
        title: 'Interpretation',
        child: _EmptyState(message: 'No data to interpret.'),
      );
    }

    final analysis = _analyzeOperation(op!);

    final color = switch (analysis.status) {
      _MoistureStatus.tooDry => Colors.orange,
      _MoistureStatus.ok => Colors.green,
      _MoistureStatus.tooWet => Colors.red,
    };

    return _SectionCard(
      title: 'Interpretation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                analysis.headline,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                  Expanded(child: Text(p)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.recommendation,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Simple moisture ranges (adjust as needed):
/// - Target band: 12–18%
/// - <12% : too dry
/// - >18% : too wet
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

  // Trend by delta between first and last
  final trend = delta.abs() < 1.0
      ? 'stable'
      : (delta > 0 ? 'rising' : 'falling');

  // Duration text
  final dur = op.duration;
  final durText = (dur == null)
      ? '—'
      : '${dur.inMinutes.remainder(60).toString().padLeft(2, '0')}:${dur.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  // Status thresholds
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
