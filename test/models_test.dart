import 'package:chain_timer/models/timer_chain.dart';
import 'package:chain_timer/models/timer_step.dart';
import 'package:chain_timer/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerChain', () {
    final chain = TimerChain(
      id: 'c1',
      name: 'Workout',
      steps: const [
        TimerStep(id: 's1', label: 'Warm up', duration: Duration(seconds: 30)),
        TimerStep(id: 's2', label: 'Sprint', duration: Duration(minutes: 1)),
      ],
    );

    test('totalDuration sums step durations', () {
      expect(chain.totalDuration, const Duration(seconds: 90));
    });

    test('round-trips through JSON', () {
      final restored = TimerChain.fromJson(chain.toJson());
      expect(restored.id, chain.id);
      expect(restored.name, chain.name);
      expect(restored.steps.length, 2);
      expect(restored.steps[1].label, 'Sprint');
      expect(restored.steps[1].duration, const Duration(minutes: 1));
    });

    test('fromJson tolerates missing fields', () {
      final restored = TimerChain.fromJson({'id': 'x'});
      expect(restored.name, 'Untitled');
      expect(restored.steps, isEmpty);
    });
  });

  group('formatDuration', () {
    test('formats sub-hour durations as m:ss', () {
      expect(formatDuration(const Duration(minutes: 4, seconds: 5)), '4:05');
      expect(formatDuration(const Duration(seconds: 9)), '0:09');
    });

    test('formats hour-plus durations as h:mm:ss', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('clamps negatives to zero', () {
      expect(formatDuration(const Duration(seconds: -5)), '0:00');
    });
  });
}
