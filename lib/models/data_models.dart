import 'package:flutter/material.dart';

class AccessibilityProfile {
  bool wheelchairAccessible;
  bool avoidStairs;
  bool avoidCrowds;
  bool audioGuidancePreferred;
  bool visualAlertsPreferred;
  bool accessibleRestroomNeeded;
  bool quietRoutePreferred;
  double maxIncline; // e.g., 0.05 for 5% slope

  AccessibilityProfile({
    this.wheelchairAccessible = false,
    this.avoidStairs = false,
    this.avoidCrowds = false,
    this.audioGuidancePreferred = false,
    this.visualAlertsPreferred = false,
    this.accessibleRestroomNeeded = false,
    this.quietRoutePreferred = false,
    this.maxIncline = 0.10, // Default to 10% max incline
  });

  Map<String, dynamic> toJson() {
    return {
      'wheelchairAccessible': wheelchairAccessible,
      'avoidStairs': avoidStairs,
      'avoidCrowds': avoidCrowds,
      'audioGuidancePreferred': audioGuidancePreferred,
      'visualAlertsPreferred': visualAlertsPreferred,
      'accessibleRestroomNeeded': accessibleRestroomNeeded,
      'quietRoutePreferred': quietRoutePreferred,
      'maxIncline': maxIncline,
    };
  }

  factory AccessibilityProfile.fromJson(Map<String, dynamic> json) {
    return AccessibilityProfile(
      wheelchairAccessible: json['wheelchairAccessible'] ?? false,
      avoidStairs: json['avoidStairs'] ?? false,
      avoidCrowds: json['avoidCrowds'] ?? false,
      audioGuidancePreferred: json['audioGuidancePreferred'] ?? false,
      visualAlertsPreferred: json['visualAlertsPreferred'] ?? false,
      accessibleRestroomNeeded: json['accessibleRestroomNeeded'] ?? false,
      quietRoutePreferred: json['quietRoutePreferred'] ?? false,
      maxIncline: (json['maxIncline'] as num?)?.toDouble() ?? 0.10,
    );
  }
}

class PointOfInterest {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // e.g., 'restaurant', 'park', 'bus_stop'
  final bool wheelchairAccessible;
  final bool hasAccessibleRestroom;
  final bool hasRamp;
  final String imageUrl; // Placeholder for image URL

  PointOfInterest({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.wheelchairAccessible = false,
    this.hasAccessibleRestroom = false,
    this.hasRamp = false,
    this.imageUrl = 'https://placehold.co/100x100/E0E0E0/333333?text=POI',
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      type: json['type'],
      wheelchairAccessible: json['wheelchairAccessible'] ?? false,
      hasAccessibleRestroom: json['hasAccessibleRestroom'] ?? false,
      hasRamp: json['hasRamp'] ?? false,
      imageUrl: json['imageUrl'] ?? 'https://placehold.co/100x100/E0E0E0/333333?text=POI',
    );
  }
}

class RouteSegment {
  final String id;
  final String description;
  final double distanceKm;
  final int durationMinutes;
  final String accessibilityNotes;
  final bool isAccessible;
  final String type; // e.g., 'walk', 'bus', 'metro'

  RouteSegment({
    required this.id,
    required this.description,
    required this.distanceKm,
    required this.durationMinutes,
    this.accessibilityNotes = '',
    this.isAccessible = true,
    this.type = 'walk',
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      id: json['id'],
      description: json['description'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: json['durationMinutes'],
      accessibilityNotes: json['accessibilityNotes'] ?? '',
      isAccessible: json['isAccessible'] ?? true,
      type: json['type'] ?? 'walk',
    );
  }
}

class Route {
  final String id;
  final String name;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<RouteSegment> segments;
  final bool isFullyAccessible;
  final String accessibilitySummary;

  Route({
    required this.id,
    required this.name,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.segments,
    this.isFullyAccessible = true,
    this.accessibilitySummary = '',
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    var segmentsList = json['segments'] as List;
    List<RouteSegment> segments = segmentsList.map((i) => RouteSegment.fromJson(i)).toList();

    return Route(
      id: json['id'],
      name: json['name'],
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalDurationMinutes: json['totalDurationMinutes'],
      segments: segments,
      isFullyAccessible: json['isAccessible'] ?? true, // Changed from isFullyAccessible to isAccessible
      accessibilitySummary: json['accessibilitySummary'] ?? '',
    );
  }
}
