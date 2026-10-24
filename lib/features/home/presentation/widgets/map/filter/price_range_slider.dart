import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/presentation/providers/map_filter_draft_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/filter/price_histogram.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/l10n/l10n.dart';

/// The price histogram over a two-thumb slider, with a bubble naming the
/// range while a thumb moves. A null end means "no limit".
class PriceRangeSlider extends StatefulWidget {
  final MapPriceScale scale;
  final double? min;
  final double? max;
  final List<int> counts;
  final void Function(double? min, double? max) onChanged;

  const PriceRangeSlider({
    super.key,
    required this.scale,
    required this.min,
    required this.max,
    required this.counts,
    required this.onChanged,
  });

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  bool _dragging = false;

  RangeValues get _values {
    final top = widget.scale.top;
    final start = (widget.min ?? 0).clamp(0, top).toDouble();
    final end = (widget.max ?? top).clamp(start, top).toDouble();
    return RangeValues(start, end);
  }

  void _onChanged(RangeValues values) {
    double snap(double v) =>
        (v / widget.scale.step).round() * widget.scale.step;
    final start = snap(values.start);
    final end = snap(values.end);
    widget.onChanged(
      start <= 0 ? null : start,
      end >= widget.scale.top ? null : end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final values = _values;
    final top = widget.scale.top;

    return Column(
      children: [
        SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                // Lines the bars up with the slider's track, which starts
                // and ends a thumb's radius in.
                padding: const EdgeInsets.symmetric(
                  horizontal: _OutlinedThumb._radius,
                ),
                child: PriceHistogram(
                  counts: widget.counts,
                  from: values.start / top,
                  to: values.end / top,
                  litColor: colors.primary,
                  dimColor: colors.border,
                ),
              ),
              if (_dragging)
                Align(
                  alignment: Alignment.topCenter,
                  child: _RangeBubble(_label(context)),
                ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.border,
            overlayShape: SliderComponentShape.noOverlay,
            rangeThumbShape: _OutlinedThumb(colors.surface, colors.border),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: RangeSlider(
            values: values,
            max: top,
            divisions: widget.scale.divisions,
            onChangeStart: (_) => setState(() => _dragging = true),
            onChangeEnd: (_) => setState(() => _dragging = false),
            onChanged: _onChanged,
          ),
        ),
      ],
    );
  }

  /// "Price: $10K – $200K", or "Price: Any/month" for rent with no limits.
  String _label(BuildContext context) {
    final l10n = context.l10n;
    final top = widget.scale.top;
    final range = widget.min == null && widget.max == null
        ? l10n.filterPriceAny
        : '${PropertyFormat.shortMoney(widget.min ?? 0)} – '
              '${widget.max == null ? '${PropertyFormat.shortMoney(top)}+' : PropertyFormat.shortMoney(widget.max!)}';
    final label = l10n.filterPriceLabel(range);
    return widget.scale.perMonth ? l10n.filterPerMonth(label) : label;
  }
}

class _RangeBubble extends StatelessWidget {
  final String text;

  const _RangeBubble(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
      ),
    );
  }
}

/// A plain thumb with a thin ring, as in the design.
class _OutlinedThumb extends RangeSliderThumbShape {
  final Color fill;
  final Color ring;

  const _OutlinedThumb(this.fill, this.ring);

  static const _radius = 10.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center + const Offset(0, 1),
      _radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, _radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      _radius - 0.5,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke,
    );
  }
}
