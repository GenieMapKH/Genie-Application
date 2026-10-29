import 'package:flutter/material.dart';

/// The bars of a voice message: [levels] from 0 to 1, drawn in [playedColor]
/// up to [progress] (0 to 1) and in [color] after it. With [onSeek], tapping
/// or dragging along the bars reports where, as a fraction of the length.
class VoiceWaveform extends StatelessWidget {
  final List<double> levels;
  final double progress;
  final Color color;
  final Color playedColor;
  final ValueChanged<double>? onSeek;
  final double height;

  const VoiceWaveform({
    super.key,
    required this.levels,
    required this.color,
    Color? playedColor,
    this.progress = 0,
    this.onSeek,
    this.height = 28,
  }) : playedColor = playedColor ?? color;

  @override
  Widget build(BuildContext context) {
    final bars = CustomPaint(
      size: Size(double.infinity, height),
      painter: _WaveformPainter(
        levels: levels,
        progress: progress,
        color: color,
        playedColor: playedColor,
      ),
    );
    final onSeek = this.onSeek;
    if (onSeek == null) return bars;

    return LayoutBuilder(
      builder: (context, constraints) {
        void seekTo(double dx) =>
            onSeek((dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => seekTo(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => seekTo(details.localPosition.dx),
          child: bars,
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  static const _gap = 2.0;
  static const _minBar = 2.0;

  final List<double> levels;
  final double progress;
  final Color color;
  final Color playedColor;

  const _WaveformPainter({
    required this.levels,
    required this.progress,
    required this.color,
    required this.playedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final slot = size.width / levels.length;
    final width = (slot - _gap).clamp(1.0, 4.0);
    final played = Paint()..color = playedColor;
    final unplayed = Paint()..color = color;

    for (var i = 0; i < levels.length; i++) {
      final barHeight = (_minBar + levels[i].clamp(0.0, 1.0) * size.height)
          .clamp(_minBar, size.height);
      final x = i * slot + (slot - width) / 2;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - barHeight) / 2, width, barHeight),
        Radius.circular(width / 2),
      );
      canvas.drawRRect(
        bar,
        (i + 0.5) / levels.length <= progress ? played : unplayed,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.levels != levels ||
      old.color != color ||
      old.playedColor != playedColor;
}
