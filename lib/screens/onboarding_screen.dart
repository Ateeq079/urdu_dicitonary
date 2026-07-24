import 'package:flutter/material.dart';

import '../theme.dart';
import 'root_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user taps "Get Started". Should write the ftue_done flag.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.wifi_off_rounded,
      title: 'Works Offline',
      subtitle:
          'Look up words even on the metro or in low-connectivity areas. '
          'Every word you open is saved for offline use automatically.',
      urduWord: 'لغت',
      urduGloss: 'Dictionary',
    ),
    _OnboardPage(
      icon: Icons.swap_horiz_rounded,
      title: 'Both Languages',
      subtitle:
          'Search in Urdu, English, or Roman Urdu. Type "mohabbat" and '
          'we\'ll find محبت for you — no Urdu keyboard needed.',
      urduWord: 'محبت',
      urduGloss: 'Love',
    ),
    _OnboardPage(
      icon: Icons.favorite_rounded,
      title: 'Build Your Vocabulary',
      subtitle:
          'Save words you love, practice with the daily challenge, and '
          'revisit them with spaced-repetition review to make them stick.',
      urduWord: 'علم',
      urduGloss: 'Knowledge',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    widget.onDone();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Indicators + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.urduWord,
    required this.urduGloss,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String urduWord;
  final String urduGloss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero — gradient card with Urdu word
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: scheme.primaryContainer,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 40, color: scheme.onPrimaryContainer),
                const SizedBox(height: 16),
                UrduText(
                  urduWord,
                  textAlign: TextAlign.center,
                  semanticsLabel: urduGloss,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    height: UrduType.headHeight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  urduGloss,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
