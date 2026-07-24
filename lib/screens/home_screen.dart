import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../services/connectivity_service.dart';
import '../state/app_state.dart';
import '../state/challenge_state.dart';
import '../theme.dart';
import 'challenge_screen.dart';
import 'settings_screen.dart';
import 'translator_screen.dart';
import 'word_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSearchTap});

  /// Called when the search bar is tapped (switches to the Search tab).
  final VoidCallback onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ur-PK');
    _tts.setSpeechRate(0.5);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _speak(String text) async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final connectivity = context.watch<ConnectivityService>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              children: [
                Text('لغت',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text('Lughat',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.outline)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            Text('Urdu ⇄ English dictionary',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.outline)),
            const SizedBox(height: 12),

            // ── Connectivity banner ───────────────────────────────────────
            if (!connectivity.isOnline)
              _ConnectivityBanner(),

            const SizedBox(height: 8),

            // ── Fake search bar → opens search tab ────────────────────────
            GestureDetector(
              onTap: widget.onSearchTap,
              child: AbsorbPointer(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search Urdu or English…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Word of the Day 2.0 ───────────────────────────────────────
            _WordOfDayCard(
              word: state.wordOfDay,
              speaking: _speaking,
              onSpeak: _speak,
            ),
            const SizedBox(height: 16),

            // ── Action cards row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.school_rounded,
                    title: 'Daily Challenge',
                    subtitle:
                        '${state.challengeLearnedToday}/5 learned today',
                    color: scheme.primary,
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
                    color: scheme.tertiary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TranslatorScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Recent searches ───────────────────────────────────────────
            if (state.recents.isNotEmpty) ...[
              Text('Recent', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...state.recents.take(5).map((r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: r.lang == 'ur'
                          ? UrduText(
                              r.word,
                              textAlign: TextAlign.left,
                              semanticsLabel: r.gloss.isNotEmpty
                                  ? r.gloss
                                  : r.word,
                              style: AppTheme.urduListStyle(context),
                            )
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

// ── Connectivity banner ───────────────────────────────────────────────────────

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline — showing saved words',
              style: TextStyle(
                  color: scheme.onTertiaryContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Word of the Day 2.0 card ──────────────────────────────────────────────────

class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({
    required this.word,
    required this.speaking,
    required this.onSpeak,
  });

  final SeedWord word;
  final bool speaking;
  final Future<void> Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<AppState>();
    final challenge = context.watch<ChallengeState>();
    final ref = WordRef(word: word.urdu, lang: 'ur', gloss: word.english);
    final fav = state.isFavorite(ref);
    final inReview = challenge.reviewQueue.any((e) => e.urdu == word.urdu);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        side: BorderSide(color: scheme.primaryContainer, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer,
              scheme.primaryContainer.withValues(alpha: 0.5),
              scheme.secondaryContainer.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () => openWord(context, word.urdu, 'ur'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded,
                        size: 16,
                        color: scheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text('WORD OF THE DAY',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          letterSpacing: 1.2,
                        )),
                    const Spacer(),
                    // TTS button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: speaking ? 'Stop' : 'Pronounce',
                      icon: Icon(
                        speaking
                            ? Icons.stop_circle_rounded
                            : Icons.volume_up_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                      onPressed: word.urdu.isNotEmpty
                          ? () => onSpeak(word.urdu)
                          : null,
                    ),
                    // Favorite button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: fav ? 'Remove from favorites' : 'Save to favorites',
                      icon: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav
                            ? scheme.error
                            : scheme.onPrimaryContainer,
                      ),
                      onPressed: () =>
                          context.read<AppState>().toggleFavorite(ref),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Urdu headword
                UrduText(
                  word.urdu,
                  textAlign: TextAlign.left,
                  semanticsLabel: '${word.english}, ${word.roman}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    height: UrduType.headHeight,
                  ),
                ),
                const SizedBox(height: 6),

                // Roman transliteration + English gloss
                Text(
                  word.roman,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.english,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),

                // Save to review button
                FilledButton.tonalIcon(
                  onPressed: inReview
                      ? null
                      : () {
                          context.read<ChallengeState>().addToReview(word);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                              content: Text('Added to review list'),
                              duration: Duration(seconds: 2),
                            ));
                        },
                  icon: Icon(inReview
                      ? Icons.check_circle_outline_rounded
                      : Icons.bookmark_add_outlined),
                  label: Text(inReview ? 'In review list' : 'Save to review'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        scheme.onPrimaryContainer.withValues(alpha: 0.12),
                    foregroundColor: scheme.onPrimaryContainer,
                    visualDensity: VisualDensity.compact,
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

// ── Action card ───────────────────────────────────────────────────────────────

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
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.10),
                color.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
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
