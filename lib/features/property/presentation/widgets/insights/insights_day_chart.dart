import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_insights.dart';

/// One bar per day for one measure, today last. Tapping a bar names its day
/// and count above the chart; the newest day is named until then.
class InsightsDayChart extends StatefulWidget {
  final List<InsightDay> days;
  final InsightMeasure measure;

  /// "3 viewers" for a count, in the reader's language.
  final String Function(int count) describe;

  const InsightsDayChart({
    super.key,
    required this.days,
    required this.measure,
    required this.describe,
  });

  static const double height = 140;

  @override
  State<InsightsDayChart> createState() => _InsightsDayChartState();
}

class _InsightsDayChartState extends State<InsightsDayChart> {
  int? _selected;

  @override
  void didUpdateWidget(InsightsDayChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) return const SizedBox(height: InsightsDayChart.height);
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat.MMMd(locale);
    final selected = _selected ?? days.length - 1;
    final values = [for (final day in days) day.valueOf(widget.measure)];
    final caption =
        '${dayFormat.format(days[selected].date)} · '
        '${widget.describe(values[selected])}';

    return Semantics(
      // The chart drawn as words, for screen readers.
      label: [
        for (var i = 0; i < days.length; i++)
          '${dayFormat.format(days[i].date)}: ${values[i]}',
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            caption,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: InsightsDayChart.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                void pick(Offset position) {
                  final slot = constraints.maxWidth / days.length;
                  final index = (position.dx / slot).floor();
                  setState(() => _selected = index.clamp(0, days.length - 1));
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => pick(details.localPosition),
                  onHorizontalDragUpdate: (details) =>
                      pick(details.localPosition),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, InsightsDayChart.height),
                    painter: _BarsPainter(
                      values: values,
                      selected: selected,
                      bar: colors.accent,
                      barQuiet: colors.accent.withValues(alpha: 0.45),
                      baseline: colors.border,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in [days.first, days.last])
                Text(
                  dayFormat.format(day.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thin bars from a hairline baseline, rounded at the top only, with space
/// between them. The selected day is full strength, the rest a
/// step quieter, so the eye finds the one named above.
class _BarsPainter extends CustomPainter {
  final List<int> values;
  final int selected;
  final Color bar;
  final Color barQuiet;
  final Color baseline;

  _BarsPainter({
    required this.values,
    required this.selected,
    required this.bar,
    required this.barQuiet,
    required this.baseline,
  });

  static const _gap = 2.0;
  static const _radius = Radius.circular(4);

  /// An empty day still shows where it is.
  static const _emptyHeight = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = values.fold(0, math.max);
    final slot = size.width / values.length;
    // Thin: never wider than 18 px, whatever the screen.
    final width = math.min(18.0, slot - _gap * 2);
    final floor = size.height - 1;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final height = peak == 0 || value == 0
          ? _emptyHeight
          : math.max(_emptyHeight, (floor - 4) * value / peak);
      final left = slot * i + (slot - width) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, floor - height, width, height),
          topLeft: _radius,
          topRight: _radius,
        ),
        Paint()..color = i == selected ? bar : barQuiet,
      );
    }
    canvas.drawLine(
      Offset(0, floor + 0.5),
      Offset(size.width, floor + 0.5),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.selected != selected ||
      old.bar != bar ||
      old.barQuiet != barQuiet ||
      old.baseline != baseline ||
      !_sameValues(old.values, values);

  static bool _sameValues(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
