import 'dart:convert';

/// Вспомогательный кодек для хранения списков строк (пути к фото и т.п.)
/// в текстовых полях SQLite в виде JSON-массива.
class JsonListCodec {
  JsonListCodec._();

  static String encode(List<String> items) => jsonEncode(items);

  static List<String> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
