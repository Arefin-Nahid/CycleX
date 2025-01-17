import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/models/cycle.dart';

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
  List<Cycle> _nearbyCycles = [];
  final LatLng _kuetLocation = const LatLng(22.8999, 89.5020);
  BitmapDescriptor? _cycleIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initializeLocation();
  }

  Future<void> _loadCustomMarker() async {
    _cycleIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/cycle_marker.png', // Add this image to your assets
    );
  }

  Future<void> _initializeLocation() async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      await _fetchNearbyCycles(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error initializing location: $e');
    }
  }

  Future<void> _fetchNearbyCycles(double latitude, double longitude) async {
    try {
      final cycles = await ApiService.getNearbyCycles(
        lat: latitude,
        lng: longitude,
      );

      setState(() {
        _markers.clear();

        // Add current location marker
        if (_currentPosition != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        }

        // Add only active and available cycles
        for (var cycle in cycles) {
          if (cycle['isActive'] == true && 
              cycle['isRented'] == false && 
              cycle['coordinates'] != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(cycle['_id']),
                position: LatLng(
                  cycle['coordinates']['latitude'],
                  cycle['coordinates']['longitude'],
                ),
                infoWindow: InfoWindow(
                  title: '${cycle['brand']} ${cycle['model']}',
                  snippet: '৳${cycle['hourlyRate']}/hour',
                ),
                icon: _cycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                onTap: () => _showCycleDetails(Cycle.fromJson(cycle)),
              ),
            );
          }
        }
      });
    } catch (e) {
      _showErrorDialog('Error fetching nearby cycles: $e');
    }
  }

  void _showCycleDetails(Cycle cycle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cycle.model,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hourly Rate: ৳${cycle.hourlyRate}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${cycle.location}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _rentCycle(cycle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D0C3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Rent Now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rentCycle(Cycle cycle) async {
    try {
      // Call the API to rent the cycle
      await ApiService.instance.rentCycle(cycle.id);

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cycle rented successfully')),
        );
      }
    } catch (e) {
      _showErrorDialog('Error renting cycle: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Nearby Cycles',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF17153A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _kuetLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Search for cycles nearby',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // TODO: Implement filter functionality
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initializeLocation,
        backgroundColor: const Color(0xFF00D0C3),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
