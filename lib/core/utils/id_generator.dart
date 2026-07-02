import 'package:uuid/uuid.dart';

/// Единая точка генерации локальных идентификаторов записей.
class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  static String next() => _uuid.v4();
}
