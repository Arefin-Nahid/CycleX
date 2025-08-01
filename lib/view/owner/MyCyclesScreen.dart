import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyCyclesScreen extends StatefulWidget {
  const MyCyclesScreen({Key? key}) : super(key: key);

  @override
  _MyCyclesScreenState createState() => _MyCyclesScreenState();
}

class _MyCyclesScreenState extends State<MyCyclesScreen> {
  List<Map<String, dynamic>> cycles = [];
  bool isLoading = true;
  bool isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final data = await ApiService.instance.getMyCycles();
      setState(() {
        cycles = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Error loading cycles: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadCycles,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _downloadQRCode(String cycleId) async {
    try {
      bool granted = await requestStoragePermission();
      if (!granted) {
        _showErrorSnackBar('Storage permission denied');
        return;
      }

      final qrValidationResult = QrValidator.validate(
        data: cycleId,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;

        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );

        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filePath = '${directory.path}/qr_$cycleId.png';
        final imageData = await painter.toImageData(2048, format: ui.ImageByteFormat.png);
        final buffer = imageData!.buffer;
        final file = File(filePath);

        await file.writeAsBytes(
          buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes),
        );

        if (mounted) {
          _showSuccessSnackBar('QR Code saved to Downloads:\nqr_$cycleId.png');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error generating QR code: $e');
      }
    }
  }

  Future<void> _showQRCodePreview(String cycleId, Map<String, dynamic> cycle) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.teal, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'QR Code for Cycle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: QrImageView(
                  data: cycleId,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '${cycle['brand']} ${cycle['model']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'ID: ${cycleId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadQRCode(cycleId);
                    },
                    icon: Icon(Icons.download),
                    label: Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareQRCode(cycleId);
                    },
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQRCode(String cycleId) async {
    // TODO: Implement share functionality
    _showSuccessSnackBar('Share functionality coming soon!');
  }

  Future<void> _toggleCycleStatus(String cycleId, bool currentStatus) async {
    if (isProcessingAction) return;

    setState(() {
      isProcessingAction = true;
    });

    try {
      Map<String, dynamic>? coordinates;
      if (!currentStatus) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          coordinates = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': placemarks.isNotEmpty
                ? '${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}'
                : 'Unknown Location',
          };
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('Error getting location. Please try again.');
          }
          setState(() {
            isProcessingAction = false;
          });
          return;
        }
      }

      await ApiService.instance.toggleCycleStatus(cycleId, coordinates: coordinates);
      await _loadCycles();
      if (mounted) {
        _showSuccessSnackBar(currentStatus
            ? 'Cycle activated and location updated'
            : 'Cycle deactivated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      setState(() {
        isProcessingAction = false;
      });
    }
  }

  Future<void> _deleteCycle(String cycleId) async {
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text('Delete Cycle', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Are you sure you want to delete this cycle? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm) {
        await ApiService.instance.deleteCycle(cycleId);
        _loadCycles();
        if (mounted) {
          _showSuccessSnackBar('Cycle deleted successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error deleting cycle: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cycles'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (isProcessingAction)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Loading your cycles...'),
                ],
              ),
            )
          : cycles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bike_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No cycles found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first cycle to get started',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCycles,
                  child: ListView.builder(
                    itemCount: cycles.length,
                    itemBuilder: (context, index) {
                      final cycle = cycles[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                '${cycle['brand']} ${cycle['model']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Condition: ${cycle['condition']}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Rate: ৳${cycle['hourlyRate']}/hour',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Location: ${cycle['location']}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.qr_code, color: Colors.teal),
                                      title: Text('Preview QR'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showQRCodePreview(cycle['_id'], cycle);
                                      },
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.download, color: Colors.blue),
                                      title: Text('Download QR'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _downloadQRCode(cycle['_id']);
                                      },
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteCycle(cycle['_id']);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cycle['isActive'] ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: cycle['isActive'] ? Colors.green : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (cycle['isRented'])
                                        Text(
                                          'Currently Rented',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
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
                ),
    );
  }
}
