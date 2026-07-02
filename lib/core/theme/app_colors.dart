import 'package:flutter/material.dart';

/// Фирменная палитра FishLog Russia: сине-зелёные акценты на премиальном
/// тёмном фоне (тёмная тема по умолчанию) с поддержкой светлой темы.
class AppColors {
  AppColors._();

  // Основные акценты
  static const Color blue = Color(0xFF2E7DF7);
  static const Color blueDark = Color(0xFF1A56C4);
  static const Color green = Color(0xFF22C58B);
  static const Color greenDark = Color(0xFF17A374);

  // Тёмная тема
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF121B2C);
  static const Color darkSurfaceHigh = Color(0xFF182437);
  static const Color darkCard = Color(0xFF16202F);
  static const Color darkOutline = Color(0xFF2A3A50);

  // Светлая тема
  static const Color lightBackground = Color(0xFFF5F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFDCE4EE);

  // Служебные
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);
  static const Color success = green;
  static const Color star = Color(0xFFFFC53D);

  static const List<Color> markerColors = [
    Color(0xFF2E7DF7),
    Color(0xFF22C58B),
    Color(0xFFF5A623),
    Color(0xFFE5484D),
    Color(0xFF9B59F6),
    Color(0xFF00BCD4),
    Color(0xFFEC4899),
    Color(0xFF8D99AE),
  ];
}
