import 'package:flutter/material.dart';
import 'package:urban_navigator_osm_app/models/data_models.dart'; // सुनिश्चित करें कि यह पथ सही है

class AccessibilityProfileScreen extends StatefulWidget {
  final AccessibilityProfile currentProfile;
  final Function(AccessibilityProfile) onSave;

  const AccessibilityProfileScreen({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<AccessibilityProfileScreen> createState() => _AccessibilityProfileScreenState();
}

class _AccessibilityProfileScreenState extends State<AccessibilityProfileScreen> {
  late AccessibilityProfile _editingProfile;

  @override
  void initState() {
    super.initState();
    _editingProfile = AccessibilityProfile(
      wheelchairAccessible: widget.currentProfile.wheelchairAccessible,
      avoidStairs: widget.currentProfile.avoidStairs,
      avoidCrowds: widget.currentProfile.avoidCrowds,
      audioGuidancePreferred: widget.currentProfile.audioGuidancePreferred,
      visualAlertsPreferred: widget.currentProfile.visualAlertsPreferred,
      accessibleRestroomNeeded: widget.currentProfile.accessibleRestroomNeeded,
      quietRoutePreferred: widget.currentProfile.quietRoutePreferred,
      maxIncline: widget.currentProfile.maxIncline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_editingProfile);
              Navigator.of(context).pop();
            },
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade200],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobility Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                    ),
                    SwitchListTile(
                      title: const Text('Wheelchair Accessible'),
                      value: _editingProfile.wheelchairAccessible,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.wheelchairAccessible = value;
                          if (value) {
                            _editingProfile.avoidStairs = true; // Wheelchair implies avoiding stairs
                          }
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    SwitchListTile(
                      title: const Text('Avoid Stairs'),
                      value: _editingProfile.avoidStairs,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.avoidStairs = value;
                          if (!value && _editingProfile.wheelchairAccessible) {
                            _editingProfile.wheelchairAccessible = false; // Cannot avoid stairs if not wheelchair accessible
                          }
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    ListTile(
                      title: const Text('Max Incline Preference'),
                      subtitle: Slider(
                        value: _editingProfile.maxIncline,
                        min: 0.01,
                        max: 0.20,
                        divisions: 19,
                        label: '${(_editingProfile.maxIncline * 100).toStringAsFixed(0)}%',
                        onChanged: (double value) {
                          setState(() {
                            _editingProfile.maxIncline = value;
                          });
                        },
                        activeColor: Colors.blueGrey.shade700,
                        inactiveColor: Colors.blueGrey.shade200,
                      ),
                      trailing: Text('${(_editingProfile.maxIncline * 100).toStringAsFixed(0)}%'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensory & Comfort Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                    ),
                    SwitchListTile(
                      title: const Text('Avoid Crowded Areas'),
                      value: _editingProfile.avoidCrowds,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.avoidCrowds = value;
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    SwitchListTile(
                      title: const Text('Prefer Quieter Routes'),
                      value: _editingProfile.quietRoutePreferred,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.quietRoutePreferred = value;
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    SwitchListTile(
                      title: const Text('Audio Guidance Preferred'),
                      value: _editingProfile.audioGuidancePreferred,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.audioGuidancePreferred = value;
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    SwitchListTile(
                      title: const Text('Visual Alerts Preferred'),
                      value: _editingProfile.visualAlertsPreferred,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.visualAlertsPreferred = value;
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facility Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                    ),
                    SwitchListTile(
                      title: const Text('Accessible Restroom Needed'),
                      value: _editingProfile.accessibleRestroomNeeded,
                      onChanged: (bool value) {
                        setState(() {
                          _editingProfile.accessibleRestroomNeeded = value;
                        });
                      },
                      activeColor: Colors.blueGrey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
