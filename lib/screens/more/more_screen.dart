import 'package:flutter/material.dart';

import '../baits/bait_list_screen.dart';
import '../fish/fish_list_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../spots/spot_list_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ещё')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, Icons.set_meal_rounded, 'Рыбы', 'Справочник видов рыб', const FishListScreen()),
          _tile(context, Icons.bubble_chart_rounded, 'Приманки', 'Все приманки и снасти', const BaitListScreen()),
          _tile(context, Icons.place_rounded, 'Места', 'Список рыболовных мест', const SpotListScreen()),
          _tile(context, Icons.search_rounded, 'Поиск', 'Поиск по всем данным', const SearchScreen()),
          const Divider(height: 32),
          _tile(context, Icons.settings_rounded, 'Настройки', 'Тема, резервные копии, данные', const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Widget screen) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
