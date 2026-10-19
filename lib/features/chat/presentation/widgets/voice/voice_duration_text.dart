/// "0:07", "1:23": how a voice message's length or position is written.
String voiceDurationText(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
