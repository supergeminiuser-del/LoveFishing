import 'package:flutter/material.dart';

/// Универсальный выбор сущности (рыба/приманка/снаряжение/место) из списка
/// с поиском и быстрым созданием новой записи, если подходящей ещё нет.
class EntityPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> recentItems;
  final String Function(T) labelOf;
  final String? Function(T)? subtitleOf;
  final VoidCallback? onCreateNew;
  final String createLabel;

  const EntityPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.labelOf,
    this.recentItems = const [],
    this.subtitleOf,
    this.onCreateNew,
    this.createLabel = 'Добавить новое',
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    List<T> recentItems = const [],
    String? Function(T)? subtitleOf,
    VoidCallback? onCreateNew,
    String createLabel = 'Добавить новое',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EntityPickerSheet<T>(
        title: title,
        items: items,
        recentItems: recentItems,
        labelOf: labelOf,
        subtitleOf: subtitleOf,
        onCreateNew: onCreateNew,
        createLabel: createLabel,
      ),
    );
  }

  @override
  State<EntityPickerSheet<T>> createState() => _EntityPickerSheetState<T>();
}

class _EntityPickerSheetState<T> extends State<EntityPickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((e) => widget.labelOf(e).toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    if (widget.onCreateNew != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onCreateNew!();
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text(widget.createLabel),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('Ничего не найдено',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (_query.isEmpty && widget.recentItems.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Недавние', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            ...widget.recentItems.map((e) => _tile(e)),
                            const Divider(height: 20),
                          ],
                          ...filtered.map((e) => _tile(e)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(T item) {
    final subtitle = widget.subtitleOf?.call(item);
    return ListTile(
      title: Text(widget.labelOf(item)),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      onTap: () => Navigator.of(context).pop(item),
    );
  }
}
