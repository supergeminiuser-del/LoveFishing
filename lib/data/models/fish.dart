import '../../core/utils/json_list_codec.dart';

class Fish {
  final String id;
  final String name;
  final String? category;
  final List<String> photoPaths;
  final String? notes;
  final String? favoriteBaitId;
  final double? averageSizeCm;
  final double? recordWeightKg;
  final double? recordLengthCm;
  final String? color;
  final String? habitatNotes;
  final String? customNotes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fish({
    required this.id,
    required this.name,
    this.category,
    this.photoPaths = const [],
    this.notes,
    this.favoriteBaitId,
    this.averageSizeCm,
    this.recordWeightKg,
    this.recordLengthCm,
    this.color,
    this.habitatNotes,
    this.customNotes,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Fish copyWith({
    String? name,
    String? category,
    List<String>? photoPaths,
    String? notes,
    String? favoriteBaitId,
    double? averageSizeCm,
    double? recordWeightKg,
    double? recordLengthCm,
    String? color,
    String? habitatNotes,
    String? customNotes,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Fish(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      photoPaths: photoPaths ?? this.photoPaths,
      notes: notes ?? this.notes,
      favoriteBaitId: favoriteBaitId ?? this.favoriteBaitId,
      averageSizeCm: averageSizeCm ?? this.averageSizeCm,
      recordWeightKg: recordWeightKg ?? this.recordWeightKg,
      recordLengthCm: recordLengthCm ?? this.recordLengthCm,
      color: color ?? this.color,
      habitatNotes: habitatNotes ?? this.habitatNotes,
      customNotes: customNotes ?? this.customNotes,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'notes': notes,
      'favorite_bait_id': favoriteBaitId,
      'average_size_cm': averageSizeCm,
      'record_weight_kg': recordWeightKg,
      'record_length_cm': recordLengthCm,
      'color': color,
      'habitat_notes': habitatNotes,
      'custom_notes': customNotes,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Fish.fromMap(Map<String, Object?> map) {
    return Fish(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      notes: map['notes'] as String?,
      favoriteBaitId: map['favorite_bait_id'] as String?,
      averageSizeCm: (map['average_size_cm'] as num?)?.toDouble(),
      recordWeightKg: (map['record_weight_kg'] as num?)?.toDouble(),
      recordLengthCm: (map['record_length_cm'] as num?)?.toDouble(),
      color: map['color'] as String?,
      habitatNotes: map['habitat_notes'] as String?,
      customNotes: map['custom_notes'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
