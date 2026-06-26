import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'word_detail_screen.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _controller = TextEditingController();
  bool _enToUr = true; // direction
  bool _loading = false;
  LookupResult? _result;
  String _lastTerm = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _lastTerm = term;
    });
    final lang = _enToUr ? 'en' : 'ur';
    final res = await context.read<ApiService>().lookup(lang, term);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  void _swap() {
    setState(() {
      _enToUr = !_enToUr;
      _result = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Translator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LangBadge(_enToUr ? 'English' : 'Urdu'),
              IconButton(
                onPressed: _swap,
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Swap direction',
              ),
              _LangBadge(_enToUr ? 'Urdu' : 'English'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _translate(),
            textDirection:
                _enToUr ? TextDirection.ltr : TextDirection.rtl,
            decoration: InputDecoration(
              hintText:
                  _enToUr ? 'Type an English word…' : 'اردو لفظ لکھیں…',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _translate,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.translate_rounded),
            label: const Text('Translate'),
          ),
          const SizedBox(height: 20),
          if (_result != null) _buildResult(theme),
        ],
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    final res = _result!;
    if (res.status == LookupStatus.offline) {
      return _info(theme, Icons.wifi_off_rounded, 'You\'re offline',
          'Connect to the internet to translate new words.');
    }
    if (res.status == LookupStatus.notFound) {
      return _info(theme, Icons.search_off_rounded, 'No translation',
          'No entry found for "$_lastTerm".');
    }
    final data = res.data!;
    final outputs =
        _enToUr ? data.urduTranslations : data.definitions;

    if (outputs.isEmpty) {
      return _info(
        theme,
        Icons.info_outline_rounded,
        'No direct translation',
        _enToUr
            ? 'The dictionary has no Urdu translation for "$_lastTerm". Tap below to see its full entry.'
            : 'No English gloss found for "$_lastTerm". Tap below to see its full entry.',
        showOpen: true,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (res.fromCache)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('Saved offline copy',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
            Text(_lastTerm,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: theme.colorScheme.outline)),
            const Divider(height: 20),
            ...outputs.take(8).map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _enToUr
                      ? UrduText(o,
                          textAlign: TextAlign.left,
                          style: theme.textTheme.headlineSmall)
                      : Text(o, style: theme.textTheme.titleMedium),
                )),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => openWord(
                    context, _lastTerm, _enToUr ? 'en' : 'ur'),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('Full entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(ThemeData theme, IconData icon, String title, String body,
      {bool showOpen = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 10),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            if (showOpen) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => openWord(
                    context, _lastTerm, _enToUr ? 'en' : 'ur'),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Open full entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer)),
    );
  }
}
