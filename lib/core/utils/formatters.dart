import 'package:intl/intl.dart';

/// Форматирование дат, времени и единиц измерения по российским стандартам.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFull = DateFormat('d MMMM yyyy', 'ru_RU');
  static final DateFormat _dateShort = DateFormat('dd.MM.yyyy', 'ru_RU');
  static final DateFormat _dateShortNoYear = DateFormat('d MMMM', 'ru_RU');
  static final DateFormat _time = DateFormat('HH:mm', 'ru_RU');
  static final DateFormat _dateTime = DateFormat('dd.MM.yyyy, HH:mm', 'ru_RU');
  static final DateFormat _monthYear = DateFormat('LLLL yyyy', 'ru_RU');
  static final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmmss');

  static String dateFull(DateTime date) => _dateFull.format(date);

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String dateShortNoYear(DateTime date) => _dateShortNoYear.format(date);

  static String time(DateTime date) => _time.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String fileStamp(DateTime date) => _fileStamp.format(date);

  /// "3 дня назад", "сегодня", "вчера" — относительное отображение.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    if (diff == 2) return 'Позавчера';
    if (diff > 2 && diff < 7) return '$diff дн. назад';
    return dateShort(date);
  }

  static String weight(double? kg, {String suffix = ' кг'}) {
    if (kg == null) return '—';
    if (kg < 1) {
      final grams = (kg * 1000).round();
      return '$grams г';
    }
    return '${_trimZeros(kg)}$suffix';
  }

  static String length(double? cm) {
    if (cm == null) return '—';
    return '${_trimZeros(cm)} см';
  }

  static String distanceKm(double? km) {
    if (km == null) return '—';
    if (km < 1) {
      final m = (km * 1000).round();
      return '$m м';
    }
    return '${_trimZeros(km)} км';
  }

  static String temperature(double? c) {
    if (c == null) return '—';
    final sign = c > 0 ? '+' : '';
    return '$sign${_trimZeros(c)} °C';
  }

  static String pressure(double? hpa) {
    if (hpa == null) return '—';
    // Российский стандарт — мм рт. ст.
    final mmHg = (hpa * 0.750062).round();
    return '$mmHg мм рт. ст.';
  }

  static String coordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static String pluralCatches(int count) {
    return '$count ${_plural(count, 'улов', 'улова', 'уловов')}';
  }

  static String pluralFish(int count) {
    return '$count ${_plural(count, 'рыба', 'рыбы', 'рыб')}';
  }

  static String pluralTrips(int count) {
    return '$count ${_plural(count, 'рыбалка', 'рыбалки', 'рыбалок')}';
  }

  static String pluralSpots(int count) {
    return '$count ${_plural(count, 'место', 'места', 'мест')}';
  }

  static String pluralPhotos(int count) {
    return '$count ${_plural(count, 'фото', 'фото', 'фото')}';
  }

  static String pluralDays(int count) {
    return '$count ${_plural(count, 'день', 'дня', 'дней')}';
  }

  static String _plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }

  static String _trimZeros(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
