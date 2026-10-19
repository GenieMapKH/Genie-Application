import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The loudness of a recording as it is made: bars that slide in from the
/// right at a steady pace, the newest growing to its height, instead of all
/// jumping one place at every sample.
class LiveVoiceWaveform extends StatefulWidget {
  /// The latest loudness samples, oldest first, 0 to 1. A new list means a
  /// new sample arrived.
  final List<double> levels;

  /// How many bars fill the width.
  final int capacity;

  /// How often a sample arrives: the time one bar takes to slide one place.
  final Duration sampleInterval;

  /// False freezes the bars (the recording stopped).
  final bool moving;

  final Color color;
  final double height;

  const LiveVoiceWaveform({
    super.key,
    required this.levels,
    required this.capacity,
    required this.sampleInterval,
    required this.color,
    this.moving = true,
    this.height = 24,
  });

  /// Each bar eased with the two before it, so the line rises and falls
  /// instead of flickering. Uses only earlier samples: a bar never changes
  /// once drawn. Exposed for tests.
  static List<double> smoothed(List<double> levels) {
    return [
      for (var i = 0; i < levels.length; i++)
        (0.5 * levels[i] +
                0.3 * (i > 0 ? levels[i - 1] : levels[i]) +
                0.2 * (i > 1 ? levels[i - 2] : levels[i]))
            .clamp(0.0, 1.0),
    ];
  }

  @override
  State<LiveVoiceWaveform> createState() => _LiveVoiceWaveformState();
}

class _LiveVoiceWaveformState extends State<LiveVoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// How far, 0 to 1, the bars have slid since the latest sample.
  final _slide = ValueNotifier<double>(1);
  Duration _clock = Duration.zero;
  Duration _sampleAt = Duration.zero;
  late List<double> _bars = LiveVoiceWaveform.smoothed(widget.levels);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame);
    if (widget.moving) _ticker.start();
  }

  @override
  void didUpdateWidget(LiveVoiceWaveform old) {
    super.didUpdateWidget(old);
    if (!identical(widget.levels, old.levels)) {
      _bars = LiveVoiceWaveform.smoothed(widget.levels);
      _sampleAt = _clock;
      _slide.value = 0;
    }
    if (widget.moving && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.moving && _ticker.isActive) {
      _ticker.stop();
      _slide.value = 1;
    }
  }

  void _onFrame(Duration elapsed) {
    _clock = elapsed;
    final interval = widget.sampleInterval.inMicroseconds;
    _slide.value = ((elapsed - _sampleAt).inMicroseconds / interval).clamp(
      0.0,
      1.0,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _LiveWaveformPainter(
          bars: _bars,
          capacity: widget.capacity,
          slide: _slide,
          color: widget.color,
        ),
      ),
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  static const _gap = 2.0;
  static const _minBar = 2.0;

  final List<double> bars;
  final int capacity;
  final ValueNotifier<double> slide;
  final Color color;

  _LiveWaveformPainter({
    required this.bars,
    required this.capacity,
    required this.slide,
    required this.color,
  }) : super(repaint: slide);

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty || capacity <= 0) return;
    final slot = size.width / capacity;
    final width = (slot - _gap).clamp(1.0, 4.0);
    final paint = Paint()..color = color;
    final t = Curves.easeOut.transform(slide.value);
    final newest = bars.length - 1;

    for (var i = 0; i < bars.length; i++) {
      final fromRight = newest - i;
      // The newest bar enters from just past the right edge; every bar
      // reaches its place as the next sample arrives.
      final centre = size.width - slot / 2 - fromRight * slot + (1 - t) * slot;
      if (centre < -slot) continue;
      final level = i == newest ? bars[i] * t : bars[i];
      final barHeight = (_minBar + level * (size.height - _minBar)).clamp(
        _minBar,
        size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centre, size.height / 2),
            width: width,
            height: barHeight,
          ),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveWaveformPainter old) =>
      !identical(old.bars, bars) ||
      old.capacity != capacity ||
      old.color != color ||
      old.slide != slide;
}
