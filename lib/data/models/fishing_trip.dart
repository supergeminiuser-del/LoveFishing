import '../../core/utils/json_list_codec.dart';

class FishingTrip {
  final String id;
  final String? title;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final List<String> photoPaths;
  final double? distanceKm;
  final String? favoriteCatchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FishingTrip({
    required this.id,
    this.title,
    required this.startDate,
    this.endDate,
    this.notes,
    this.photoPaths = const [],
    this.distanceKm,
    this.favoriteCatchId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOngoing => endDate == null;

  FishingTrip copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? notes,
    List<String>? photoPaths,
    double? distanceKm,
    String? favoriteCatchId,
    DateTime? updatedAt,
  }) {
    return FishingTrip(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      distanceKm: distanceKm ?? this.distanceKm,
      favoriteCatchId: favoriteCatchId ?? this.favoriteCatchId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'photo_paths': JsonListCodec.encode(photoPaths),
      'distance_km': distanceKm,
      'favorite_catch_id': favoriteCatchId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FishingTrip.fromMap(Map<String, Object?> map) {
    return FishingTrip(
      id: map['id'] as String,
      title: map['title'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      notes: map['notes'] as String?,
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      favoriteCatchId: map['favorite_catch_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
