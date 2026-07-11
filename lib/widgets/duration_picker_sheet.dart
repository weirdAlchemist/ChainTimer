import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Shows a bottom sheet with an hours/minutes/seconds wheel picker and returns
/// the chosen [Duration], or `null` if dismissed.
Future<Duration?> showDurationPicker(
  BuildContext context, {
  required Duration initial,
  String title = 'Duration',
}) {
  return showModalBottomSheet<Duration>(
    context: context,
    showDragHandle: true,
    builder: (context) => _DurationPickerSheet(initial: initial, title: title),
  );
}

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({required this.initial, required this.title});

  final Duration initial;
  final String title;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late Duration _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              formatDurationLong(_value),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(
              height: 190,
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hms,
                initialTimerDuration: widget.initial,
                onTimerDurationChanged: (d) => setState(() => _value = d),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _value <= Duration.zero
                        ? null
                        : () => Navigator.pop(context, _value),
                    child: const Text('Set'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
