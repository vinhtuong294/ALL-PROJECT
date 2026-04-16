import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for address suggestions using OpenStreetMap Nominatim
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Search for address suggestions based on a query string
  Future<List<MapSuggestion>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&accept-language=vi');
      
      debugPrint('🗺️ [GEOCODING] GET $url');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MapSuggestion.fromJson(item)).toList();
      } else {
        debugPrint('❌ [GEOCODING] Error status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [GEOCODING] Error: $e');
      return [];
    }
  }
}

class MapSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  MapSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory MapSuggestion.fromJson(Map<String, dynamic> json) {
    return MapSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '0') ?? 0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0,
    );
  }

  @override
  String toString() => 'MapSuggestion($displayName, $lat, $lon)';
}
