import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final String name;
  final String? street;
  final String? neighbourhood;
  final String? locality;
  final String? region;
  final String? country;
  final String label;
  final LatLng coordinates;

  GeocodingResult({
    required this.name,
    this.street,
    this.neighbourhood,
    this.locality,
    this.region,
    this.country,
    required this.label,
    required this.coordinates,
  });

  factory GeocodingResult.fromFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List;

    return GeocodingResult(
      name: props['name'] as String? ?? '',
      street: props['street'] as String?,
      neighbourhood: props['neighbourhood'] as String?,
      locality: props['locality'] as String?,
      region: props['region'] as String?,
      country: props['country'] as String?,
      label: props['label'] as String? ?? props['name'] as String? ?? '',
      coordinates: LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      ),
    );
  }

  /// Returns the best short name for a territory
  String get territoryName {
    if (street != null && street!.isNotEmpty) return street!;
    if (neighbourhood != null && neighbourhood!.isNotEmpty) return neighbourhood!;
    if (name.isNotEmpty) return name;
    if (locality != null && locality!.isNotEmpty) return locality!;
    return 'Unknown Territory';
  }
}

class GeocodingService {
  static const String _apiKey = 'aba107a2-3f38-4e4a-8d0a-135e6ff7c2f7';
  static const String _baseUrl = 'https://api.stadiamaps.com/geocoding/v1';

  /// Autocomplete search — returns suggestions as user types
  Future<List<GeocodingResult>> autocomplete({
    required String query,
    double? focusLat,
    double? focusLng,
  }) async {
    if (query.trim().length < 2) return [];

    try {
      final params = {
        'text': query,
        'api_key': _apiKey,
        if (focusLat != null) 'focus.point.lat': focusLat.toString(),
        if (focusLng != null) 'focus.point.lon': focusLng.toString(),
      };
      final uri = Uri.parse('$_baseUrl/autocomplete').replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        return features
            .map((f) => GeocodingResult.fromFeature(f as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Forward geocoding — full search when user presses enter
  Future<List<GeocodingResult>> search({required String query}) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = {
        'text': query,
        'api_key': _apiKey,
      };
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        return features
            .map((f) => GeocodingResult.fromFeature(f as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocoding — get a place name from coordinates
  Future<GeocodingResult?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final params = {
        'point.lat': lat.toString(),
        'point.lon': lng.toString(),
        'api_key': _apiKey,
        'layers': 'street,venue,neighbourhood',
      };
      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          return GeocodingResult.fromFeature(features.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
