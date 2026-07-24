import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final favs = state.favorites;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('No favorites yet',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the heart on any word to save it here for offline access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: favs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final f = favs[i];
                return Dismissible(
                  key: ValueKey(f.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: scheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(Icons.delete_outline_rounded,
                        color: scheme.onError),
                  ),
                  onDismissed: (_) =>
                      context.read<AppState>().removeFavorite(f),
                  child: ListTile(
                    leading: Icon(Icons.favorite, color: scheme.error),
                    title: f.lang == 'ur'
                        ? UrduText(
                            f.word,
                            textAlign: TextAlign.left,
                            semanticsLabel: f.gloss.isNotEmpty ? f.gloss : f.word,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Text(f.word,
                            style: const TextStyle(fontSize: 18)),
                    subtitle: f.gloss.isEmpty
                        ? Text(f.lang == 'ur' ? 'Urdu' : 'English')
                        : Text(f.gloss),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openWord(context, f.word, f.lang),
                  ),
                );
              },
            ),
    );
  }
}
