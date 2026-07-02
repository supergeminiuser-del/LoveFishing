// Базовый тест-заглушка для FishLog Russia.
//
// Полноценные виджет-тесты требуют инициализации SQLite/plugin-каналов,
// которые недоступны в headless-тестовом окружении по умолчанию. Здесь
// проверяется лишь то, что основные модели/утилиты корректно импортируются
// и работают.

import 'package:flutter_test/flutter_test.dart';

import 'package:fishlog_russia/core/utils/formatters.dart';

void main() {
  test('AppFormatters форматирует вес в килограммах', () {
    expect(AppFormatters.weight(2.5), '2.5 кг');
  });

  test('AppFormatters форматирует вес в граммах при значении меньше 1 кг', () {
    expect(AppFormatters.weight(0.35), '350 г');
  });
}
