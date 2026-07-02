import 'package:flutter/material.dart';

import '../../navigation/main_navigation.dart';
import '../../services/settings_service.dart';
import '../baits/bait_form_screen.dart';
import '../fish/fish_form_screen.dart';
import '../spots/spot_form_screen.dart';
import '../trips/trip_form_screen.dart';

/// Экран приветствия при первом запуске. База данных пуста — пользователь
/// сам создаёт первые записи. Никакого встроенного справочника нет.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    await SettingsService().markFirstRunDone();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  Future<void> _openAndFinish(BuildContext context, Widget screen) async {
    await SettingsService().markFirstRunDone();
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.phishing_rounded, color: Colors.white, size: 44),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'FishLog Russia',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Личный офлайн-дневник рыболова. Все данные хранятся только '
                'на вашем устройстве — без аккаунта, без интернета, без рекламы.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _OptionTile(
                      icon: Icons.set_meal_rounded,
                      title: 'Добавить первую рыбу',
                      subtitle: 'Создайте вид рыбы для своего справочника',
                      onTap: () => _openAndFinish(context, const FishFormScreen()),
                    ),
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: Icons.bubble_chart_rounded,
                      title: 'Добавить первую приманку',
                      subtitle: 'Занесите приманку или снасть, которой ловите',
                      onTap: () => _openAndFinish(context, const BaitFormScreen()),
                    ),
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: Icons.place_rounded,
                      title: 'Добавить первое место',
                      subtitle: 'Отметьте любимое место для рыбалки',
                      onTap: () => _openAndFinish(context, const SpotFormScreen()),
                    ),
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: Icons.directions_boat_filled_rounded,
                      title: 'Начать первую рыбалку',
                      subtitle: 'Создайте запись о новой рыбалке',
                      onTap: () => _openAndFinish(context, const TripFormScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _finish(context),
                child: const Text('Пропустить и перейти в приложение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
