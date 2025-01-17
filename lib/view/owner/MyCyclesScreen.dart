import 'package:flutter/material.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class MyCyclesScreen extends StatefulWidget {
  const MyCyclesScreen({Key? key}) : super(key: key);

  @override
  _MyCyclesScreenState createState() => _MyCyclesScreenState();
}

class _MyCyclesScreenState extends State<MyCyclesScreen> {
  List<Map<String, dynamic>> cycles = [];
  bool isLoading = true;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    try {
      final data = await ApiService.instance.getMyCycles();
      setState(() {
        cycles = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleCycleStatus(String cycleId, bool currentStatus) async {
    try {
      // Only get location when activating the cycle
      Map<String, dynamic>? coordinates;
      if (!currentStatus) { // When activating (changing from inactive to active)
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          
          // Get address details
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          coordinates = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': placemarks.isNotEmpty 
                ? '${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}'
                : 'Unknown Location'
          };
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error getting location. Please try again.')),
            );
          }
          return; // Don't proceed if we can't get location
        }
      }

      await ApiService.instance.toggleCycleStatus(cycleId, coordinates: coordinates);
      await _loadCycles(); // Reload cycles after toggle
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Cycle deactivated' : 'Cycle activated and location updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteCycle(String cycleId) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Cycle'),
          content: const Text('Are you sure you want to delete this cycle?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm) {
        await ApiService.instance.deleteCycle(cycleId);
        _loadCycles(); // Reload the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cycle deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting cycle: $e')),
        );
      }
    }
  }

  Future<void> _downloadQRCode(String cycleId) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: cycleId,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;
        
        // Create QR code image
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );

        // Convert to image
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/qr_${cycleId}.png';
        final picData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
        final buffer = picData!.buffer;
        final file = File(path);
        await file.writeAsBytes(buffer.asUint8List(picData.offsetInBytes, picData.lengthInBytes));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR Code saved to: $path')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cycles'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cycles.isEmpty
              ? const Center(child: Text('No cycles found'))
              : ListView.builder(
                  itemCount: cycles.length,
                  itemBuilder: (context, index) {
                    final cycle = cycles[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('${cycle['brand']} ${cycle['model']}'),
                            subtitle: Text(
                              'Condition: ${cycle['condition']}\n'
                              'Rate: ৳${cycle['hourlyRate']}/hour\n'
                              'Location: ${cycle['location']}',
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: const Icon(Icons.qr_code),
                                    title: const Text('Download QR'),
                                    onTap: () => _downloadQRCode(cycle['_id']),
                                  ),
                                ),
                                PopupMenuItem(
                                  child: ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    onTap: () => _deleteCycle(cycle['_id']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cycle['isActive'] ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: cycle['isActive'] ? Colors.green : Colors.grey,
                                  ),
                                ),
                                Switch(
                                  value: cycle['isActive'],
                                  onChanged: cycle['isRented']
                                      ? null
                                      : (value) => _toggleCycleStatus(cycle['_id'], value),
                                  activeColor: Colors.teal,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 