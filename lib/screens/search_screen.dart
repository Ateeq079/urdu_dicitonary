import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../services/connectivity_service.dart';
import '../state/app_state.dart';
import '../state/recents_state.dart';
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
    final connectivity = context.watch<ConnectivityService>();
    final suggestions = state.seed.suggest(_query);
    final correction =
        suggestions.isEmpty ? state.seed.fuzzyCorrect(_query) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // ── Connectivity chip ───────────────────────────────────────────
          if (!connectivity.isOnline)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _OfflineChip(),
            ),

          // ── Search field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: _query.isEmpty
                ? _RecentList(state: state)
                : _SuggestionList(
                    query: _query,
                    suggestions: suggestions,
                    correction: correction,
                    onSearchExact: () => _submit(_query),
                    isOffline: !connectivity.isOnline,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Offline chip ──────────────────────────────────────────────────────────────

class _OfflineChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Text('Offline — showing local results',
              style: TextStyle(
                  fontSize: 13, color: scheme.onTertiaryContainer)),
        ],
      ),
    );
  }
}

// ── Suggestion list ───────────────────────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.query,
    required this.suggestions,
    required this.correction,
    required this.onSearchExact,
    required this.isOffline,
  });

  final String query;
  final List<SeedWord> suggestions;
  final SeedWord? correction;
  final VoidCallback onSearchExact;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final lang = isUrdu(query) ? 'ur' : 'en';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final noResults = suggestions.isEmpty && correction == null;

    return ListView(
      children: [
        // ── Online search entry (dimmed if offline) ─────────────────────
        ListTile(
          leading: Icon(
            Icons.travel_explore_rounded,
            color: isOffline ? scheme.outline : null,
          ),
          title: Text(
            'Search "$query" online',
            style: isOffline
                ? TextStyle(color: scheme.outline)
                : null,
          ),
          subtitle: Text(
            isOffline
                ? 'Unavailable offline'
                : 'Look up in the full dictionary',
          ),
          onTap: isOffline ? null : onSearchExact,
        ),

        // ── "Did you mean?" correction ──────────────────────────────────
        if (correction != null) ...[
          const Divider(height: 1),
          Container(
            color: scheme.tertiaryContainer.withValues(alpha: 0.4),
            child: ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded),
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Did you mean '),
                TextSpan(
                    text: correction!.english,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?'),
              ])),
              subtitle: Align(
                alignment: Alignment.centerLeft,
                child: UrduText(
                  correction!.urdu,
                  textAlign: TextAlign.left,
                  semanticsLabel: correction!.english,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              onTap: () => openWord(context, correction!.urdu, 'ur'),
            ),
          ),
        ],

        // ── Seed suggestions ────────────────────────────────────────────
        if (suggestions.isNotEmpty) const Divider(height: 1),
        ...suggestions.map((w) => _SeedTile(word: w)),

        // ── Empty state with personality ────────────────────────────────
        if (noResults)
          _EmptySearchState(
            query: query,
            lang: lang,
            isOffline: isOffline,
          ),

        // ── Switch language option ───────────────────────────────────────
        if (!noResults) ...[
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
      ],
    );
  }
}

// ── Empty search state ────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.query,
    required this.lang,
    required this.isOffline,
  });
  final String query;
  final String lang;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: scheme.outline),
          const SizedBox(height: 16),
          Text('No results for "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try one of these:',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // Action tiles
          _SuggestionAction(
            icon: Icons.travel_explore_rounded,
            label: 'Search online',
            enabled: !isOffline,
            onTap: () => openWord(context, query, lang),
          ),
          _SuggestionAction(
            icon: Icons.swap_horiz_rounded,
            label: 'Try in ${lang == 'ur' ? 'English' : 'Urdu'}',
            enabled: true,
            onTap: () =>
                openWord(context, query, lang == 'ur' ? 'en' : 'ur'),
          ),
          _SuggestionAction(
            icon: Icons.list_alt_rounded,
            label: 'Browse word lists',
            enabled: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionAction extends StatelessWidget {
  const _SuggestionAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}

// ── Seed tile ─────────────────────────────────────────────────────────────────

class _SeedTile extends StatelessWidget {
  const _SeedTile({required this.word});
  final SeedWord word;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: UrduText(
        word.urdu,
        textAlign: TextAlign.left,
        semanticsLabel: '${word.english}, ${word.roman}',
        style: AppTheme.urduListStyle(context),
      ),
      subtitle: Text('${word.english}  ·  ${word.roman}'),
      trailing: Text(WordCategory.titleFor(word.category),
          style: Theme.of(context).textTheme.bodySmall),
      onTap: () => openWord(context, word.urdu, 'ur'),
    );
  }
}

// ── Recent list ───────────────────────────────────────────────────────────────

class _RecentList extends StatelessWidget {
  const _RecentList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final recents = state.recents;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 56, color: scheme.outline),
              const SizedBox(height: 12),
              Text('Your recent searches will appear here',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant)),
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
                  style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<RecentsState>().clearRecents(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        ...recents.map((r) => ListTile(
              leading: const Icon(Icons.history_rounded),
              title: r.lang == 'ur'
                  ? UrduText(
                      r.word,
                      textAlign: TextAlign.left,
                      semanticsLabel:
                          r.gloss.isNotEmpty ? r.gloss : r.word,
                      style: AppTheme.urduListStyle(context),
                    )
                  : Text(r.word),
              trailing: const Icon(Icons.north_west_rounded, size: 18),
              onTap: () => openWord(context, r.word, r.lang),
            )),
      ],
    );
  }
}
