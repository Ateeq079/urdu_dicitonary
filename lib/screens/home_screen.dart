import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'challenge_screen.dart';
import 'translator_screen.dart';
import 'word_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSearchTap});

  /// Called when the search bar is tapped (switches to the Search tab).
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                Text('لغت',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text('Lughat',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            Text('Urdu ⇄ English dictionary',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 16),

            // Fake search bar -> opens search tab
            GestureDetector(
              onTap: onSearchTap,
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Urdu or English…',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _WordOfDayCard(word: state.wordOfDay),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.school_rounded,
                    title: 'Daily Challenge',
                    subtitle:
                        '${state.challengeLearnedToday}/5 learned today',
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ChallengeScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.translate_rounded,
                    title: 'Translator',
                    subtitle: 'EN ⇄ UR offline-aware',
                    color: theme.colorScheme.tertiary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TranslatorScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.recents.isNotEmpty) ...[
              Text('Recent', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...state.recents.take(5).map((r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: r.lang == 'ur'
                          ? UrduText(r.word,
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 20))
                          : Text(r.word),
                      onTap: () => openWord(context, r.word, r.lang),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.word});
  final SeedWord word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final ref = WordRef(word: word.urdu, lang: 'ur', gloss: word.english);
    final fav = state.isFavorite(ref);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openWord(context, word.urdu, 'ur'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text('WORD OF THE DAY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        letterSpacing: 1.2,
                      )),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav
                            ? Colors.redAccent
                            : theme.colorScheme.onPrimaryContainer),
                    onPressed: () =>
                        context.read<AppState>().toggleFavorite(ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              UrduText(word.urdu,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              Text('${word.english}  ·  ${word.roman}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}
