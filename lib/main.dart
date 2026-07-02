import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'navigation/main_navigation.dart';
import 'providers/app_data_bus.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/backup_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  // Автоматическая локальная резервная копия (не чаще раза в сутки).
  unawaited(BackupService().maybeCreateAutomaticBackup());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AppDataBus()),
      ],
      child: const FishLogApp(),
    ),
  );
}

class FishLogApp extends StatelessWidget {
  const FishLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'FishLog Russia',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.flutterThemeMode,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final SettingsService _settings = SettingsService();
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await _settings.isFirstRunDone();
    if (mounted) {
      setState(() => _showOnboarding = !done);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _showOnboarding! ? const WelcomeScreen() : const MainNavigation();
  }
}
