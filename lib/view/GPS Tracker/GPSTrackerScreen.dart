import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:CycleX/services/gps_tracker_service.dart';
import 'package:CycleX/constants/colors.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class DemoGPSTrackerScreen extends StatefulWidget {
  const DemoGPSTrackerScreen({Key? key}) : super(key: key);

  @override
  State<DemoGPSTrackerScreen> createState() => _DemoGPSTrackerScreenState();
}

class _DemoGPSTrackerScreenState extends State<DemoGPSTrackerScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _gpsMarkers = {};
  final Set<Polyline> _gpsPolylines = {};
  final Map<String, LatLng> _trackerPositions = {};
  final Map<String, List<LatLng>> _trackerPaths = {};
  
  bool _isListening = false;
  String _selectedTrackerId = 'demo_tracker_001';
  BitmapDescriptor? _gpsTrackerIcon;
  
  // Demo GPS Tracker Service
  final DemoGPSTrackerService _gpsService = DemoGPSTrackerService();

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _setupGPSListeners();
    _loadExistingTrackers();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _gpsTrackerIcon = await _createCustomGPSTrackerMarker();
    } catch (e) {
      print('Error creating GPS tracker marker: $e');
      _gpsTrackerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<BitmapDescriptor> _createCustomGPSTrackerMarker() async {
    const double size = 96;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.red;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw GPS tracker icon (satellite dish)
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      borderPaint,
    );

    // Draw signal waves
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        (size / 3) + (i * 8),
        borderPaint..strokeWidth = 2,
      );
    }

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _setupGPSListeners() {
    _gpsService.onLocationUpdate = (String trackerId, LatLng position, Map<String, dynamic> data) {
      setState(() {
        _trackerPositions[trackerId] = position;
        
        // Add to path history
        if (_trackerPaths[trackerId] == null) {
          _trackerPaths[trackerId] = [];
        }
        _trackerPaths[trackerId]!.add(position);
        
        // Update markers
        _updateGPSMarkers();
        _updateGPSPolylines();
      });
    };
  }

  Future<void> _loadExistingTrackers() async {
    try {
      final trackers = await _gpsService.getAllTrackers();
      setState(() {
        trackers.forEach((trackerId, data) {
          _trackerPositions[trackerId] = LatLng(data['latitude'], data['longitude']);
          _trackerPaths[trackerId] = [LatLng(data['latitude'], data['longitude'])];
        });
        _updateGPSMarkers();
        _updateGPSPolylines();
      });
    } catch (e) {
      print('Error loading existing trackers: $e');
    }
  }

  void _updateGPSMarkers() {
    _gpsMarkers.clear();
    _trackerPositions.forEach((trackerId, position) {
      _gpsMarkers.add(
        Marker(
          markerId: MarkerId('gps_$trackerId'),
          position: position,
          icon: _gpsTrackerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'GPS Tracker: $trackerId',
            snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
          ),
          onTap: () => _showTrackerDetails(trackerId),
        ),
      );
    });
  }

  void _updateGPSPolylines() {
    _gpsPolylines.clear();
    _trackerPaths.forEach((trackerId, path) {
      if (path.length > 1) {
        _gpsPolylines.add(
          Polyline(
            polylineId: PolylineId('path_$trackerId'),
            points: path,
            color: _getTrackerColor(trackerId),
            width: 4,
            geodesic: true,
          ),
        );
      }
    });
  }

  Color _getTrackerColor(String trackerId) {
    // Generate consistent color based on tracker ID
    int hash = trackerId.hashCode;
    return Color.fromARGB(255, hash % 256, (hash >> 8) % 256, (hash >> 16) % 256);
  }

  void _showTrackerDetails(String trackerId) {
    final position = _trackerPositions[trackerId];
    if (position == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('GPS Tracker: $trackerId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
            Text('Path Points: ${_trackerPaths[trackerId]?.length ?? 0}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _centerOnTracker(trackerId),
              child: const Text('Center on Tracker'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _centerOnTracker(String trackerId) {
    final position = _trackerPositions[trackerId];
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 18.0,
          ),
        ),
      );
    }
    Navigator.pop(context);
  }

  void _toggleGPSListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _gpsService.startListening();
      _showSnackBar('GPS tracking started', Colors.green);
    } else {
      _gpsService.dispose();
      _showSnackBar('GPS tracking stopped', Colors.orange);
    }
  }

  void _sendDemoData() {
    // Send a single demo GPS data point
    _gpsService.sendDemoGPSData(
      trackerId: _selectedTrackerId,
      latitude: 22.8999 + (DateTime.now().millisecond / 1000000), // Slight variation
      longitude: 89.5020 + (DateTime.now().millisecond / 1000000),
      speed: 15.0 + (DateTime.now().second % 10),
      battery: 85.0 - (DateTime.now().minute % 10),
    );
    _showSnackBar('Demo GPS data sent', Colors.blue);
  }

  void _startDemoSimulation() {
    final startPos = LatLng(22.8999, 89.5020);
    final endPos = LatLng(22.9050, 89.5080);
    
    _gpsService.startDemoSimulation(
      trackerId: _selectedTrackerId,
      startPosition: startPos,
      endPosition: endPos,
      duration: const Duration(minutes: 2),
    );
    
    _showSnackBar('Demo simulation started', Colors.green);
  }

  void _clearAllData() {
    setState(() {
      _trackerPositions.clear();
      _trackerPaths.clear();
      _gpsMarkers.clear();
      _gpsPolylines.clear();
    });
    _showSnackBar('All GPS data cleared', Colors.red);
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
        title: const Text('Demo GPS Tracker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleGPSListening,
            tooltip: _isListening ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(22.8999, 89.5020), // KUET location
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _gpsMarkers,
            polylines: _gpsPolylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Tracker Demo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTrackerId,
                            decoration: const InputDecoration(
                              labelText: 'Tracker ID',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              'demo_tracker_001',
                              'demo_tracker_002',
                              'demo_tracker_003',
                            ].map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTrackerId = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _sendDemoData,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startDemoSimulation,
                            icon: const Icon(Icons.play_circle),
                            label: const Text('Simulate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _clearAllData,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _isListening ? 'TRACKING' : 'STOPPED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Trackers: ${_trackerPositions.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._trackerPositions.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getTrackerColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key}: ${entry.value.latitude.toStringAsFixed(4)}, ${entry.value.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
