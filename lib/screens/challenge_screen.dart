import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final words = state.challengeWords;
    final done = state.challengeLearnedToday;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learn 5 new words today',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: words.isEmpty ? 0 : done / words.length,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$done of ${words.length} learned   ·   ${state.learnedTotal} total all-time',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...words.map((w) => _ChallengeTile(word: w)),
        ],
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.word});
  final SeedWord word;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final learned = state.isLearned(word);
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: UrduText(word.urdu,
            textAlign: TextAlign.left, style: const TextStyle(fontSize: 24)),
        subtitle: Text('${word.english}  ·  ${word.roman}'),
        leading: IconButton(
          iconSize: 30,
          icon: Icon(
            learned
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: learned ? Colors.green : theme.colorScheme.outline,
          ),
          onPressed: () => context.read<AppState>().toggleLearned(word),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: () => openWord(context, word.urdu, 'ur'),
        ),
        onTap: () => context.read<AppState>().toggleLearned(word),
      ),
    );
  }
}
