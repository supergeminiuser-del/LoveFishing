/// Общие константы приложения FishLog Russia.
class AppConstants {
  AppConstants._();

  static const String appName = 'FishLog Russia';
  static const String dbName = 'fishlog_russia.db';
  static const int dbVersion = 1;

  static const String photosDirName = 'photos';
  static const String backupsDirName = 'backups';
  static const String tileCacheDirName = 'tile_cache';

  // Ключи SharedPreferences
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefFirstRunDone = 'pref_first_run_done';
  static const String prefLastBackupAt = 'pref_last_backup_at';

  static const int maxPhotosPerEntity = 12;
}

/// Категории рыб по умолчанию (стартовый список пользователь может менять).
class FishCategories {
  FishCategories._();

  static const List<String> defaults = [
    'Карповые',
    'Хищные',
    'Окунёвые',
    'Лососёвые',
    'Другое',
  ];
}

/// Категории снаряжения.
class EquipmentCategory {
  EquipmentCategory._();

  static const String rod = 'rod';
  static const String reel = 'reel';
  static const String line = 'line';
  static const String hook = 'hook';
  static const String float = 'float';
  static const String sinker = 'sinker';
  static const String lure = 'lure';
  static const String net = 'net';
  static const String boat = 'boat';
  static const String motor = 'motor';
  static const String accessory = 'accessory';

  static const List<String> all = [
    rod,
    reel,
    line,
    hook,
    float,
    sinker,
    lure,
    net,
    boat,
    motor,
    accessory,
  ];

  static String label(String value) {
    switch (value) {
      case rod:
        return 'Удилище';
      case reel:
        return 'Катушка';
      case line:
        return 'Леска/шнур';
      case hook:
        return 'Крючок';
      case float:
        return 'Поплавок';
      case sinker:
        return 'Грузило';
      case lure:
        return 'Приманка/блесна';
      case net:
        return 'Подсак/садок';
      case boat:
        return 'Лодка';
      case motor:
        return 'Мотор';
      case accessory:
        return 'Аксессуар';
      default:
        return value;
    }
  }
}

/// Способы ловли.
class FishingMethods {
  FishingMethods._();

  static const List<String> all = [
    'Спиннинг',
    'Поплавочная удочка',
    'Донная снасть (фидер)',
    'Нахлыст',
    'Троллинг',
    'Зимняя рыбалка',
    'Другое',
  ];
}

/// Прозрачность воды.
class WaterClarityOptions {
  WaterClarityOptions._();

  static const List<String> all = [
    'Прозрачная',
    'Слегка мутная',
    'Мутная',
    'Очень мутная',
  ];
}

/// Уровень воды.
class WaterLevelOptions {
  WaterLevelOptions._();

  static const List<String> all = [
    'Низкий',
    'Ниже среднего',
    'Средний',
    'Выше среднего',
    'Высокий',
  ];
}

/// Сезоны.
class SeasonOptions {
  SeasonOptions._();

  static const List<String> all = ['Весна', 'Лето', 'Осень', 'Зима'];
}

/// Типы маркеров на карте.
class MarkerTypeOptions {
  MarkerTypeOptions._();

  static const String spot = 'spot';
  static const String danger = 'danger';

  static const List<String> all = [spot, danger];
}
