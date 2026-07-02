import '../../core/utils/json_list_codec.dart';

class EquipmentItem {
  final String id;
  final String name;
  final String category;
  final List<String> photoPaths;
  final String? brand;
  final String? model;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    this.photoPaths = const [],
    this.brand,
    this.model,
    this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  EquipmentItem copyWith({
    String? name,
    String? category,
    List<String>? photoPaths,
    String? brand,
    String? model,
    DateTime? purchaseDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return EquipmentItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      photoPaths: photoPaths ?? this.photoPaths,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'photo_paths': JsonListCodec.encode(photoPaths),
      'brand': brand,
      'model': model,
      'purchase_date': purchaseDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EquipmentItem.fromMap(Map<String, Object?> map) {
    return EquipmentItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
