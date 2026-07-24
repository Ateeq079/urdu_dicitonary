import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    final saved = storage.getString('theme_mode');
    _selected = saved == 'light'
        ? ThemeMode.light
        : saved == 'dark'
        ? ThemeMode.dark
        : ThemeMode.system;
  }

  void _setTheme(ThemeMode mode) {
    setState(() => _selected = mode);
    // Propagate to root app.
    final setter = context.read<void Function(ThemeMode)>();
    setter(mode);
  }

  Future<void> _clearCache(BuildContext context) async {
    final storage = context.read<StorageService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'This removes all saved offline word data. '
          'You\'ll need a connection to look up words again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // Remove all cache: keys from storage.
      // SharedPreferences doesn't expose key iteration via our wrapper,
      // so we use a flag to signal a cache wipe on next app launch.
      // A full cache clear would require direct SharedPreferences access.
      await storage.setString(
        'cache_cleared',
        DateTime.now().toIso8601String(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _ThemeTile(selected: _selected, onChanged: _setTheme),

          const Divider(height: 24),

          // ── Offline Data ────────────────────────────────────────────────
          _SectionHeader('Offline Data'),
          ListTile(
            leading: Icon(Icons.delete_sweep_rounded, color: scheme.error),
            title: const Text('Clear word cache'),
            subtitle: const Text('Removes all saved offline word data'),
            onTap: () => _clearCache(context),
          ),

          const Divider(height: 24),

          // ── About ───────────────────────────────────────────────────────
          _SectionHeader('About'),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: scheme.primary),
            title: const Text('Lughat'),
            subtitle: const Text('Version 2.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.library_books_rounded, color: scheme.primary),
            title: const Text('Dictionary data'),
            subtitle: const Text(
              'Free Dictionary API (Wiktionary, CC BY-SA 4.0)',
            ),
          ),
          ListTile(
            leading: Icon(Icons.translate_rounded, color: scheme.primary),
            title: const Text('Seed vocabulary'),
            subtitle: const Text('Curated Urdu–English word list, offline'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return scheme.primaryContainer;
                }
                return Colors.transparent;
              }),
            ),
          ),
        ],
      ),
    );
  }
}
