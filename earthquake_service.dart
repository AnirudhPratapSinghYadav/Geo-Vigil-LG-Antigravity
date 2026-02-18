import 'dart:convert';
import 'package:http/http.dart' as http;

class Earthquake {
  final double mag;
  final String place;
  final int time;
  final double lat;
  final double lon;
  final double depth;

  Earthquake({
    required this.mag,
    required this.place,
    required this.time,
    required this.lat,
    required this.lon,
    required this.depth,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    final geometry = json['geometry']['coordinates'];

    return Earthquake(
      // Explicitly casting to double to prevent 'int is not a subtype of double' errors
      mag: (props['mag'] as num).toDouble(),
      place: props['place'] ?? 'Unknown Location',
      time: props['time'] as int,
      lon: (geometry[0] as num).toDouble(),
      lat: (geometry[1] as num).toDouble(),
      depth: (geometry[2] as num).toDouble(),
    );
  }
}

class EarthquakeService {
  // Using the 4.5+ magnitude feed for a cleaner dashboard
  static const String _url = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.geojson';

  Future<List<Earthquake>> getMajorEarthquakes() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];

        return features
            .map((e) => Earthquake.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load USGS Data');
      }
    } catch (e) {
      print('Seismic Data Error: $e');
      return [];
    }
  }
}