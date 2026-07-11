import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/timer_chain.dart';
import '../services/chain_run_controller.dart';
import '../utils/format.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.chain});

  final TimerChain chain;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  late final ChainRunController _controller = ChainRunController(widget.chain)
    ..onStepAdvance = _onStepAdvance
    ..onFinished = _onFinished;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  void _onStepAdvance() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _onFinished() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    await Future.delayed(const Duration(milliseconds: 250));
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chain.name.isEmpty ? 'Running' : widget.chain.name),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isFinished) {
              return _FinishedView(
                chain: widget.chain,
                onRestart: _controller.restart,
                onDone: () => Navigator.of(context).pop(),
              );
            }
            return _RunningView(controller: _controller, theme: theme);
          },
        ),
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({required this.controller, required this.theme});

  final ChainRunController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final next = controller.nextStep;
    final label = controller.currentStep.label.isEmpty
        ? 'Timer ${controller.index + 1}'
        : controller.currentStep.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Overall chain progress.
          Row(
            children: [
              Text(
                'Step ${controller.index + 1} of ${controller.stepCount}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Total ${formatDuration(controller.chain.totalDuration)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.overallProgress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const Spacer(),
          // Big countdown ring.
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1 - controller.stepProgress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          controller.isPaused ? scheme.outline : scheme.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatDuration(controller.remaining),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (controller.isPaused)
                          Text(
                            'Paused',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // Up next hint.
          SizedBox(
            height: 28,
            child: next == null
                ? Text(
                    'Last timer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Text(
                    'Up next · ${next.label.isEmpty ? "Timer ${controller.index + 2}" : next.label} '
                    '(${formatDuration(next.duration)})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(height: 16),
          // Controls.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundButton(
                icon: Icons.skip_previous,
                tooltip: 'Previous / restart step',
                onPressed: controller.previous,
              ),
              _PlayPauseButton(
                isPaused: controller.isPaused,
                onPressed: controller.togglePause,
              ),
              _RoundButton(
                icon: Icons.skip_next,
                tooltip: 'Skip',
                onPressed: controller.skipToNext,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.restart,
            icon: const Icon(Icons.replay),
            label: const Text('Restart chain'),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPaused, required this.onPressed});

  final bool isPaused;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 84,
      height: 84,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: scheme.primary,
        ),
        onPressed: onPressed,
        child: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          size: 40,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      height: 64,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.chain,
    required this.onRestart,
    required this.onDone,
  });

  final TimerChain chain;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Chain complete!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${chain.steps.length} timers · '
              '${formatDurationLong(chain.totalDuration)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay),
                  label: const Text('Run again'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
