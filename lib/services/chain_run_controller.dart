import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../models/timer_chain.dart';
import '../models/timer_step.dart';

enum RunStatus { idle, running, paused, finished }

/// Drives a [TimerChain] through its steps in sequence.
///
/// Timekeeping is anchored to the wall clock (a target [_deadline]) rather than
/// accumulated tick counts, so the countdown stays accurate even if the ticker
/// fires irregularly.
class ChainRunController extends ChangeNotifier {
  ChainRunController(this.chain);

  final TimerChain chain;

  Timer? _ticker;
  int _index = 0;
  Duration _remaining = Duration.zero;
  DateTime? _deadline;
  RunStatus _status = RunStatus.idle;

  /// Invoked when a step finishes naturally and the next one begins.
  VoidCallback? onStepAdvance;

  /// Invoked when the final step finishes naturally.
  VoidCallback? onFinished;

  RunStatus get status => _status;
  int get index => _index;
  int get stepCount => chain.steps.length;
  bool get isRunning => _status == RunStatus.running;
  bool get isPaused => _status == RunStatus.paused;
  bool get isFinished => _status == RunStatus.finished;

  TimerStep get currentStep => chain.steps[_index];
  TimerStep? get nextStep =>
      _index + 1 < chain.steps.length ? chain.steps[_index + 1] : null;
  Duration get remaining => _remaining;

  /// Progress of the current step in the range 0..1.
  double get stepProgress {
    final total = currentStep.duration.inMilliseconds;
    if (total <= 0) return 1;
    final done = total - _remaining.inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  /// Time elapsed across the whole chain up to now.
  Duration get elapsedOverall {
    var d = Duration.zero;
    for (var i = 0; i < _index; i++) {
      d += chain.steps[i].duration;
    }
    if (_index < chain.steps.length) {
      d += currentStep.duration - _remaining;
    }
    return d;
  }

  /// Progress across the whole chain in the range 0..1.
  double get overallProgress {
    final total = chain.totalDuration.inMilliseconds;
    if (total <= 0) return isFinished ? 1 : 0;
    return (elapsedOverall.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void start() {
    if (chain.steps.isEmpty) {
      _status = RunStatus.finished;
      notifyListeners();
      onFinished?.call();
      return;
    }
    _beginStep(0);
  }

  void _beginStep(int i) {
    _index = i;
    _remaining = chain.steps[i].duration;
    _startTicking();
  }

  void _startTicking() {
    _status = RunStatus.running;
    _deadline = clock.now().add(_remaining);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final left = deadline.difference(clock.now());
    if (left <= Duration.zero) {
      _remaining = Duration.zero;
      _advance();
    } else {
      _remaining = left;
      notifyListeners();
    }
  }

  void _advance({bool natural = true}) {
    _ticker?.cancel();
    if (_index + 1 < chain.steps.length) {
      if (natural) onStepAdvance?.call();
      _beginStep(_index + 1);
    } else {
      _status = RunStatus.finished;
      _deadline = null;
      _remaining = Duration.zero;
      notifyListeners();
      if (natural) onFinished?.call();
    }
  }

  void pause() {
    if (_status != RunStatus.running) return;
    _ticker?.cancel();
    final deadline = _deadline;
    _remaining = deadline == null
        ? _remaining
        : deadline.difference(clock.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
    _deadline = null;
    _status = RunStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != RunStatus.paused) return;
    _startTicking();
  }

  void togglePause() {
    if (isRunning) {
      pause();
    } else if (isPaused) {
      resume();
    }
  }

  /// Jumps to the next step (or finishes), without firing the advance cue.
  void skipToNext() {
    if (isFinished) return;
    _advance(natural: false);
  }

  /// Restarts the current step, or jumps to the previous one if it has only
  /// just begun.
  void previous() {
    if (isFinished) {
      _beginStep(chain.steps.length - 1);
      return;
    }
    final justStarted = currentStep.duration - _remaining < const Duration(seconds: 2);
    final target = (justStarted && _index > 0) ? _index - 1 : _index;
    _beginStep(target);
  }

  void restart() {
    _ticker?.cancel();
    _status = RunStatus.idle;
    start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
