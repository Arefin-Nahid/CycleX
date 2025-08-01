import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? controller;
  bool isScanning = true;
  bool hasPermission = false;
  bool isValidating = false;
  String? validationStatus;

  final Color primaryColor = const Color(0xFF17153A);
  final Color accentColor = const Color(0xFF00D0C3);

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status.isGranted;
    });
    
    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: accentColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Camera Permission Required',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'This app needs camera permission to scan QR codes. Please grant camera permission in settings.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning && capture.barcodes.isNotEmpty) {
      final code = capture.barcodes.first.rawValue;
      if (code != null) {
        _handleScannedCode(code);
      }
    }
  }

  void _handleScannedCode(String code) async {
    setState(() {
      isScanning = false;
      isValidating = true;
      validationStatus = 'Validating QR code...';
    });

    // Stop scanning
    controller?.stop();

    print('🔍 QR Scanner detected code: $code');
    print('🔍 Code length: ${code.length}');

    try {
      // Validate cycle ID format first
      if (code.length != 24) {
        throw Exception('INVALID_ID_FORMAT');
      }

      setState(() {
        validationStatus = 'Checking cycle availability...';
      });

      // Pre-validate the QR code by fetching cycle details
      await ApiService.instance.getCycleById(code);
      
      setState(() {
        isValidating = false;
      });

      // Return the valid code to the previous screen
      print('✅ QR code validated successfully');
      Navigator.pop(context, code);
      
    } catch (e) {
      setState(() {
        isValidating = false;
      });
      
      print('❌ QR validation failed: $e');
      _showErrorDialog(_getErrorMessage(e.toString()));
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('CYCLE_NOT_FOUND')) {
      return 'CYCLE_NOT_FOUND';
    } else if (error.contains('CYCLE_UNAVAILABLE')) {
      return 'CYCLE_UNAVAILABLE';
    } else if (error.contains('CYCLE_INACTIVE')) {
      return 'CYCLE_INACTIVE';
    } else if (error.contains('INVALID_ID_FORMAT')) {
      return 'INVALID_ID_FORMAT';
    } else if (error.contains('Network') || error.contains('timeout')) {
      return 'NETWORK_ERROR';
    } else {
      return 'UNKNOWN_ERROR';
    }
  }

  void _showErrorDialog(String errorType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: primaryColor,
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'QR Code Issue',
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
              _getFriendlyErrorMessage(errorType),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildErrorSuggestions(errorType),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _reportInvalidQR(errorType),
            child: Text(
              'Report Issue',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartScanning();
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: Text('Scan Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getFriendlyErrorMessage(String errorType) {
    switch (errorType) {
      case 'CYCLE_NOT_FOUND':
        return 'This QR code doesn\'t match any available cycles.';
      case 'CYCLE_INACTIVE':
        return 'This cycle is currently not available for rent.';
      case 'CYCLE_UNAVAILABLE':
        return 'This cycle is already being used by someone else.';
      case 'INVALID_ID_FORMAT':
        return 'Invalid QR code format. Please scan a valid CycleX QR code.';
      case 'NETWORK_ERROR':
        return 'Network connection issue. Please check your internet connection.';
      default:
        return 'Unable to process this QR code. Please try again.';
    }
  }

  Widget _buildErrorSuggestions(String errorType) {
    List<String> suggestions = [];
    
    switch (errorType) {
      case 'CYCLE_NOT_FOUND':
        suggestions = [
          '• Make sure you\'re scanning a CycleX QR code',
          '• Check if the QR code is clear and not damaged',
          '• Try scanning from a different angle',
        ];
        break;
      case 'CYCLE_INACTIVE':
        suggestions = [
          '• Try looking for another available cycle nearby',
          '• The owner may have deactivated this cycle',
          '• Check if there are other cycles in the area',
        ];
        break;
      case 'CYCLE_UNAVAILABLE':
        suggestions = [
          '• This cycle is currently in use',
          '• Try finding another available cycle',
          '• Wait a few minutes and try again',
        ];
        break;
      case 'NETWORK_ERROR':
        suggestions = [
          '• Check your internet connection',
          '• Try moving to an area with better signal',
          '• Restart the app and try again',
        ];
        break;
      case 'INVALID_ID_FORMAT':
        suggestions = [
          '• Ensure you\'re scanning a valid CycleX QR code',
          '• Check if the QR code is complete and undamaged',
          '• Try scanning from a closer distance',
        ];
        break;
    }

    if (suggestions.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions:',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...suggestions.map((s) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            s,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        )),
      ],
    );
  }

  void _reportInvalidQR(String errorType) {
    // TODO: Implement QR reporting functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for reporting this issue. We\'ll investigate.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _restartScanning() {
    setState(() {
      isScanning = true;
      isValidating = false;
      validationStatus = null;
    });
    controller?.start();
  }

  void _toggleFlash() async {
    await controller?.toggleTorch();
  }

  void _flipCamera() async {
    await controller?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        backgroundColor: primaryColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.7),
                ),
                SizedBox(height: 24),
                Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please grant camera permission to scan QR codes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Open Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            overlay: const QRScannerOverlay(),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // Balance the header
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Point your camera at the cycle\'s QR code',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Control buttons
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.flash_on,
                  onPressed: _toggleFlash,
                ),
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  onPressed: _flipCamera,
                ),
              ],
            ),
          ),

          // Validation overlay
          if (isValidating)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Card(
                  color: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          validationStatus ?? 'Validating QR code...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF00D0C3),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D0C3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    const cornerThickness = 3.0;

    // Top-left corner
    canvas.drawLine(
      const Offset(0, cornerLength),
      const Offset(0, 0),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      paint..strokeWidth = cornerThickness,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint..strokeWidth = cornerThickness,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerThickness,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint..strokeWidth = cornerThickness,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 