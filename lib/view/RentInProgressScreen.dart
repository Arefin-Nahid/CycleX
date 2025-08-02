import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'PaymentScreen.dart';

class RentInProgressScreen extends StatefulWidget {
  const RentInProgressScreen({Key? key}) : super(key: key);

  @override
  State<RentInProgressScreen> createState() => _RentInProgressScreenState();
}

class _RentInProgressScreenState extends State<RentInProgressScreen> {
  bool _isLoading = true;
  bool _isEndingRental = false;
  Map<String, dynamic>? _activeRental;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActiveRental();
  }

  Future<void> _loadActiveRental() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get active rentals
      final activeRentals = await ApiService.instance.getActiveRentals();
      
      if (activeRentals.isNotEmpty) {
        setState(() {
          _activeRental = activeRentals.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No active rental found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading rental details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _endRental() async {
    if (_activeRental == null) return;

    try {
      // Show confirmation dialog
      final shouldEnd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF17153A),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'End Rental',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to end this rental?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. Make sure you have returned the cycle to a safe location.',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('End Rental'),
            ),
          ],
        ),
      );

      if (shouldEnd == true) {
        setState(() {
          _isEndingRental = true;
        });

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                const SizedBox(height: 16),
                const Text(
                  'Ending your ride...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );

        // Call the API to end the rental
        final rentalId = _activeRental!['_id'] ?? _activeRental!['id'];
        final response = await ApiService.endRental(rentalId);
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          // Navigate directly to payment screen like RenterDashboard
          final completedRental = response['rental'] ?? _activeRental!;
          final amount = (completedRental['totalCost'] ?? 0.0).toDouble();
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                rental: completedRental,
                amount: amount,
              ),
            ),
          );
          
          // Check if payment was successful and refresh is needed
          if (mounted && result != null && result is Map && result['refresh'] == true) {
            Navigator.pop(context, {'refresh': true});
          }
        }
      }
    } catch (e) {
      setState(() {
        _isEndingRental = false;
      });
      
      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Dialog might already be closed
        }
      }
      
      if (mounted) {
        _showErrorDialog(_getErrorMessage(e.toString()));
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('RENTAL_NOT_FOUND')) {
      return 'Rental not found. It may have already been ended.';
    } else if (error.contains('FORBIDDEN')) {
      return 'You are not authorized to end this rental.';
    } else if (error.contains('INVALID_STATUS')) {
      return 'This rental cannot be ended as it is not active.';
    } else if (error.contains('Network') || error.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'An error occurred while ending the rental. Please try again.';
    }
  }

  void _showSuccessDialog() {
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
              size: 24, // reduced from 28
            ),
            SizedBox(width: 6), // reduced from 8
            Text(
              'Rental Ended!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18, // reduced from default
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rental has been successfully ended.',
              style: TextStyle(color: Colors.white, fontSize: 14), // reduced from 16
            ),
            SizedBox(height: 12), // reduced from 16
            Container(
              padding: EdgeInsets.all(10), // reduced from 12
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // reduced from 8
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16), // reduced from 20
                  SizedBox(width: 6), // reduced from 8
                  Expanded(
                    child: Text(
                      'Thank you for using CycleX! Please proceed to payment.',
                      style: TextStyle(color: Colors.green, fontSize: 12), // reduced from 14
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF17153A),
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Preparing payment...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
              
              // Get the actual rental cost from backend with timeout
              try {
                final rentalId = _activeRental!['_id'] ?? _activeRental!['id'];
                
                // Add timeout to the API call
                final rentalDetails = await ApiService.getRentalById(rentalId)
                    .timeout(Duration(seconds: 5));
                
                Navigator.pop(context); // Close loading dialog
                
                if (mounted && rentalDetails != null) {
                  final actualAmount = rentalDetails['totalCost']?.toDouble() ?? 0.0;
                  
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        rental: _activeRental!,
                        amount: actualAmount,
                      ),
                    ),
                  );
                } else {
                  // Fallback to client-side calculation
                  _navigateToPaymentWithCalculatedAmount();
                }
              } catch (e) {
                print('Error getting rental details: $e');
                Navigator.pop(context); // Close loading dialog
                
                // Fallback to client-side calculation
                _navigateToPaymentWithCalculatedAmount();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // reduced padding
            ),
            child: Text('Proceed to Payment', style: TextStyle(fontSize: 14)), // reduced font size
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentWithCalculatedAmount() {
    try {
      final cycle = _activeRental!['cycle'] as Map<String, dynamic>?;
      final startTime = DateTime.parse(_activeRental!['startTime']);
      final duration = DateTime.now().difference(startTime);
      final hourlyRate = cycle?['hourlyRate'] ?? 0.0;
      final calculatedAmount = (duration.inMinutes / 60) * hourlyRate;
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              rental: _activeRental!,
              amount: calculatedAmount,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in fallback calculation: $e');
      // Final fallback with default amount
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              rental: _activeRental!,
              amount: 0.0,
            ),
          ),
        );
      }
    }
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
            SizedBox(width: 8),
            Text(
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
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
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
      backgroundColor: Colors.white, // Changed to white
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700, // Keep app bar teal for consistency
        elevation: 0,
        title: const Text(
          'Rent In Progress',
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
              : _buildRentalDetailsView(),
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
            'Loading rental details...',
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
              'No Active Rental',
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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
      ),
    );
  }

  Widget _buildRentalDetailsView() {
    if (_activeRental == null) return _buildErrorView();

    final cycle = _activeRental!['cycle'] as Map<String, dynamic>?;
    final startTime = DateTime.parse(_activeRental!['startTime']);
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final hourlyRate = cycle?['hourlyRate'] ?? 0.0;
    final currentCost = (duration.inMinutes / 60) * hourlyRate;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // reduced from 16.0
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.07),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.15),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.directions_bike,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cycle?['brand'] ?? 'Unknown'} ${cycle?['model'] ?? 'Cycle'}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.fiber_manual_record, color: Colors.green, size: 12),
                            SizedBox(width: 6),
                            Text(
                              'Rental in progress',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // reduced from 24

            // Timer Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Changed to light grey
                borderRadius: BorderRadius.circular(12), // reduced from 16
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14), // reduced from 20
              child: Column(
                children: [
                  const Text(
                    'Rental Duration',
                    style: TextStyle(
                      color: Colors.black, // Changed from white to black
                      fontSize: 14, // reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12), // reduced from 16
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeUnit('Hours', hours.toString()),
                      Container(
                        width: 1,
                        height: 32, // reduced from 40
                        color: Colors.grey.shade300, // Changed from white to grey
                      ),
                      _buildTimeUnit('Minutes', minutes.toString()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // reduced from 24

            // Cost Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Changed to light grey
                borderRadius: BorderRadius.circular(12), // reduced from 16
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14), // reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Cost',
                    style: TextStyle(
                      color: Colors.black, // Changed from white to black
                      fontSize: 14, // reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8), // reduced from 12
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '৳${currentCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 24, // reduced from 32
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '৳${hourlyRate.toStringAsFixed(2)}/hour',
                        style: TextStyle(
                          color: Colors.grey.shade600, // Changed from white to grey
                          fontSize: 12, // reduced from 14
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // reduced from 24

            // Location Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Changed to light grey
                borderRadius: BorderRadius.circular(12), // reduced from 16
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14), // reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      color: Colors.black, // Changed from white to black
                      fontSize: 14, // reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8), // reduced from 12
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 16, // reduced from 20
                      ),
                      const SizedBox(width: 6), // reduced from 8
                      Expanded(
                        child: Text(
                          cycle?['location'] ?? 'Location not specified',
                          style: const TextStyle(
                            color: Colors.black, // Changed from white to black
                            fontSize: 14, // reduced from 16
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // reduced from 24

            // Start Time Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Changed to light grey
                borderRadius: BorderRadius.circular(12), // reduced from 16
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14), // reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rental Started',
                    style: TextStyle(
                      color: Colors.black, // Changed from white to black
                      fontSize: 14, // reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8), // reduced from 12
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.green,
                        size: 16, // reduced from 20
                      ),
                      const SizedBox(width: 6), // reduced from 8
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(startTime),
                        style: const TextStyle(
                          color: Colors.black, // Changed from white to black
                          fontSize: 14, // reduced from 16
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // reduced from 32

            // End Rental Button
            SizedBox(
              width: double.infinity,
              height: 48, // reduced from 56
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // reduced from 12
                  ),
                  elevation: 4,
                ),
                onPressed: _isEndingRental ? null : _endRental,
                child: _isEndingRental
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16, // reduced from 20
                            height: 16, // reduced from 20
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8), // reduced from 12
                          Text(
                            'Ending Rental...',
                            style: TextStyle(
                              fontSize: 16, // reduced from 18
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'End Rental',
                        style: TextStyle(
                          fontSize: 16, // reduced from 18
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12), // reduced from 16

            // Info Card
            Container(
              padding: const EdgeInsets.all(12), // reduced from 16
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), // reduced from 12
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 16, // reduced from 20
                  ),
                  const SizedBox(width: 8), // reduced from 12
                  Expanded(
                    child: Text(
                      'Your rental is active. You can end it anytime by pressing the "End Rental" button.',
                      style: TextStyle(
                        color: Colors.blue.shade700, // Changed to darker blue
                        fontSize: 12, // reduced from 14
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // reduced from 16, 8
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6), // reduced from 8
          ),
          child: Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 18, // reduced from 24
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6), // reduced from 8
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600, // Changed from white to grey
            fontSize: 10, // reduced from 12
          ),
        ),
      ],
    );
  }
} 