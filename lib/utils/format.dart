/// Formats a [Duration] as `m:ss`, or `h:mm:ss` once it reaches an hour.
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final mm = minutes.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}

/// A more verbose form used in summaries, e.g. `1h 05m 30s`, `4m 30s`, `45s`.
String formatDurationLong(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  final parts = <String>[];
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0) parts.add('${minutes.toString().padLeft(hours > 0 ? 2 : 1, '0')}m');
  if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');
  return parts.join(' ');
}
