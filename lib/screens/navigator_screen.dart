import 'package:flutter/material.dart' hide Route;
import 'package:urban_navigator_osm_app/models/data_models.dart';
import 'package:urban_navigator_osm_app/services/api_service.dart';
import 'package:urban_navigator_osm_app/screens/accessibility_profile_screen.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as ll;

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  PointOfInterest? _startPoi;
  PointOfInterest? _endPoi;
  List<Route>? _suggestedRoutes;
  bool _isLoading = false;
  String? _errorMessage;

  AccessibilityProfile _userProfile = AccessibilityProfile();

  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  Timer? _debounce;

  final MapController _mapController = MapController();

  static const LatLng _initialCenter = LatLng(28.7041, 77.1025);

  // _predefinedSearchExamples list को हटा दिया गया है
  // final List<String> _predefinedSearchExamples = [
  //   'Central Park',
  //   'City Library',
  //   'Accessible Cafe',
  //   'Metro Station A',
  //   'City Hospital',
  //   'National Museum',
  //   'Mega Shopping Mall',
  // ];

  double? _distanceBetweenPois;
  List<ll.LatLng> _routePolylinePoints = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _updateMapMarkers();
  }

  @override
  void dispose() {
    _searchController.removeListener(() => _onSearchChanged(_searchController.text));
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.isNotEmpty) {
        _getAutocompleteSuggestions(text);
      } else {
        setState(() {
          _autocompleteSuggestions = [];
        });
      }
    });
  }

  Future<void> _getAutocompleteSuggestions(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final suggestions = await _apiService.getPlaceAutocompleteSuggestions(query);
      setState(() {
        _autocompleteSuggestions = suggestions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting suggestions: $e';
        _autocompleteSuggestions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion, bool isStartPoint) async {
    _searchController.text = suggestion['description'];
    _autocompleteSuggestions = [];

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final poi = await _apiService.getPlaceDetails(suggestion['place_id']);
      if (isStartPoint) {
        _startPoi = poi;
      } else {
        _endPoi = poi;
      }
      _updateMapMarkers();
      _calculateDistanceAndAnimateCamera();
    } catch (e) {
      _errorMessage = 'Error getting place details: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchAndSetPoi(String query, bool isStart) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<PointOfInterest> results = await _apiService.searchPois(query, _userProfile);
      if (results.isNotEmpty) {
        final poi = results.first;
        if (isStart) {
          _startPoi = poi;
        } else {
          _endPoi = poi;
        }
        _updateMapMarkers();
        _calculateDistanceAndAnimateCamera();
      } else {
        _errorMessage = 'No accessible POI found for "$query" matching your profile.';
      }
    } catch (e) {
      _errorMessage = 'Error searching POI: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Marker> _currentMarkers = [];

  void _updateMapMarkers() {
    final List<Marker> newMarkers = [];
    if (_startPoi != null) {
      newMarkers.add(
        Marker(
          point: LatLng(_startPoi!.latitude, _startPoi!.longitude),
          width: 80,
          height: 80,
            builder: (BuildContext context) => Icon(Icons.location_on)
        ),
      );
    }
    if (_endPoi != null) {
      newMarkers.add(
        Marker(
          point: LatLng(_endPoi!.latitude, _endPoi!.longitude),
          width: 80,
          height: 80,
            builder: (BuildContext context) => Icon(Icons.location_on)
        ),
      );
    }
    setState(() {
      _currentMarkers = newMarkers;
    });
  }

  void _calculateDistanceAndAnimateCamera() {
    if (_startPoi != null && _endPoi != null) {
      final distance = ll.Distance();
      final startLatLng = LatLng(_startPoi!.latitude, _startPoi!.longitude);
      final endLatLng = LatLng(_endPoi!.latitude, _endPoi!.longitude);

      final double meters = distance(startLatLng, endLatLng);
      setState(() {
        _distanceBetweenPois = meters / 1000;
        // _routePolylinePoints = [startLatLng, endLatLng]; // अब यह OSRM से आएगा
      });

      _mapController.fitBounds(
        LatLngBounds(startLatLng, endLatLng),
        options: FitBoundsOptions(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 100,
            bottom: 200,
            left: 50,
            right: 50,
          ),
        ),
      );
    } else {
      setState(() {
        _distanceBetweenPois = null;
        _routePolylinePoints = [];
      });
    }
  }

  Future<void> _findRoutes() async {
    if (_startPoi == null || _endPoi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end points.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestedRoutes = null;
      _routePolylinePoints = []; // नई खोज पर पॉलीलाइन साफ करें
    });

    try {
      final polylinePoints = await _apiService.getOSRMRoutePolyline(
        LatLng(_startPoi!.latitude, _startPoi!.longitude),
        LatLng(_endPoi!.latitude, _endPoi!.longitude),
      );
      setState(() {
        _routePolylinePoints = polylinePoints;
      });

      // मॉक रूट सुझाव प्राप्त करें (आप इसे बाद में वास्तविक मार्ग API से बदल सकते हैं)
      List<Route> routes = await _apiService.getAccessibleRoutes(_startPoi!, _endPoi!, _userProfile);
      if (routes.isNotEmpty) {
        _suggestedRoutes = routes;
      } else {
        _errorMessage = 'No accessible routes found for your selection and profile.';
      }
    } catch (e) {
      _errorMessage = 'Error finding routes: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAccessibilityProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccessibilityProfileScreen(
          currentProfile: _userProfile,
          onSave: (newProfile) {
            setState(() {
              _userProfile = newProfile;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile Saved!')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitMockCrowdsourcingReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final bool success = await _apiService.submitAccessibilityReport(
        'poi_test_id',
        'Broken ramp at main entrance',
        40.7123,
        -74.0056,
        'https://placehold.co/100x100/FF0000/FFFFFF?text=Broken+Ramp',
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crowdsourcing Report Submitted! (Check Console)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urban Navigator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            onPressed: _openAccessibilityProfile,
            tooltip: 'Accessibility Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings Tapped!')),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _initialCenter,
                zoom: 12.0,
                keepAlive: true,
                onTap: (tapPosition, latLng) {
                  print('Map tapped at: $latLng');
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.urban_navigator_osm_app',
                ),
                MarkerLayer(
                  markers: _currentMarkers,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolylinePoints,
                      color: Colors.blue,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _startPoi == null ? 'Search start point...' : 'Search end point...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.blueGrey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _autocompleteSuggestions = [];
                            if (_startPoi != null && _endPoi == null) {
                              _startPoi = null;
                            } else if (_endPoi != null) {
                              _endPoi = null;
                            }
                            _suggestedRoutes = null;
                            _updateMapMarkers();
                            _calculateDistanceAndAnimateCamera();
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    onChanged: (value) => _onSearchChanged(value),
                    onSubmitted: (value) {
                      if (_autocompleteSuggestions.isNotEmpty) {
                        _selectSuggestion(_autocompleteSuggestions.first, _startPoi == null);
                      } else {
                        _searchAndSetPoi(value, _startPoi == null);
                      }
                      _searchController.clear();
                      _autocompleteSuggestions = [];
                    },
                  ),
                ),
                if (_autocompleteSuggestions.isNotEmpty)
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(top: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _autocompleteSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _autocompleteSuggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () {
                            _selectSuggestion(suggestion, _startPoi == null);
                            _searchController.clear();
                            _autocompleteSuggestions = [];
                          },
                        );
                      },
                    ),
                  ),
                // Removed the else if (_searchController.text.isEmpty) block
                if (_startPoi != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('Start: ${_startPoi!.name}'),
                      onDeleted: () {
                        setState(() {
                          _startPoi = null;
                          _suggestedRoutes = null;
                          _updateMapMarkers();
                          _calculateDistanceAndAnimateCamera();
                        });
                      },
                      deleteIcon: const Icon(Icons.cancel),
                    ),
                  ),
                if (_endPoi != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('End: ${_endPoi!.name}'),
                      onDeleted: () {
                        setState(() {
                          _endPoi = null;
                          _suggestedRoutes = null;
                          _updateMapMarkers();
                          _calculateDistanceAndAnimateCamera();
                        });
                      },
                      deleteIcon: const Icon(Icons.cancel),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey)),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_suggestedRoutes == null && !_isLoading && _errorMessage == null)
                    Column(
                      children: [
                        Text(
                          'Route Suggestions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your personalized routes will appear here based on your accessibility profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade500),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _startPoi != null && _endPoi != null ? _findRoutes : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          child: const Text('Find Accessible Routes'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _submitMockCrowdsourcingReport,
                          icon: const Icon(Icons.report_problem, color: Colors.white),
                          label: const Text('Submit Mock Accessibility Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  if (_suggestedRoutes != null && _suggestedRoutes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggested Routes (${_suggestedRoutes!.length})',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestedRoutes!.length,
                          itemBuilder: (context, index) {
                            final route = _suggestedRoutes![index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              child: ExpansionTile(
                                leading: Icon(
                                  route.isFullyAccessible ? Icons.check_circle : Icons.warning,
                                  color: route.isFullyAccessible ? Colors.green : Colors.orange,
                                ),
                                title: Text(
                                  route.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${route.totalDurationMinutes} mins • ${route.totalDistanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(color: Colors.blueGrey.shade600),
                                ),
                                children: route.segments.map((segment) {
                                  return ListTile(
                                    leading: Icon(
                                      segment.type == 'walk'
                                          ? Icons.directions_walk
                                          : segment.type == 'bus'
                                          ? Icons.directions_bus
                                          : Icons.subway,
                                      color: Colors.blueGrey,
                                    ),
                                    title: Text(segment.description),
                                    subtitle: Text(
                                      '${segment.durationMinutes} mins • ${segment.distanceKm.toStringAsFixed(1)} km\n${segment.accessibilityNotes}',
                                      style: TextStyle(
                                        color: segment.isAccessible ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  if (_suggestedRoutes != null && _suggestedRoutes!.isEmpty && !_isLoading && _errorMessage == null)
                    Column(
                      children: [
                        Text(
                          'No routes found matching your criteria.',
                          style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _startPoi != null && _endPoi != null ? _findRoutes : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          child: const Text('Retry Route Search'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
