import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urban_navigator_osm_app/models/data_models.dart';
import 'package:latlong2/latlong.dart' as ll;

class ApiService {
  final String _openWeatherMapApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  final List<PointOfInterest> _mockPois = [
    PointOfInterest(
      id: 'osm_poi_central_park',
      name: 'Central Park',
      address: 'New York, NY',
      latitude: 40.785091,
      longitude: -73.968285,
      type: 'park',
      wheelchairAccessible: true,
      hasAccessibleRestroom: true,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Park',
    ),
    PointOfInterest(
      id: 'osm_poi_city_library',
      name: 'City Library',
      address: '123 Main St, New York',
      latitude: 40.758000,
      longitude: -73.985500,
      type: 'library',
      wheelchairAccessible: true,
      hasAccessibleRestroom: false,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Library',
    ),
    PointOfInterest(
      id: 'osm_poi_metro_station_a',
      name: 'Metro Station A',
      address: 'Downtown Metro, New York',
      latitude: 40.712800,
      longitude: -74.006000,
      type: 'metro_station',
      wheelchairAccessible: false,
      hasRamp: false,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Metro',
    ),
    PointOfInterest(
      id: 'osm_poi_accessible_cafe',
      name: 'Accessible Cafe',
      address: '456 Elm St, New York',
      latitude: 40.765000,
      longitude: -73.975000,
      type: 'cafe',
      wheelchairAccessible: true,
      hasAccessibleRestroom: true,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Cafe',
    ),
    PointOfInterest(
      id: 'osm_poi_city_hospital',
      name: 'City Hospital',
      address: '789 Health St, New York',
      latitude: 40.720000,
      longitude: -73.990000,
      type: 'hospital',
      wheelchairAccessible: true,
      hasAccessibleRestroom: true,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Hospital',
    ),
    PointOfInterest(
      id: 'osm_poi_national_museum',
      name: 'National Museum',
      address: '100 Culture Rd, New York',
      latitude: 40.730000,
      longitude: -73.980000,
      type: 'museum',
      wheelchairAccessible: true,
      hasAccessibleRestroom: true,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Museum',
    ),
    PointOfInterest(
      id: 'osm_poi_mega_mall',
      name: 'Mega Shopping Mall',
      address: '200 Retail Blvd, New York',
      latitude: 40.740000,
      longitude: -73.970000,
      type: 'shopping_mall',
      wheelchairAccessible: true,
      hasAccessibleRestroom: true,
      hasRamp: true,
      imageUrl: 'https://placehold.co/100x100/A8C0D8/333333?text=Mall',
    ),
  ];

  List<PointOfInterest> get mockPois => _mockPois;

  Map<String, dynamic> _mockRealtimeData = {
    'traffic': 'moderate',
    'weather': 'clear',
    'incidents': [],
    'bus_delays': {'route_101': 5},
  };

  // --- OSM के लिए मॉक प्लेस सर्च और डिटेल्स ---

  Future<List<Map<String, dynamic>>> getPlaceAutocompleteSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return [];

    return _mockPois
        .where((poi) => poi.name.toLowerCase().contains(query.toLowerCase()) ||
        poi.address.toLowerCase().contains(query.toLowerCase()))
        .map((poi) => {'description': '${poi.name}, ${poi.address}', 'place_id': poi.id})
        .toList();
  }

  Future<PointOfInterest> getPlaceDetails(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockPois.firstWhere((poi) => poi.id == placeId,
        orElse: () => _mockPois.first);
  }

  Future<List<PointOfInterest>> searchPois(String query, AccessibilityProfile profile) async {
    List<PointOfInterest> results = _mockPois.where((poi) {
      bool matchesQuery = poi.name.toLowerCase().contains(query.toLowerCase()) ||
          poi.address.toLowerCase().contains(query.toLowerCase());

      bool matchesProfile = true;
      if (profile.wheelchairAccessible && !poi.wheelchairAccessible) matchesProfile = false;
      if (profile.accessibleRestroomNeeded && !poi.hasAccessibleRestroom) matchesProfile = false;
      if (profile.avoidStairs && !poi.hasRamp) matchesProfile = false;

      return matchesQuery && matchesProfile;
    }).toList();

    return results;
  }

  // --- OSRM API से वास्तविक मार्ग पॉलीलाइन प्राप्त करने के लिए नया फ़ंक्शन ---
  Future<List<ll.LatLng>> getOSRMRoutePolyline(ll.LatLng start, ll.LatLng end) async {
    // OSRM डेमो सर्वर का उपयोग करें (उत्पादन के लिए अपना खुद का होस्ट करें)
    final String url =
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            List<dynamic> coords = geometry['coordinates'];
            // OSRM [longitude, latitude] लौटाता है, हमें [latitude, longitude] चाहिए
            return coords.map((c) => ll.LatLng(c[1], c[0])).toList();
          }
        }
        return []; // कोई मार्ग नहीं मिला
      } else {
        print('OSRM API Error: ${response.statusCode} ${response.reasonPhrase}');
        return [];
      }
    } catch (e) {
      print('Error fetching OSRM route: $e');
      return [];
    }
  }


  // --- मॉक रूट जनरेशन और क्राउडसोर्सिंग (पहले जैसा ही) ---

  Future<List<Route>> getAccessibleRoutes(
      PointOfInterest start, PointOfInterest end, AccessibilityProfile profile) async {
    await Future.delayed(const Duration(seconds: 2));

    List<Route> routes = [];

    final int busRoute101Delay = (_mockRealtimeData['bus_delays'] as Map<String, dynamic>?)?['route_101'] as int? ?? 0;

    List<RouteSegment> segments1 = [
      RouteSegment(
        id: 'seg1_1',
        description: 'Walk from ${start.name} to bus stop',
        distanceKm: 0.5,
        durationMinutes: 7,
        accessibilityNotes: 'Flat pavement, no stairs.',
        isAccessible: true,
        type: 'walk',
      ),
      RouteSegment(
        id: 'seg1_2',
        description: 'Bus Route 101 to near ${end.name}',
        distanceKm: 3.0,
        durationMinutes: 15 + busRoute101Delay,
        accessibilityNotes: 'Accessible bus, ramp available.',
        isAccessible: true,
        type: 'bus',
      ),
      RouteSegment(
        id: 'seg1_3',
        description: 'Walk from bus stop to ${end.name}',
        distanceKm: 0.2,
        durationMinutes: 3,
        accessibilityNotes: 'Short, flat walk.',
        isAccessible: true,
        type: 'walk',
      ),
    ];
    routes.add(
      Route(
        id: 'route1',
        name: 'Accessible Bus Route',
        totalDistanceKm: 3.7,
        totalDurationMinutes: 25 + busRoute101Delay,
        segments: segments1,
        isFullyAccessible: true,
        accessibilitySummary: 'Fully accessible, avoids stairs.',
      ),
    );

    if (!profile.avoidStairs && !profile.wheelchairAccessible) {
      List<RouteSegment> segments2 = [
        RouteSegment(
          id: 'seg2_1',
          description: 'Walk through park shortcut with stairs',
          distanceKm: 0.3,
          durationMinutes: 5,
          accessibilityNotes: 'Includes 2 flights of stairs.',
          isAccessible: false,
          type: 'walk',
        ),
        RouteSegment(
          id: 'seg2_2',
          description: 'Metro Line A to ${end.name}',
          distanceKm: 4.5,
          durationMinutes: 10,
          accessibilityNotes: 'Metro station has stairs, no elevator.',
          isAccessible: false,
          type: 'metro',
        ),
      ];
      routes.add(
        Route(
          id: 'route2',
          name: 'Fastest (Less Accessible)',
          totalDistanceKm: 4.8,
          totalDurationMinutes: 15,
          segments: segments2,
          isFullyAccessible: false,
          accessibilitySummary: 'Faster, but includes stairs at metro station.',
        ),
      );
    }

    return routes.where((route) {
      bool meetsProfile = true;
      if (profile.wheelchairAccessible && !route.isFullyAccessible) meetsProfile = false;
      if (profile.avoidCrowds && route.accessibilitySummary.contains('crowded')) meetsProfile = false;
      return meetsProfile;
    }).toList();
  }

  Future<bool> submitAccessibilityReport(
      String poiId, String issue, double lat, double lon, String photoUrl) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Report submitted for POI $poiId: $issue at ($lat, $lon)');
    return true;
  }

  Future<Map<String, dynamic>> getRealtimeUrbanData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockRealtimeData['traffic'] = (DateTime.now().second % 2 == 0) ? 'heavy' : 'light';
    _mockRealtimeData['weather'] = (DateTime.now().minute % 3 == 0) ? 'rainy' : 'clear';
    _mockRealtimeData['incidents'] = (DateTime.now().second % 10 == 0) ? ['road_closure_main_st'] : [];
    return _mockRealtimeData;
  }
}
