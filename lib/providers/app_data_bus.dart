import 'package:flutter/foundation.dart';

/// Простая шина событий: любой экран может «оповестить» об изменении
/// данных (добавлен/изменён/удалён улов, рыба, приманка и т.д.), а другие
/// экраны (дашборд, статистика) слушают и обновляются автоматически.
class AppDataBus extends ChangeNotifier {
  int _tick = 0;
  int get tick => _tick;

  void notifyChanged() {
    _tick++;
    notifyListeners();
  }
}
