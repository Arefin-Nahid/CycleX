import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CycleX/services/api_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'RentCycle.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeCycles = [];
  List<Map<String, dynamic>> _myActiveCycles = [];
  final LatLng _kuetLocation = const LatLng(22.8999, 89.5020);
  BitmapDescriptor? _cycleIcon;
  BitmapDescriptor? _myCycleIcon;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _initializeLocation();
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _cycleIcon = await _createCustomCycleMarker(Colors.green);
      _myCycleIcon = await _createCustomCycleMarker(Colors.blue);
    } catch (e) {
      print('Error creating custom cycle markers: $e');
      try {
        _cycleIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(96, 96)),
          'assets/images/cycle_marker.png',
        );
        _myCycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      } catch (assetError) {
        print('Error loading asset marker: $assetError');
        _cycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        _myCycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
    }
  }

  Future<BitmapDescriptor> _createCustomCycleMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 96.0;
    const double shadowOffset = 4.0;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0);

    canvas.drawCircle(
      const Offset(size / 2 + shadowOffset, size / 2 + shadowOffset),
      size / 2 - 8,
      shadowPaint,
    );

    final Paint backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      backgroundPaint,
    );

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 8,
      borderPaint,
    );

    final Paint cyclePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      const Offset(size / 2 - 20, size / 2 + 8),
      12.0,
      cyclePaint,
    );
    canvas.drawCircle(
      const Offset(size / 2 + 20, size / 2 + 8),
      12.0,
      cyclePaint,
    );

    canvas.drawLine(
      const Offset(size / 2 - 20, size / 2 + 8),
      const Offset(size / 2, size / 2 - 16),
      cyclePaint,
    );
    canvas.drawLine(
      const Offset(size / 2, size / 2 - 16),
      const Offset(size / 2 + 20, size / 2 + 8),
      cyclePaint,
    );
    canvas.drawLine(
      const Offset(size / 2 - 8, size / 2 - 4),
      const Offset(size / 2 + 8, size / 2 - 4),
      cyclePaint,
    );
    canvas.drawLine(
      const Offset(size / 2 - 6, size / 2 - 16),
      const Offset(size / 2 + 6, size / 2 - 16),
      cyclePaint,
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      await _fetchActiveCycles(position.latitude, position.longitude);
      await _fetchMyActiveCycles();

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error initializing location: $e');
    }
  }

  Future<void> _fetchActiveCycles(double latitude, double longitude) async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      final cycles = await ApiService.getNearbyCycles(
        lat: latitude,
        lng: longitude,
      );

      setState(() {
        _markers.clear();

        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUserId = currentUser?.uid;

        // Filter out user's own cycles from available cycles list
        List<Map<String, dynamic>> otherUsersCycles = [];

        for (var cycle in cycles) {
          if (cycle['coordinates'] != null) {
            final coordinates = cycle['coordinates'];
            if (coordinates is Map &&
                coordinates['latitude'] != null &&
                coordinates['longitude'] != null) {
              try {
                final lat = coordinates['latitude'].toDouble();
                final lng = coordinates['longitude'].toDouble();

                // Only add to available cycles if it's not the user's own cycle
                if (currentUserId == null || cycle['owner'] != currentUserId) {
                  otherUsersCycles.add(cycle);

                  _markers.add(
                    Marker(
                      markerId: MarkerId(cycle['_id']),
                      position: LatLng(lat, lng),
                      infoWindow: InfoWindow(
                        title: '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                        snippet: '৳${cycle['hourlyRate']?.toStringAsFixed(2) ?? '0.00'}/hour',
                      ),
                      icon: _cycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      onTap: () => _onCycleMarkerTapped(cycle),
                    ),
                  );
                }
              } catch (e) {
                continue;
              }
            }
          }
        }

        _activeCycles = otherUsersCycles;
        _isRefreshing = false;
      });
    } catch (e) {
      print('❌ MapView: Error fetching active cycles: $e');
      setState(() {
        _isRefreshing = false;
      });
      _showErrorDialog('Error fetching active cycles: $e');
    }
  }

  Future<void> _fetchMyActiveCycles() async {
    try {
      final myCycles = await ApiService.instance.getMyCycles();
      final activeMyCycles = myCycles.where((cycle) =>
      cycle['isActive'] == true &&
          cycle['coordinates'] != null
      ).toList();

      setState(() {
        _myActiveCycles = activeMyCycles;
      });

      // Add markers for my active cycles
      for (var cycle in activeMyCycles) {
        if (cycle['coordinates'] != null) {
          final coordinates = cycle['coordinates'];
          if (coordinates is Map &&
              coordinates['latitude'] != null &&
              coordinates['longitude'] != null) {
            try {
              final lat = coordinates['latitude'].toDouble();
              final lng = coordinates['longitude'].toDouble();

              _markers.add(
                Marker(
                  markerId: MarkerId('my_${cycle['_id']}'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: 'My ${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                    snippet: 'My Active Cycle',
                  ),
                  icon: _myCycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  onTap: () => _onMyCycleMarkerTapped(cycle),
                ),
              );
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      print('❌ MapView: Error fetching my active cycles: $e');
    }
  }

  void _onCycleMarkerTapped(Map<String, dynamic> cycleData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentCycle(
          cycleId: cycleData['_id'],
        ),
      ),
    );
  }

  void _onMyCycleMarkerTapped(Map<String, dynamic> cycleData) {
    _showMyCycleInfo(cycleData);
  }

  void _showMyCycleInfo(Map<String, dynamic> cycle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(Icons.directions_bike, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            const Text(
              'My Active Cycle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cycle['brand']} ${cycle['model']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate: ৳${cycle['hourlyRate']?.toStringAsFixed(2) ?? '0.00'}/hour',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Condition: ${cycle['condition'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${cycle['location'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCycleList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bike, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Available Cycles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_activeCycles.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _activeCycles.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bike_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cycles available nearby',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try moving to a different location',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activeCycles.length,
                itemBuilder: (context, index) {
                  final cycle = _activeCycles[index];
                  bool isMine = false;
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null && cycle['owner'] == currentUser.uid) {
                    isMine = true;
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(
                          Icons.directions_bike,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isMine)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'own',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '৳${cycle['hourlyRate']?.toStringAsFixed(2) ?? '0.00'}/hour',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Condition: ${cycle['condition'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: isMine
                          ? null
                          : ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _onCycleMarkerTapped(cycle);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Rent'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Active Cycles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _kuetLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bike,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Cycles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            '${_activeCycles.length}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view cycle list or tap markers to rent',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showCycleList,
                            icon: const Icon(Icons.list),
                            label: const Text('View List'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'My Cycles: ${_myActiveCycles.length}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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