import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seed_word.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary Lists')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: WordCategory.all
            .map((c) => _CategoryCard(category: c))
            .toList(),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final WordCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = context.read<AppState>().seed.byCategory(category.id).length;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CategoryWordsScreen(category: category),
        )),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(category.emoji,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(category.title, style: theme.textTheme.titleMedium),
              Text('$count words',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryWordsScreen extends StatelessWidget {
  const CategoryWordsScreen({super.key, required this.category});
  final WordCategory category;

  @override
  Widget build(BuildContext context) {
    final words = context.read<AppState>().seed.byCategory(category.id);
    return Scaffold(
      appBar: AppBar(title: Text('${category.emoji}  ${category.title}')),
      body: ListView.separated(
        itemCount: words.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final w = words[i];
          return ListTile(
            title: UrduText(
              w.urdu,
              textAlign: TextAlign.left,
              semanticsLabel: '${w.english}, ${w.roman}',
              style: const TextStyle(fontSize: 24),
            ),
            subtitle: Text('${w.english}  ·  ${w.roman}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openWord(context, w.urdu, 'ur'),
          );
        },
      ),
    );
  }
}
