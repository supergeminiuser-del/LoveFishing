import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// Пользовательская область на карте: зона ловли или опасная зона.
class MapArea {
  final String id;
  final String name;
  final String areaType; // fishing | danger
  final String? color;
  final List<LatLng> points;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MapArea({
    required this.id,
    required this.name,
    this.areaType = 'fishing',
    this.color,
    this.points = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  MapArea copyWith({
    String? name,
    String? areaType,
    String? color,
    List<LatLng>? points,
    String? notes,
    DateTime? updatedAt,
  }) {
    return MapArea(
      id: id,
      name: name ?? this.name,
      areaType: areaType ?? this.areaType,
      color: color ?? this.color,
      points: points ?? this.points,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static String _encodePoints(List<LatLng> points) {
    return jsonEncode(points.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList());
  }

  static List<LatLng> _decodePoints(String raw) {
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => LatLng((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'area_type': areaType,
      'color': color,
      'points': _encodePoints(points),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MapArea.fromMap(Map<String, Object?> map) {
    return MapArea(
      id: map['id'] as String,
      name: map['name'] as String,
      areaType: map['area_type'] as String? ?? 'fishing',
      color: map['color'] as String?,
      points: _decodePoints(map['points'] as String? ?? '[]'),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
