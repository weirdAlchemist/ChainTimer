import 'package:chain_timer/models/timer_chain.dart';
import 'package:chain_timer/models/timer_step.dart';
import 'package:chain_timer/services/chain_run_controller.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

TimerChain _chain() => TimerChain(
      id: 'c1',
      name: 'Test',
      steps: const [
        TimerStep(id: 's1', label: 'A', duration: Duration(seconds: 2)),
        TimerStep(id: 's2', label: 'B', duration: Duration(seconds: 3)),
      ],
    );

void main() {
  test('runs steps in sequence and finishes', () {
    fakeAsync((async) {
      final controller = ChainRunController(_chain());
      var advances = 0;
      var finished = false;
      controller.onStepAdvance = () => advances++;
      controller.onFinished = () => finished = true;
      controller.start();

      expect(controller.index, 0);
      expect(controller.isRunning, isTrue);

      // Finish the first step.
      async.elapse(const Duration(seconds: 2, milliseconds: 200));
      expect(controller.index, 1);
      expect(advances, 1);
      expect(finished, isFalse);

      // Finish the second (final) step.
      async.elapse(const Duration(seconds: 3, milliseconds: 200));
      expect(controller.isFinished, isTrue);
      expect(finished, isTrue);

      controller.dispose();
    });
  });

  test('pause halts the countdown', () {
    fakeAsync((async) {
      final controller = ChainRunController(_chain())..start();
      async.elapse(const Duration(milliseconds: 600));
      controller.pause();
      final remainingAtPause = controller.remaining;
      async.elapse(const Duration(seconds: 5));
      expect(controller.remaining, remainingAtPause);
      expect(controller.isPaused, isTrue);
      expect(controller.index, 0);
      controller.dispose();
    });
  });

  test('skipToNext advances without firing the advance cue', () {
    fakeAsync((async) {
      final controller = ChainRunController(_chain());
      var advances = 0;
      controller.onStepAdvance = () => advances++;
      controller.start();
      controller.skipToNext();
      expect(controller.index, 1);
      expect(advances, 0);
      controller.dispose();
    });
  });

  test('previous restarts the current step mid-run', () {
    fakeAsync((async) {
      final controller = ChainRunController(_chain())..start();
      async.elapse(const Duration(milliseconds: 1500));
      controller.skipToNext(); // now on step 2 (3s)
      expect(controller.index, 1);
      async.elapse(const Duration(seconds: 2)); // 2s into step 2
      controller.previous(); // >2s elapsed, so restart current step
      expect(controller.index, 1);
      expect(controller.remaining, const Duration(seconds: 3));
      controller.dispose();
    });
  });
}
