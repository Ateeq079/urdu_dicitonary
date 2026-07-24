import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/connectivity_service.dart';
import 'services/seed_repository.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'state/challenge_state.dart';
import 'state/favorites_state.dart';
import 'state/recents_state.dart';
import 'state/word_of_day_state.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.create();
  final seed = await SeedRepository.load();
  final api = ApiService(storage);

  // Instantiate focused state notifiers.
  final favoritesState = FavoritesState(storage);
  final recentsState = RecentsState(storage);
  final wordOfDayState = WordOfDayState(seed);
  final challengeState = ChallengeState(storage, seed);

  // Compose AppState facade for backwards-compatible call sites.
  final appState = AppState(
    storage,
    seed,
    favorites: favoritesState,
    recents: recentsState,
    wordOfDay: wordOfDayState,
    challenge: challengeState,
  );

  // ThemeMode stored in shared_preferences; mutable via Settings screen.
  final savedTheme = storage.getString('theme_mode');
  final initialTheme = savedTheme == 'light'
      ? ThemeMode.light
      : savedTheme == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system;

  // Check FTUE.
  final ftue = storage.getString('ftue_done') == null;

  runApp(LughatApp(
    storage: storage,
    api: api,
    appState: appState,
    favoritesState: favoritesState,
    recentsState: recentsState,
    wordOfDayState: wordOfDayState,
    challengeState: challengeState,
    initialTheme: initialTheme,
    showFtue: ftue,
  ));
}

class LughatApp extends StatefulWidget {
  const LughatApp({
    super.key,
    required this.storage,
    required this.api,
    required this.appState,
    required this.favoritesState,
    required this.recentsState,
    required this.wordOfDayState,
    required this.challengeState,
    required this.initialTheme,
    required this.showFtue,
  });

  final StorageService storage;
  final ApiService api;
  final AppState appState;
  final FavoritesState favoritesState;
  final RecentsState recentsState;
  final WordOfDayState wordOfDayState;
  final ChallengeState challengeState;
  final ThemeMode initialTheme;
  final bool showFtue;

  @override
  State<LughatApp> createState() => _LughatAppState();
}

class _LughatAppState extends State<LughatApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  void _setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    final val = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    widget.storage.setString('theme_mode', val);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<ApiService>.value(value: widget.api),
        Provider<StorageService>.value(value: widget.storage),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(widget.api),
        ),

        // State notifiers — provided both individually and via AppState facade
        ChangeNotifierProvider<FavoritesState>.value(
            value: widget.favoritesState),
        ChangeNotifierProvider<RecentsState>.value(value: widget.recentsState),
        ChangeNotifierProvider<WordOfDayState>.value(
            value: widget.wordOfDayState),
        ChangeNotifierProvider<ChallengeState>.value(
            value: widget.challengeState),

        // AppState facade for backwards-compatible call sites
        ChangeNotifierProvider<AppState>.value(value: widget.appState),

        // ThemeMode setter callback
        Provider<void Function(ThemeMode)>.value(value: _setTheme),
      ],
      child: MaterialApp(
        title: 'Lughat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        home: widget.showFtue
            ? OnboardingScreen(onDone: () {
                widget.storage.setString('ftue_done', '1');
              })
            : const RootShell(),
      ),
    );
  }
}
