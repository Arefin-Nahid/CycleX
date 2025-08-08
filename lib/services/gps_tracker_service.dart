import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DemoGPSTrackerService {
  // Singleton
  static final DemoGPSTrackerService _instance = DemoGPSTrackerService._internal();
  factory DemoGPSTrackerService() => _instance;
  DemoGPSTrackerService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _gpsSubscription;

  // Callbacks
  Function(String trackerId, LatLng position, Map<String, dynamic> data)? onLocationUpdate;
  Function(String trackerId)? onTrackerDisconnected;

  /// Start listening to GPS tracker updates.
  /// If [specificTrackerId] is provided, listens only to that tracker.
  void startListening({String? specificTrackerId}) {
    _stopListening();

    final String path = specificTrackerId != null
        ? 'demo_gps_trackers/$specificTrackerId/location'
        : 'demo_gps_trackers';

    _gpsSubscription = _database.child(path).onValue.listen(
          (DatabaseEvent event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists) return;
        _processGPSData(snapshot, specificTrackerId: specificTrackerId);
      },
      onError: (error) {
        // You could surface this via another callback if desired
        // ignore: avoid_print
        print('Demo GPS Tracker Error: $error');
      },
      onDone: () {
        // Stream closed (network loss or permission change)
        if (specificTrackerId != null) {
          onTrackerDisconnected?.call(specificTrackerId);
        }
      },
    );
  }

  /// Stop listening to GPS updates.
  void _stopListening() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  /// Process GPS data from Firebase.
  /// Handles both "single location node" and "all trackers" modes.
  void _processGPSData(
      DataSnapshot snapshot, {
        String? specificTrackerId,
      }) {
    try {
      final dynamic raw = snapshot.value;

      if (raw == null) return;

      // Case 1: Listening to a single tracker location node:
      // Path: demo_gps_trackers/{trackerId}/location
      // Snapshot key will be 'location' and value is the location map.
      if (snapshot.key == 'location') {
        final trackerId = snapshot.ref.parent?.key;
        if (trackerId != null && raw is Map) {
          _processSingleTrackerData(trackerId, raw);
        }
        return;
      }

      // Case 2: Listening to root 'demo_gps_trackers'
      // raw should be a map of trackers.
      if (raw is Map) {
        raw.forEach((trackerId, trackerNode) {
          if (trackerNode is Map && trackerNode['location'] is Map) {
            _processSingleTrackerData(trackerId.toString(), trackerNode['location']);
          }
        });
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Error processing GPS data: $e\n$st');
    }
  }

  /// Process a single tracker's location payload.
  void _processSingleTrackerData(String trackerId, Map<dynamic, dynamic> locationData) {
    try {
      final double? latitude = _parseDouble(locationData['latitude']);
      final double? longitude = _parseDouble(locationData['longitude']);

      if (latitude == null || longitude == null) return;

      final LatLng position = LatLng(latitude, longitude);

      final Map<String, dynamic> data = {
        'timestamp': locationData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        'speed': _parseDouble(locationData['speed']) ?? 0.0,
        'battery': _parseDouble(locationData['battery']) ?? 100.0,
        'signal_strength': _parseDouble(locationData['signal_strength']) ?? -100.0,
        'accuracy': _parseDouble(locationData['accuracy']) ?? 5.0,
      };

      onLocationUpdate?.call(trackerId, position, data);
    } catch (e, st) {
      // ignore: avoid_print
      print('Error processing tracker $trackerId data: $e\n$st');
    }
  }

  /// Safe numeric parsing to double.
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Fetch all current trackers and their last known location info.
  Future<Map<String, Map<String, dynamic>>> getAllTrackers() async {
    try {
      final DatabaseEvent event = await _database.child('demo_gps_trackers').once();
      final Map<String, Map<String, dynamic>> trackers = {};

      final dynamic raw = event.snapshot.value;
      if (raw is Map) {
        raw.forEach((trackerId, trackerNode) {
          if (trackerNode is Map && trackerNode['location'] is Map) {
            final loc = trackerNode['location'] as Map<dynamic, dynamic>;
            final double? lat = _parseDouble(loc['latitude']);
            final double? lng = _parseDouble(loc['longitude']);
            if (lat != null && lng != null) {
              trackers[trackerId.toString()] = {
                'latitude': lat,
                'longitude': lng,
                'timestamp': loc['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
                'speed': _parseDouble(loc['speed']) ?? 0.0,
                'battery': _parseDouble(loc['battery']) ?? 100.0,
                'signal_strength': _parseDouble(loc['signal_strength']) ?? -100.0,
                'accuracy': _parseDouble(loc['accuracy']) ?? 5.0,
              };
            }
          }
        });
      }

      return trackers;
    } catch (e, st) {
      // ignore: avoid_print
      print('Error getting all trackers: $e\n$st');
      return {};
    }
  }

  /// Send (or overwrite) a demo GPS location for a tracker.
  Future<void> sendDemoGPSData({
    required String trackerId,
    required double latitude,
    required double longitude,
    double speed = 0.0,
    double battery = 100.0,
    double signalStrength = -65.0,
    double accuracy = 5.0,
    int? timestamp,
  }) async {
    try {
      await _database.child('demo_gps_trackers/$trackerId/location').set({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
        'speed': speed,
        'battery': battery,
        'signal_strength': signalStrength,
        'accuracy': accuracy,
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Error sending demo GPS data: $e\n$st');
    }
  }

  /// Simulate a moving tracker from [startPosition] to [endPosition] over [duration].
  /// Produces regular updates (default 2 per second).
  Timer? startDemoSimulation({
    required String trackerId,
    required LatLng startPosition,
    required LatLng endPosition,
    Duration duration = const Duration(minutes: 5),
    int updatesPerSecond = 2,
    double initialBattery = 100.0,
    double batteryDrainPerUpdate = 0.1,
  }) {
    final int totalUpdates = (duration.inSeconds * updatesPerSecond).clamp(1, 1 << 31);
    final double latStep = (endPosition.latitude - startPosition.latitude) / totalUpdates;
    final double lngStep = (endPosition.longitude - startPosition.longitude) / totalUpdates;

    int updateCount = 0;
    double currentBattery = initialBattery;

    final Timer timer = Timer.periodic(
      Duration(milliseconds: (1000 / updatesPerSecond).round()),
          (t) {
        if (updateCount >= totalUpdates) {
          t.cancel();
          return;
        }

        final double currentLat = startPosition.latitude + (latStep * updateCount);
        final double currentLng = startPosition.longitude + (lngStep * updateCount);

        currentBattery = (currentBattery - batteryDrainPerUpdate).clamp(0.0, 100.0);

        sendDemoGPSData(
          trackerId: trackerId,
          latitude: currentLat,
          longitude: currentLng,
          speed: 10.0 + (updateCount % 12), // simple varying pattern
          battery: currentBattery,
          signalStrength: -60.0 - (updateCount % 10),
        );

        updateCount++;
      },
    );

    return timer;
  }

  /// Clean up.
  void dispose() {
    _stopListening();
  }
}