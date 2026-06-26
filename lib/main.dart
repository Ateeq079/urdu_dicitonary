import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/seed_repository.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'screens/root_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final seed = await SeedRepository.load();
  final api = ApiService(storage);

  runApp(LughatApp(storage: storage, seed: seed, api: api));
}

class LughatApp extends StatelessWidget {
  const LughatApp({
    super.key,
    required this.storage,
    required this.seed,
    required this.api,
  });

  final StorageService storage;
  final SeedRepository seed;
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(storage, seed),
        ),
      ],
      child: MaterialApp(
        title: 'Lughat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const RootShell(),
      ),
    );
  }
}
