import '../../core/utils/json_list_codec.dart';

class Bait {
  final String id;
  final String name;
  final List<String> photoPaths;
  final String? brand;
  final String? type;
  final String? color;
  final String? size;
  final double? weightG;
  final String? notes;
  final int rating;
  final String? favoriteFishId;
  final String? bestSeason;
  final String? bestWeather;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bait({
    required this.id,
    required this.name,
    this.photoPaths = const [],
    this.brand,
    this.type,
    this.color,
    this.size,
    this.weightG,
    this.notes,
    this.rating = 0,
    this.favoriteFishId,
    this.bestSeason,
    this.bestWeather,
    required this.createdAt,
    required this.updatedAt,
  });

  Bait copyWith({
    String? name,
    List<String>? photoPaths,
    String? brand,
    String? type,
    String? color,
    String? size,
    double? weightG,
    String? notes,
    int? rating,
    String? favoriteFishId,
    String? bestSeason,
    String? bestWeather,
    DateTime? updatedAt,
  }) {
    return Bait(
      id: id,
      name: name ?? this.name,
      photoPaths: photoPaths ?? this.photoPaths,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      color: color ?? this.color,
      size: size ?? this.size,
      weightG: weightG ?? this.weightG,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      favoriteFishId: favoriteFishId ?? this.favoriteFishId,
      bestSeason: bestSeason ?? this.bestSeason,
      bestWeather: bestWeather ?? this.bestWeather,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'photo_paths': JsonListCodec.encode(photoPaths),
      'brand': brand,
      'type': type,
      'color': color,
      'size': size,
      'weight_g': weightG,
      'notes': notes,
      'rating': rating,
      'favorite_fish_id': favoriteFishId,
      'best_season': bestSeason,
      'best_weather': bestWeather,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bait.fromMap(Map<String, Object?> map) {
    return Bait(
      id: map['id'] as String,
      name: map['name'] as String,
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      brand: map['brand'] as String?,
      type: map['type'] as String?,
      color: map['color'] as String?,
      size: map['size'] as String?,
      weightG: (map['weight_g'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      rating: map['rating'] as int? ?? 0,
      favoriteFishId: map['favorite_fish_id'] as String?,
      bestSeason: map['best_season'] as String?,
      bestWeather: map['best_weather'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
