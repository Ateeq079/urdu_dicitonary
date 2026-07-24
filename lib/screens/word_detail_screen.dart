import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_result.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({
    super.key,
    required this.word,
    required this.lang,
  });

  final String word;
  final String lang; // 'en' or 'ur'

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late Future<LookupResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<LookupResult> _fetch() async {
    final api = context.read<ApiService>();
    final res = await api.lookup(widget.lang, widget.word);
    if (res.status == LookupStatus.found && mounted) {
      context.read<AppState>().addRecent(
            WordRef(word: widget.word, lang: widget.lang),
          );
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final isUr = widget.lang == 'ur';
    return Scaffold(
      appBar: AppBar(
        title: isUr
            ? UrduText(
                widget.word,
                textAlign: TextAlign.left,
                semanticsLabel: widget.word,
                style: const TextStyle(fontSize: 22),
              )
            : Text(widget.word),
        actions: [_FavButton(word: widget.word, lang: widget.lang)],
      ),
      body: FutureBuilder<LookupResult>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final res = snap.data!;
          switch (res.status) {
            case LookupStatus.offline:
              return _Message(
                icon: Icons.wifi_off_rounded,
                title: 'You\'re offline',
                body:
                    'Connect to the internet to look up "${widget.word}". Words you opened before are available offline.',
                onRetry: _retry,
              );
            case LookupStatus.notFound:
              return _Message(
                icon: Icons.search_off_rounded,
                title: 'No entry found',
                body: 'We couldn\'t find "${widget.word}" in the dictionary.',
                onRetry: _retry,
              );
            case LookupStatus.found:
            case LookupStatus.staleCache:
              return _ResultView(
                result: res.data!,
                fromCache: res.fromCache,
                cachedAt: res.cachedAt,
              );
          }
        },
      ),
    );
  }

  void _retry() => setState(() => _future = _fetch());
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.fromCache,
    this.cachedAt,
  });

  final WordResult result;
  final bool fromCache;
  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (fromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Banner(
              icon: Icons.offline_pin_rounded,
              text: cachedAt != null
                  ? 'Offline — saved copy from ${_fmtDate(cachedAt!)}'
                  : 'Showing a saved offline copy.',
            ),
          ),
        for (final entry in result.entries) ...[
          _EntryCard(entry: entry),
          const SizedBox(height: 14),
        ],
        Text(
          'English definitions: Free Dictionary API (Wiktionary, CC BY-SA 4.0)\nUrdu definitions: English Wiktionary (CC BY-SA 4.0)',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final DictEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urdu = entry.langCode == 'ur';

    final urduTranslations = <String>[];
    for (final s in entry.senses) {
      for (final t in s.translations) {
        if (t.langCode == 'ur' && !urduTranslations.contains(t.word)) {
          urduTranslations.add(t.word);
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (entry.partOfSpeech.isNotEmpty)
                  _Pill(entry.partOfSpeech, theme.colorScheme.primary),
                const Spacer(),
                if (entry.pronunciation != null)
                  Text(entry.pronunciation!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 12),

            // Senses
            for (var i = 0; i < entry.senses.length; i++)
              _SenseTile(index: i + 1, sense: entry.senses[i]),

            // Urdu translations (for English words)
            if (urduTranslations.isNotEmpty) ...[
              const Divider(height: 24),
              _SectionLabel('Urdu translation'),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: urduTranslations
                    .map((w) => Chip(
                          label: UrduText(
                            w,
                            textAlign: TextAlign.center,
                            semanticsLabel: w,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Word forms
            if (entry.forms.isNotEmpty) ...[
              const Divider(height: 24),
              _SectionLabel('Forms'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: entry.forms
                    .take(8)
                    .map((f) => Chip(
                          label: urdu
                              ? UrduText(
                                  f,
                                  textAlign: TextAlign.center,
                                  semanticsLabel: f,
                                  style: const TextStyle(fontSize: 16),
                                )
                              : Text(f),
                        ))
                    .toList(),
              ),
            ],

            if (entry.synonyms.isNotEmpty) ...[
              const Divider(height: 24),
              _WordChips(label: 'Synonyms', words: entry.synonyms),
            ],
            if (entry.antonyms.isNotEmpty) ...[
              const SizedBox(height: 10),
              _WordChips(label: 'Antonyms', words: entry.antonyms),
            ],
          ],
        ),
      ),
    );
  }
}

class _SenseTile extends StatelessWidget {
  const _SenseTile({required this.index, required this.sense});

  final int index;
  final Sense sense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sense.definition.isEmpty) return const SizedBox.shrink();
    final defIsUrdu = isUrdu(sense.definition);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$index. ',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
              Expanded(
                child: defIsUrdu
                    ? UrduText(
                        sense.definition,
                        textAlign: TextAlign.left,
                        semanticsLabel: sense.definition,
                        style: theme.textTheme.titleMedium,
                      )
                    : Text(sense.definition,
                        style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          for (final ex in sense.examples.take(3))
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: isUrdu(ex)
                        ? UrduText(
                            ex,
                            textAlign: TextAlign.left,
                            semanticsLabel: ex,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant),
                          )
                        : Text(ex,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WordChips extends StatelessWidget {
  const _WordChips({required this.label, required this.words});

  final String label;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: words
              .take(12)
              .map((w) => Chip(
                    label: isUrdu(w)
                        ? UrduText(
                            w,
                            textAlign: TextAlign.center,
                            semanticsLabel: w,
                            style: const TextStyle(fontSize: 16),
                          )
                        : Text(w),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.outline,
        letterSpacing: 1,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  const _FavButton({required this.word, required this.lang});
  final String word;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final ref = WordRef(word: word, lang: lang);
    final fav = state.isFavorite(ref);
    return IconButton(
      tooltip: fav ? 'Remove from favorites' : 'Save to favorites',
      icon: Icon(
        fav ? Icons.favorite : Icons.favorite_border,
        color: fav ? scheme.error : null,
      ),
      onPressed: () {
        context.read<AppState>().toggleFavorite(ref);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(fav ? 'Removed from favorites' : 'Saved to favorites'),
          ));
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper to push a detail screen from anywhere.
void openWord(BuildContext context, String word, String lang) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => WordDetailScreen(word: word, lang: lang),
  ));
}

/// Format a [DateTime] as "24 Jul 2026" without the intl package.
String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
