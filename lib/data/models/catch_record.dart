import '../../core/utils/json_list_codec.dart';

class CatchRecord {
  final String id;
  final String? fishId;
  final String? tripId;
  final String? spotId;
  final DateTime date;
  final double? weightKg;
  final double? lengthCm;
  final int quantity;
  final double? latitude;
  final double? longitude;
  final List<String> photoPaths;
  final String? baitId;
  final String? lureEquipmentId;
  final String? rodEquipmentId;
  final String? reelEquipmentId;
  final String? lineEquipmentId;
  final String? hookEquipmentId;
  final String? method;
  final String? weatherText;
  final double? waterTempC;
  final double? airTempC;
  final String? windText;
  final double? pressureHpa;
  final String? waterClarity;
  final String? waterLevel;
  final String? notes;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CatchRecord({
    required this.id,
    this.fishId,
    this.tripId,
    this.spotId,
    required this.date,
    this.weightKg,
    this.lengthCm,
    this.quantity = 1,
    this.latitude,
    this.longitude,
    this.photoPaths = const [],
    this.baitId,
    this.lureEquipmentId,
    this.rodEquipmentId,
    this.reelEquipmentId,
    this.lineEquipmentId,
    this.hookEquipmentId,
    this.method,
    this.weatherText,
    this.waterTempC,
    this.airTempC,
    this.windText,
    this.pressureHpa,
    this.waterClarity,
    this.waterLevel,
    this.notes,
    this.rating = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  CatchRecord copyWith({
    String? fishId,
    String? tripId,
    bool clearTripId = false,
    String? spotId,
    DateTime? date,
    double? weightKg,
    double? lengthCm,
    int? quantity,
    double? latitude,
    double? longitude,
    List<String>? photoPaths,
    String? baitId,
    String? lureEquipmentId,
    String? rodEquipmentId,
    String? reelEquipmentId,
    String? lineEquipmentId,
    String? hookEquipmentId,
    String? method,
    String? weatherText,
    double? waterTempC,
    double? airTempC,
    String? windText,
    double? pressureHpa,
    String? waterClarity,
    String? waterLevel,
    String? notes,
    int? rating,
    DateTime? updatedAt,
  }) {
    return CatchRecord(
      id: id,
      fishId: fishId ?? this.fishId,
      tripId: clearTripId ? null : (tripId ?? this.tripId),
      spotId: spotId ?? this.spotId,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      quantity: quantity ?? this.quantity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoPaths: photoPaths ?? this.photoPaths,
      baitId: baitId ?? this.baitId,
      lureEquipmentId: lureEquipmentId ?? this.lureEquipmentId,
      rodEquipmentId: rodEquipmentId ?? this.rodEquipmentId,
      reelEquipmentId: reelEquipmentId ?? this.reelEquipmentId,
      lineEquipmentId: lineEquipmentId ?? this.lineEquipmentId,
      hookEquipmentId: hookEquipmentId ?? this.hookEquipmentId,
      method: method ?? this.method,
      weatherText: weatherText ?? this.weatherText,
      waterTempC: waterTempC ?? this.waterTempC,
      airTempC: airTempC ?? this.airTempC,
      windText: windText ?? this.windText,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      waterClarity: waterClarity ?? this.waterClarity,
      waterLevel: waterLevel ?? this.waterLevel,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fish_id': fishId,
      'trip_id': tripId,
      'spot_id': spotId,
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'length_cm': lengthCm,
      'quantity': quantity,
      'latitude': latitude,
      'longitude': longitude,
      'photo_paths': JsonListCodec.encode(photoPaths),
      'bait_id': baitId,
      'lure_equipment_id': lureEquipmentId,
      'rod_equipment_id': rodEquipmentId,
      'reel_equipment_id': reelEquipmentId,
      'line_equipment_id': lineEquipmentId,
      'hook_equipment_id': hookEquipmentId,
      'method': method,
      'weather_text': weatherText,
      'water_temp_c': waterTempC,
      'air_temp_c': airTempC,
      'wind_text': windText,
      'pressure_hpa': pressureHpa,
      'water_clarity': waterClarity,
      'water_level': waterLevel,
      'notes': notes,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CatchRecord.fromMap(Map<String, Object?> map) {
    return CatchRecord(
      id: map['id'] as String,
      fishId: map['fish_id'] as String?,
      tripId: map['trip_id'] as String?,
      spotId: map['spot_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      lengthCm: (map['length_cm'] as num?)?.toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      photoPaths: JsonListCodec.decode(map['photo_paths'] as String?),
      baitId: map['bait_id'] as String?,
      lureEquipmentId: map['lure_equipment_id'] as String?,
      rodEquipmentId: map['rod_equipment_id'] as String?,
      reelEquipmentId: map['reel_equipment_id'] as String?,
      lineEquipmentId: map['line_equipment_id'] as String?,
      hookEquipmentId: map['hook_equipment_id'] as String?,
      method: map['method'] as String?,
      weatherText: map['weather_text'] as String?,
      waterTempC: (map['water_temp_c'] as num?)?.toDouble(),
      airTempC: (map['air_temp_c'] as num?)?.toDouble(),
      windText: map['wind_text'] as String?,
      pressureHpa: (map['pressure_hpa'] as num?)?.toDouble(),
      waterClarity: map['water_clarity'] as String?,
      waterLevel: map['water_level'] as String?,
      notes: map['notes'] as String?,
      rating: map['rating'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
