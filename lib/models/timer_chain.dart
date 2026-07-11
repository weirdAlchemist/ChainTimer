import 'package:flutter/foundation.dart';

import 'timer_step.dart';

/// An ordered collection of [TimerStep]s that are run one after another.
@immutable
class TimerChain {
  const TimerChain({
    required this.id,
    required this.name,
    required this.steps,
  });

  final String id;
  final String name;
  final List<TimerStep> steps;

  /// Sum of every step's duration.
  Duration get totalDuration =>
      steps.fold(Duration.zero, (sum, s) => sum + s.duration);

  TimerChain copyWith({String? name, List<TimerStep>? steps}) => TimerChain(
        id: id,
        name: name ?? this.name,
        steps: steps ?? this.steps,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory TimerChain.fromJson(Map<String, dynamic> json) => TimerChain(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? 'Untitled',
        steps: ((json['steps'] as List<dynamic>?) ?? const [])
            .map((e) => TimerStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
