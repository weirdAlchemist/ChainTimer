import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timer_chain.dart';
import '../models/timer_step.dart';
import '../providers/chains_provider.dart';
import '../utils/format.dart';
import '../utils/id.dart';
import 'chain_editor_screen.dart';
import 'run_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createChain(BuildContext context) async {
    final draft = TimerChain(
      id: newId(),
      name: '',
      steps: [
        TimerStep(id: newId(), label: 'Timer 1', duration: const Duration(minutes: 1)),
      ],
    );
    final result = await Navigator.of(context).push<TimerChain>(
      MaterialPageRoute(
        builder: (_) => ChainEditorScreen(chain: draft, isNew: true),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<ChainsProvider>().upsert(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChainTimer'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createChain(context),
        icon: const Icon(Icons.add),
        label: const Text('New chain'),
      ),
      body: Consumer<ChainsProvider>(
        builder: (context, provider, _) {
          if (!provider.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final chains = provider.chains;
          if (chains.isEmpty) {
            return const _EmptyState();
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: chains.length,
            onReorder: provider.reorder,
            itemBuilder: (context, index) {
              final chain = chains[index];
              return _ChainCard(
                key: ValueKey(chain.id),
                chain: chain,
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChainCard extends StatelessWidget {
  const _ChainCard({
    required this.chain,
    required this.index,
    super.key,
  });

  final TimerChain chain;
  final int index;

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<TimerChain>(
      MaterialPageRoute(
        builder: (_) => ChainEditorScreen(chain: chain, isNew: false),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<ChainsProvider>().upsert(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chain?'),
        content: Text('"${chain.name.isEmpty ? 'Untitled' : chain.name}" '
            'will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ChainsProvider>().delete(chain.id);
    }
  }

  void _run(BuildContext context) {
    if (chain.steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a timer before running this chain.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RunScreen(chain: chain)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = chain.name.isEmpty ? 'Untitled chain' : chain.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _run(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${chain.steps.length} '
                        '${chain.steps.length == 1 ? 'timer' : 'timers'}'
                        ' · ${formatDurationLong(chain.totalDuration)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _edit(context);
                      case 'delete':
                        _confirmDelete(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.timer_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text('No chains yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create a chain of timers that run one after another — '
              'perfect for workouts, cooking, or focus sessions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
