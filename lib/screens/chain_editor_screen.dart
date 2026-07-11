import 'package:flutter/material.dart';

import '../models/timer_chain.dart';
import '../models/timer_step.dart';
import '../utils/format.dart';
import '../utils/id.dart';
import '../widgets/duration_picker_sheet.dart';

/// Create or edit a [TimerChain]. Pops with the edited chain, or `null` if the
/// user backs out without saving.
class ChainEditorScreen extends StatefulWidget {
  const ChainEditorScreen({
    super.key,
    required this.chain,
    required this.isNew,
  });

  final TimerChain chain;
  final bool isNew;

  @override
  State<ChainEditorScreen> createState() => _ChainEditorScreenState();
}

class _ChainEditorScreenState extends State<ChainEditorScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.chain.name);
  late final List<TimerStep> _steps = List.of(widget.chain.steps);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Duration get _total =>
      _steps.fold(Duration.zero, (sum, s) => sum + s.duration);

  Future<void> _addStep() async {
    final duration = await showDurationPicker(
      context,
      initial: const Duration(minutes: 1),
      title: 'New timer duration',
    );
    if (duration == null) return;
    setState(() {
      _steps.add(TimerStep(
        id: newId(),
        label: 'Timer ${_steps.length + 1}',
        duration: duration,
      ));
    });
  }

  Future<void> _editDuration(int index) async {
    final step = _steps[index];
    final duration = await showDurationPicker(
      context,
      initial: step.duration,
      title: 'Edit duration',
    );
    if (duration == null) return;
    setState(() => _steps[index] = step.copyWith(duration: duration));
  }

  Future<void> _editLabel(int index) async {
    final step = _steps[index];
    final controller = TextEditingController(text: step.label);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Warm up'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null) return;
    setState(() => _steps[index] = step.copyWith(label: label.trim()));
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  void _save() {
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one timer.')),
      );
      return;
    }
    final name = _nameController.text.trim();
    final result = widget.chain.copyWith(
      name: name.isEmpty ? 'Untitled chain' : name,
      steps: _steps,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New chain' : 'Edit chain'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Chain name',
                hintText: 'e.g. Morning workout',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_steps.length} ${_steps.length == 1 ? 'timer' : 'timers'}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total ${formatDurationLong(_total)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _steps.isEmpty
                ? Center(
                    child: Text(
                      'Tap "Add timer" to start building your chain.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: _steps.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _StepTile(
                        key: ValueKey(step.id),
                        index: index,
                        step: step,
                        onEditLabel: () => _editLabel(index),
                        onEditDuration: () => _editDuration(index),
                        onRemove: () => _removeStep(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStep,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add timer'),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    super.key,
    required this.index,
    required this.step,
    required this.onEditLabel,
    required this.onEditDuration,
    required this.onRemove,
  });

  final int index;
  final TimerStep step;
  final VoidCallback onEditLabel;
  final VoidCallback onEditDuration;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = step.label.isEmpty ? 'Timer ${index + 1}' : step.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onEditLabel,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          label,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onEditDuration,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatDurationLong(step.duration),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
