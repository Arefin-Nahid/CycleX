import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:CycleX/services/gps_tracker_service.dart';
import 'package:CycleX/models/gps_tracker.dart';
import 'package:CycleX/constants/colors.dart';
import 'package:intl/intl.dart';

class DemoGPSTrackerDetailsScreen extends StatefulWidget {
  final String trackerId;
  
  const DemoGPSTrackerDetailsScreen({
    Key? key,
    required this.trackerId,
  }) : super(key: key);

  @override
  State<DemoGPSTrackerDetailsScreen> createState() => _DemoGPSTrackerDetailsScreenState();
}

class _DemoGPSTrackerDetailsScreenState extends State<DemoGPSTrackerDetailsScreen> {
  GoogleMapController? _mapController;
  DemoGPSTracker? _currentTracker;
  List<DemoGPSTracker> _trackerHistory = [];
  bool _isLoading = true;
  bool _isTracking = false;
  
  final DemoGPSTrackerService _gpsService = DemoGPSTrackerService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _loadTrackerData();
    _setupGPSListener();
  }

  void _setupGPSListener() {
    _gpsService.onLocationUpdate = (String trackerId, LatLng position, Map<String, dynamic> data) {
      if (trackerId == widget.trackerId) {
        setState(() {
          _currentTracker = DemoGPSTracker(
            trackerId: trackerId,
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
            speed: data['speed'] ?? 0.0,
            battery: data['battery'] ?? 100.0,
            signalStrength: data['signal_strength'] ?? -100.0,
            accuracy: data['accuracy'] ?? 5.0,
          );
          
          // Add to history if it's a new position
          if (_trackerHistory.isEmpty || 
              _trackerHistory.last.latitude != position.latitude ||
              _trackerHistory.last.longitude != position.longitude) {
            _trackerHistory.add(_currentTracker!);
          }
        });
      }
    };
  }

  Future<void> _loadTrackerData() async {
    setState(() => _isLoading = true);
    
    try {
      final trackers = await _gpsService.getAllTrackers();
      final trackerData = trackers[widget.trackerId];
      
      if (trackerData != null) {
        setState(() {
          _currentTracker = DemoGPSTracker(
            trackerId: widget.trackerId,
            latitude: trackerData['latitude'],
            longitude: trackerData['longitude'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(trackerData['timestamp']),
            speed: trackerData['speed'] ?? 0.0,
            battery: trackerData['battery'] ?? 100.0,
            signalStrength: trackerData['signal_strength'] ?? -100.0,
            accuracy: trackerData['accuracy'] ?? 5.0,
          );
          _trackerHistory = [_currentTracker!];
        });
      }
    } catch (e) {
      print('Error loading tracker data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      _gpsService.startListening(specificTrackerId: widget.trackerId);
      _showSnackBar('Started tracking ${widget.trackerId}', Colors.green);
    } else {
      _gpsService.dispose();
      _showSnackBar('Stopped tracking ${widget.trackerId}', Colors.orange);
    }
  }

  void _sendTestData() {
    if (_currentTracker != null) {
      _gpsService.sendDemoGPSData(
        trackerId: widget.trackerId,
        latitude: _currentTracker!.latitude + (DateTime.now().millisecond / 1000000),
        longitude: _currentTracker!.longitude + (DateTime.now().millisecond / 1000000),
        speed: 15.0 + (DateTime.now().second % 10),
        battery: _currentTracker!.battery - 1.0,
      );
      _showSnackBar('Test data sent', Colors.blue);
    }
  }

  void _clearHistory() {
    setState(() {
      _trackerHistory.clear();
    });
    _showSnackBar('History cleared', Colors.red);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracker: ${widget.trackerId}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleTracking,
            tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentTracker == null
              ? const Center(child: Text('No tracker data available'))
              : Column(
                  children: [
                    // Map Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_currentTracker!.latitude, _currentTracker!.longitude),
                              zoom: 16.0,
                            ),
                            onMapCreated: (controller) => _mapController = controller,
                            markers: {
                              Marker(
                                markerId: MarkerId(widget.trackerId),
                                position: LatLng(_currentTracker!.latitude, _currentTracker!.longitude),
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                infoWindow: InfoWindow(
                                  title: 'GPS Tracker: ${widget.trackerId}',
                                  snippet: 'Last updated: ${_dateFormat.format(_currentTracker!.timestamp)}',
                                ),
                              ),
                            },
                            polylines: _trackerHistory.length > 1
                                ? {
                                    Polyline(
                                      polylineId: PolylineId('${widget.trackerId}_path'),
                                      points: _trackerHistory
                                          .map((tracker) => LatLng(tracker.latitude, tracker.longitude))
                                          .toList(),
                                      color: Colors.red,
                                      width: 4,
                                      geodesic: true,
                                    ),
                                  }
                                : {},
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: false,
                            mapType: MapType.normal,
                            compassEnabled: true,
                          ),
                        ),
                      ),
                    ),
                    
                    // Tracker Info Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracker Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Status', _isTracking ? 'Active' : 'Inactive', _isTracking ? Colors.green : Colors.grey),
                          _buildInfoRow('Latitude', _currentTracker!.latitude.toStringAsFixed(6)),
                          _buildInfoRow('Longitude', _currentTracker!.longitude.toStringAsFixed(6)),
                          _buildInfoRow('Speed', '${_currentTracker!.speed.toStringAsFixed(1)} km/h'),
                          _buildInfoRow('Battery', '${_currentTracker!.battery.toStringAsFixed(1)}%'),
                          _buildInfoRow('Signal', '${_currentTracker!.signalStrength.toStringAsFixed(1)} dBm'),
                          _buildInfoRow('Accuracy', '${_currentTracker!.accuracy.toStringAsFixed(1)}m'),
                          _buildInfoRow('Last Update', _dateFormat.format(_currentTracker!.timestamp)),
                          _buildInfoRow('History Points', _trackerHistory.length.toString()),
                          
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _sendTestData,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send Test Data'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _clearHistory,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear History'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // History Section
                    if (_trackerHistory.length > 1)
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location History',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _trackerHistory.length,
                                  itemBuilder: (context, index) {
                                    final tracker = _trackerHistory[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.red,
                                          child: Text('${index + 1}'),
                                        ),
                                        title: Text(
                                          '${tracker.latitude.toStringAsFixed(6)}, ${tracker.longitude.toStringAsFixed(6)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        subtitle: Text(
                                          'Speed: ${tracker.speed.toStringAsFixed(1)} km/h • Battery: ${tracker.battery.toStringAsFixed(1)}%',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        trailing: Text(
                                          _dateFormat.format(tracker.timestamp),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        onTap: () => _centerOnLocation(tracker),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnLocation(DemoGPSTracker tracker) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(tracker.latitude, tracker.longitude),
            zoom: 18.0,
          ),
        ),
      );
    }
  }
}
