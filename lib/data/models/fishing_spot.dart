import '../../core/utils/json_list_codec.dart';

class FishingSpot {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String markerType; // spot | danger
  final String? color;
  final bool isFavorite;
  final String? notes;
  final List<String> photoPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FishingSpot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.markerType = 'spot',
    this.color,
    this.isFavorite = false,
    this.notes,
    this.photoPaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  FishingSpot copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? markerType,
    String? color,
    bool? isFavorite,
    String? notes,
    List<String>? photoPaths,
    DateTime? updatedAt,
  }) {
    return FishingSpot(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      markerType: markerType ?? this.markerType,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'marker_type': markerType,
      'color': color,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
      'photo_paths': JsonListCodec.encode(photoPaths),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FishingSpot.fromMap(Map<String, Object?> map) {
    return FishingSpot(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      markerType: map['marker_type'] as String? ?? 'spot',
      color: map['color'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
