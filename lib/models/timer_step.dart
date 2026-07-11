import 'package:flutter/foundation.dart';

/// A single timer within a [TimerChain]: a human-readable [label] and a
/// [duration] to count down.
@immutable
class TimerStep {
  const TimerStep({
    required this.id,
    required this.label,
    required this.duration,
  });

  final String id;
  final String label;
  final Duration duration;

  TimerStep copyWith({String? label, Duration? duration}) {
    return TimerStep(
      id: id,
      label: label ?? this.label,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'seconds': duration.inSeconds,
      };

  factory TimerStep.fromJson(Map<String, dynamic> json) => TimerStep(
        id: json['id'] as String,
        label: (json['label'] as String?) ?? '',
        duration: Duration(seconds: (json['seconds'] as num?)?.toInt() ?? 0),
      );

  @override
  bool operator ==(Object other) =>
      other is TimerStep &&
      other.id == id &&
      other.label == label &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(id, label, duration);
}
