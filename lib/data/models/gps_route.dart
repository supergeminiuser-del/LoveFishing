import 'dart:convert';

import 'package:latlong2/latlong.dart';

class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RoutePoint({required this.latitude, required this.longitude, required this.timestamp});

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, Object?> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.toIso8601String(),
      };

  factory RoutePoint.fromJson(Map<String, Object?> json) => RoutePoint(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['ts'] as String),
      );
}

/// Записанный трек (маршрут) рыболова, привязанный опционально к рыбалке.
class GpsRoute {
  final String id;
  final String? tripId;
  final String? name;
  final List<RoutePoint> points;
  final double? distanceKm;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const GpsRoute({
    required this.id,
    this.tripId,
    this.name,
    this.points = const [],
    this.distanceKm,
    required this.startedAt,
    this.finishedAt,
  });

  static String _encode(List<RoutePoint> points) =>
      jsonEncode(points.map((e) => e.toJson()).toList());

  static List<RoutePoint> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => RoutePoint.fromJson(Map<String, Object?>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'points': _encode(points),
      'distance_km': distanceKm,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }

  factory GpsRoute.fromMap(Map<String, Object?> map) {
    return GpsRoute(
      id: map['id'] as String,
      tripId: map['trip_id'] as String?,
      name: map['name'] as String?,
      points: _decode(map['points'] as String? ?? '[]'),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null ? DateTime.parse(map['finished_at'] as String) : null,
    );
  }
}
