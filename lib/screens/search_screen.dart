import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return;
    final lang = isUrdu(q) ? 'ur' : 'en';
    openWord(context, q, lang);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final suggestions = state.seed.suggest(_query);
    final correction =
        suggestions.isEmpty ? state.seed.fuzzyCorrect(_query) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: 'Search Urdu or English…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _RecentList(state: state)
                : _SuggestionList(
                    query: _query,
                    suggestions: suggestions,
                    correction: correction,
                    onSearchExact: () => _submit(_query),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.query,
    required this.suggestions,
    required this.correction,
    required this.onSearchExact,
  });

  final String query;
  final List<SeedWord> suggestions;
  final SeedWord? correction;
  final VoidCallback onSearchExact;

  @override
  Widget build(BuildContext context) {
    final lang = isUrdu(query) ? 'ur' : 'en';
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.travel_explore_rounded),
          title: Text('Search "$query" online'),
          subtitle: const Text('Look up in the full dictionary'),
          onTap: onSearchExact,
        ),
        if (correction != null) ...[
          const Divider(height: 1),
          Container(
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withValues(alpha: 0.4),
            child: ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Did you mean '),
                TextSpan(
                    text: correction!.english,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?'),
              ])),
              subtitle: _UrduSubtitle(correction!),
              onTap: () => openWord(context, correction!.urdu, 'ur'),
            ),
          ),
        ],
        if (suggestions.isNotEmpty) const Divider(height: 1),
        ...suggestions.map((w) => _SeedTile(word: w)),
        if (suggestions.isEmpty && correction == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No quick suggestions. Tap “Search online” to look it up in the full dictionary.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        // also offer searching the raw query in the other language
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          leading: const Icon(Icons.swap_horiz_rounded),
          title: Text(
              'Search "$query" as ${lang == 'ur' ? 'English' : 'Urdu'} instead'),
          onTap: () =>
              openWord(context, query, lang == 'ur' ? 'en' : 'ur'),
        ),
      ],
    );
  }
}

class _SeedTile extends StatelessWidget {
  const _SeedTile({required this.word});
  final SeedWord word;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: UrduText(word.urdu,
          textAlign: TextAlign.left, style: const TextStyle(fontSize: 22)),
      subtitle: Text('${word.english}  ·  ${word.roman}'),
      trailing: Text(WordCategory.titleFor(word.category),
          style: Theme.of(context).textTheme.bodySmall),
      onTap: () => openWord(context, word.urdu, 'ur'),
    );
  }
}

class _UrduSubtitle extends StatelessWidget {
  const _UrduSubtitle(this.word);
  final SeedWord word;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: UrduText(word.urdu,
          textAlign: TextAlign.left, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recents = state.recents;
    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 56, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text('Your recent searches will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text('Recent searches',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: () => context.read<AppState>().clearRecents(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        ...recents.map((r) => ListTile(
              leading: const Icon(Icons.history_rounded),
              title: r.lang == 'ur'
                  ? UrduText(r.word,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 20))
                  : Text(r.word),
              trailing: const Icon(Icons.north_west_rounded, size: 18),
              onTap: () => openWord(context, r.word, r.lang),
            )),
      ],
    );
  }
}
