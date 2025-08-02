import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cycle.dart';
import 'RentInProgressScreen.dart';

class RentCycle extends StatefulWidget {
  final String cycleId; // This will be passed from QR scanner

  const RentCycle({
    Key? key,
    required this.cycleId,
  }) : super(key: key);

  @override
  State<RentCycle> createState() => _RentCycleState();
}

class _RentCycleState extends State<RentCycle> {
  bool _isLoading = true;
  bool _isRenting = false;
  Map<String, dynamic>? _cycleData;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchCycleData();
  }

  Future<void> _fetchCycleData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔍 RentCycle: Fetching data for cycle ID: ${widget.cycleId}');
      print('🔍 RentCycle: Cycle ID length: ${widget.cycleId.length}');

      // Fetch cycle data from backend with retry logic
      final response = await ApiService.getCycleByIdWithRetry(widget.cycleId, maxRetries: 3);
      
      print('🔍 RentCycle: API Response received: ${response.toString()}');
      
      if (response['cycle'] != null) {
        print('✅ RentCycle: Cycle data found successfully');
        setState(() {
          _cycleData = response['cycle'];
          _isLoading = false;
        });
      } else {
        print('❌ RentCycle: No cycle data in response');
        throw Exception('Cycle data not found in response');
      }
    } catch (e) {
      print('❌ RentCycle: Error fetching cycle data: $e');
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String error) {
    print('🔍 Processing error: $error');
    
    if (error.contains('CYCLE_NOT_FOUND')) {
      return 'Cycle not found. Please check the QR code.';
    } else if (error.contains('CYCLE_UNAVAILABLE')) {
      return 'This cycle is already rented.';
    } else if (error.contains('CYCLE_INACTIVE')) {
      return 'This cycle is not available for rent.';
    } else if (error.contains('CYCLE_UNAVAILABLE_OR_INACTIVE')) {
      return 'This cycle is not available for rent (may be inactive or already rented).';
    } else if (error.contains('INVALID_ID_FORMAT')) {
      return 'Invalid QR code format.';
    } else if (error.contains('OWNER_RENTAL_NOT_ALLOWED')) {
      return 'You cannot rent your own cycle.';
    } else if (error.contains('ACTIVE_RENTAL_EXISTS')) {
      return 'You already have an active rental. Please return your current cycle first.';
    } else if (error.contains('MISSING_CYCLE_ID')) {
      return 'Invalid cycle ID. Please try scanning again.';
    } else if (error.contains('Network') || error.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('500') || error.contains('Internal Server Error')) {
      return 'Server error. Please try again in a few moments.';
    } else if (error.contains('Failed to rent cycle')) {
      return 'Unable to start rental. Please try again.';
    } else {
      return 'An error occurred while starting the rental. Please try again.';
    }
  }

  Future<void> _startRent() async {
    if (_cycleData == null) return;

    try {
      setState(() {
        _isRenting = true;
      });

      print('🔍 Starting rental for cycle: ${widget.cycleId}');

      Map<String, dynamic> response;
      
      try {
        // Use QR rental endpoint for better consistency
        response = await ApiService.rentCycleByQR(widget.cycleId);
        print('✅ QR rental response: $response');
        
        // Check if response is valid
        if (response == null) {
          throw Exception('Empty response from rental endpoint');
        }
        
      } catch (qrError) {
        print('❌ QR rental failed: $qrError');
        
        // Fallback to regular rental endpoint
        try {
          response = await ApiService.instance.rentCycle(widget.cycleId);
          print('✅ Regular rental response: $response');
          
          // Check if response is valid
          if (response == null) {
            throw Exception('Empty response from regular rental endpoint');
          }
          
        } catch (regularError) {
          print('❌ Regular rental also failed: $regularError');
          throw Exception('Both rental methods failed. QR: $qrError, Regular: $regularError');
        }
      }
      
      // Show success dialog
      _showSuccessDialog(response);
      
    } catch (e) {
      print('❌ Rental error: $e');
      setState(() {
        _isRenting = false;
      });
      
      // Show error dialog
      _showErrorDialog(_getErrorMessage(e.toString()));
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    // Extract data from response
    final rental = response['rental'] ?? {};
    final cycle = response['cycle'] ?? rental['cycle'] ?? {};
    final startTime = rental['startTime'] != null 
        ? DateTime.tryParse(rental['startTime']) ?? DateTime.now()
        : DateTime.now();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17153A),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Rental Started!',
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
              'Cycle: ${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Start Time: ${DateFormat('MMM dd, yyyy HH:mm').format(startTime)}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate: ৳${cycle['hourlyRate'] ?? 0}/hour',
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Rental ID: ${rental['_id']?.toString().substring(0, 8) ?? 'N/A'}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your rental has started successfully! You can now use the cycle.',
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back to previous screen with success result
              // Navigate to rent in progress screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RentInProgressScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
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
              'Rental Error',
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
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildErrorSuggestions(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (message.contains('Network') || message.contains('try again'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startRent();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorSuggestions(String message) {
    List<String> suggestions = [];
    
    if (message.contains('already rented')) {
      suggestions = [
        '• Try finding another available cycle nearby',
        '• Wait a few minutes and try again',
        '• Check the app for other available cycles',
      ];
    } else if (message.contains('not available')) {
      suggestions = [
        '• The owner may have deactivated this cycle',
        '• Try looking for other cycles in the area',
        '• Contact support if this persists',
      ];
    } else if (message.contains('Network')) {
      suggestions = [
        '• Check your internet connection',
        '• Try moving to an area with better signal',
        '• Restart the app and try again',
      ];
    } else if (message.contains('own cycle')) {
      suggestions = [
        '• You cannot rent cycles you own',
        '• Use the owner dashboard to manage your cycles',
        '• Look for cycles owned by other users',
      ];
    } else if (message.contains('active rental')) {
      suggestions = [
        '• Return your current rental first',
        '• Check your active rentals in the dashboard',
        '• Contact support if you need help',
      ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17153A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Rent Cycle',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildCycleDetailsView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Loading cycle details...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _fetchCycleData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDetailsView() {
    if (_cycleData == null) return _buildErrorView();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cycle Image and Details Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cycle Image
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      child: _cycleData?['images'] != null && 
                             (_cycleData!['images'] as List).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _cycleData!['images'][0],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              ),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cycle Details
                    Text(
                      '${_cycleData?['brand'] ?? 'Unknown'} ${_cycleData?['model'] ?? 'Cycle'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Condition
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getConditionColor(_cycleData?['condition']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _cycleData?['condition'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Price
                    Row(
                      children: [
                        Text(
                          '৳${_cycleData?['hourlyRate']?.toStringAsFixed(2) ?? '0.00'}/hour',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _cycleData?['location'] ?? 'Location not specified',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description Card
              if (_cycleData?['description'] != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _cycleData?['description'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_cycleData?['description'] != null) const SizedBox(height: 24),

              // Start Rent Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isRenting ? null : _startRent,
                  child: _isRenting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Starting Rental...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Start Rent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Terms and conditions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By starting the rental, you agree to return the cycle in the same condition.',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.3),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bike,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Cycle Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 