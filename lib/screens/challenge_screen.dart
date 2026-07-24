import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../models/spaced_repetition_entry.dart';
import '../state/app_state.dart';
import '../state/challenge_state.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ur-PK');
    _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) => _tts.speak(text);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final challenge = context.watch<ChallengeState>();
    final words = state.challengeWords;
    final done = state.challengeLearnedToday;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dueReviews = challenge.dueToday;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge & Review')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ── Daily progress card ─────────────────────────────────────────
          Card(
            color: scheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learn 5 new words today',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: words.isEmpty ? 0 : done / words.length,
                      minHeight: 10,
                      backgroundColor: scheme.onPrimaryContainer
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$done of ${words.length} learned   ·   ${state.learnedTotal} total all-time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Review queue (spaced repetition) ────────────────────────────
          if (dueReviews.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.replay_circle_filled_rounded,
                    size: 18, color: scheme.tertiary),
                const SizedBox(width: 8),
                Text('Review (${dueReviews.length} due today)',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ...dueReviews
                .map((e) => _ReviewCard(entry: e, onSpeak: _speak)),
            const SizedBox(height: 20),
          ],

          // ── Today's 5 challenge words ────────────────────────────────────
          Row(
            children: [
              Icon(Icons.school_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text("Today's Words", style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...words.map((w) => _ChallengeTile(word: w, onSpeak: _speak)),
        ],
      ),
    );
  }
}

// ── Review card (spaced repetition) ──────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.entry, required this.onSpeak});
  final SpacedRepetitionEntry entry;
  final Future<void> Function(String) onSpeak;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final challenge = context.read<ChallengeState>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: scheme.tertiaryContainer,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urdu word + TTS
            Row(
              children: [
                Expanded(
                  child: UrduText(
                    widget.entry.urdu,
                    textAlign: TextAlign.left,
                    semanticsLabel: widget.entry.english,
                    style: const TextStyle(
                        fontSize: 28, height: UrduType.headHeight),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  tooltip: 'Pronounce',
                  onPressed: () => widget.onSpeak(widget.entry.urdu),
                ),
              ],
            ),

            // Reveal / answer row
            if (!_revealed)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _revealed = true),
                  child: const Text('Show answer'),
                ),
              )
            else ...[
              const SizedBox(height: 4),
              Text(
                widget.entry.roman,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant),
              ),
              Text(
                widget.entry.english,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Easy / Hard buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sentiment_dissatisfied_rounded),
                      label: const Text('Hard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      onPressed: () {
                        challenge.markHard(widget.entry);
                        setState(() => _revealed = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.sentiment_satisfied_rounded),
                      label: const Text('Easy'),
                      onPressed: () {
                        challenge.markEasy(widget.entry);
                        setState(() => _revealed = false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Daily challenge tile ──────────────────────────────────────────────────────

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.word, required this.onSpeak});
  final SeedWord word;
  final Future<void> Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final learned = state.isLearned(word);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: UrduText(
          word.urdu,
          textAlign: TextAlign.left,
          semanticsLabel: '${word.english}, ${word.roman}',
          style: const TextStyle(fontSize: 24, height: UrduType.bodyHeight),
        ),
        subtitle: Text('${word.english}  ·  ${word.roman}'),
        leading: IconButton(
          iconSize: 30,
          icon: Icon(
            learned
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: learned ? scheme.primary : scheme.outline,
          ),
          onPressed: () => context.read<AppState>().toggleLearned(word),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up_outlined),
              tooltip: 'Pronounce',
              onPressed: () => onSpeak(word.urdu),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Look up',
              onPressed: () => openWord(context, word.urdu, 'ur'),
            ),
          ],
        ),
        onTap: () => context.read<AppState>().toggleLearned(word),
      ),
    );
  }
}
