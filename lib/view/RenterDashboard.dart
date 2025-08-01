import 'package:flutter/material.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/view/QRScannerScreen.dart';
import 'package:CycleX/view/RentCycle.dart';
import 'package:CycleX/view/RentInProgressScreen.dart';
import 'package:intl/intl.dart';

class RenterDashboard extends StatefulWidget {
  const RenterDashboard({Key? key}) : super(key: key);

  @override
  State<RenterDashboard> createState() => _RenterDashboardState();
}

class _RenterDashboardState extends State<RenterDashboard> {
  bool isLoading = true;
  Map<String, dynamic> dashboardStats = {
    'totalRides': 0,
    'totalSpent': 0.0,
  };
  List<Map<String, dynamic>> activeRentals = [];
  List<Map<String, dynamic>> recentRides = [];
  bool isProcessingQR = false;

  final Color primaryColor = const Color(0xFF17153A);
  final Color accentColor = const Color(0xFF00D0C3);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await ApiService.instance.getRenterDashboardStats();
      final actives = await ApiService.instance.getActiveRentals();
      final rides = await ApiService.instance.getRecentRides();

      setState(() {
        dashboardStats = stats;
        activeRentals = actives;
        recentRides = rides;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  Future<void> _scanQRCode() async {
    try {
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );

      if (scannedCode != null && mounted) {
        await _processScannedCode(scannedCode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processScannedCode(String cycleId) async {
    setState(() {
      isProcessingQR = true;
    });

    try {
      // Debug: Print the scanned cycle ID
      print('🔍 Scanned Cycle ID: $cycleId');
      
      // Validate cycle ID format
      if (cycleId.length != 24) {
        throw Exception('Invalid cycle ID format. Expected 24 characters, got ${cycleId.length}');
      }
      
      // Debug: Test API call first
      print('🔍 Testing API call to get cycle details...');
      try {
        final cycleResponse = await ApiService.instance.getCycleById(cycleId);
        print('✅ Cycle details retrieved: ${cycleResponse['cycle']?['brand']} ${cycleResponse['cycle']?['model']}');
      } catch (apiError) {
        print('❌ API Error: $apiError');
        throw Exception('Failed to fetch cycle details: $apiError');
      }

      // Navigate to RentCycle screen with the scanned cycle ID
      print('🔍 Navigating to RentCycle screen...');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RentCycle(cycleId: cycleId),
        ),
      );

      // If rental was successful, refresh dashboard data
      if (result == true) {
        print('✅ Rental successful, refreshing dashboard...');
        await _loadDashboardData();
      }
    } catch (e) {
      print('❌ Error in _processScannedCode: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR code: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        isProcessingQR = false;
      });
    }
  }

  Future<bool?> _showRentConfirmationDialog(Map<String, dynamic> cycleDetails) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rental'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to rent this cycle?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildCycleInfoRow('Model', cycleDetails['model'] ?? 'N/A'),
              _buildCycleInfoRow('Rate', '৳${cycleDetails['rate']?.toString() ?? 'N/A'}/hour'),
              _buildCycleInfoRow('Location', cycleDetails['location'] ?? 'N/A'),
              if (cycleDetails['description'] != null)
                _buildCycleInfoRow('Description', cycleDetails['description']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rent Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCycleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showCycleUnavailableDialog(Map<String, dynamic> cycleDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cycle Unavailable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cycleDetails['model']} is currently not available for rent.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason: ${cycleDetails['isActive'] == false ? 'Cycle is inactive' : 'Cycle is already rented'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Renter Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.map,
                              label: 'Find Cycles',
                              onPressed: () => Navigator.pushNamed(
                                context,
                                PageConstants.mapViewScreen,
                              ),
                              primary: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Scan QR',
                              onPressed: isProcessingQR ? () {} : () => _scanQRCode(),
                              primary: false,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Content
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              // Stats Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Rides',
                                      dashboardStats['totalRides'].toString(),
                                      Icons.pedal_bike,
                                      accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Spent',
                                      '৳${dashboardStats['totalSpent'].toStringAsFixed(2)}',
                                      Icons.account_balance_wallet,
                                      primaryColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Active Rentals
                              if (activeRentals.isNotEmpty) ...[
                                _buildSectionHeader('Active Rental', Icons.play_circle_filled, Colors.orange),
                                const SizedBox(height: 12),
                                ...activeRentals.map((rental) => _buildGorgeousRentalCard(rental)),
                                const SizedBox(height: 24),
                              ],

                              // Recent Rides
                              _buildSectionHeader(
                                'Recent Rides',
                                Icons.history,
                                Colors.purple,
                                action: TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    PageConstants.historyScreen,
                                  ),
                                  child: Text(
                                    'View All',
                                    style: TextStyle(color: accentColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (recentRides.isEmpty)
                                _buildGorgeousEmptyState('No recent rides found', Icons.directions_bike_outlined)
                              else ...[
                                ...recentRides.take(5).map((ride) => _buildSmartRideCard(ride)),
                                if (recentRides.length > 5) ...[
                                  const SizedBox(height: 16),
                                  _buildViewAllButton(),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _endRental(Map<String, dynamic> rental) async {
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
                'End Ride',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to end this ride?',
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
                        'Make sure you have returned the cycle to a safe location before ending the ride.',
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
              child: Text('End Ride'),
            ),
          ],
        ),
      );

      if (shouldEnd == true) {
        // Call the API to end the rental
        final rentalId = rental['_id'] ?? rental['id'];
        await ApiService.endRental(rentalId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride ended successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the dashboard data
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending ride: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRentalDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRideCard(Map<String, dynamic> ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          ride['model'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildRideDetail(Icons.calendar_today, _formatDate(ride['date'])),
            _buildRideDetail(Icons.timer, '${ride['duration']} hours'),
            _buildRideDetail(Icons.attach_money, '৳${ride['cost']}'),
            _buildRideDetail(Icons.location_on, ride['location']),
          ],
        ),
      ),
    );
  }

  Widget _buildRideDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return DateFormat('MMM d, y').format(dateTime);
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool primary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? accentColor : Colors.white,
        foregroundColor: primary ? Colors.white : primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: primary ? 4 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildCycleDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _viewRentalDetails(Map<String, dynamic> rental) {
    // Navigate to RentInProgressScreen for detailed view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RentInProgressScreen(),
      ),
    );
  }

  // New gorgeous widgets
  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGorgeousRentalCard(Map<String, dynamic> rental) {
    final cycle = rental['cycle'] ?? {};
    final startTime = DateTime.tryParse(rental['startTime'] ?? '') ?? DateTime.now();
    final duration = DateTime.now().difference(startTime);
    
    // Use backend calculated values if available, otherwise calculate frontend
    final durationInMinutes = rental['durationInMinutes'] ?? duration.inMinutes;
    final currentCost = rental['cost'] ?? 0.0;
    final hourlyRate = cycle['hourlyRate'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rental ID: ${rental['_id']?.substring(0, 8) ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildRentalInfo(
                        Icons.access_time,
                        'Duration',
                        '${(durationInMinutes / 60).floor()}h ${durationInMinutes % 60}m',
                      ),
                    ),
                    Expanded(
                      child: _buildRentalInfo(
                        Icons.attach_money,
                        'Current Cost',
                        '৳${currentCost.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRentalInfo(
                        Icons.speed,
                        'Rate',
                        '৳${hourlyRate.toStringAsFixed(2)}/hr',
                      ),
                    ),
                    Expanded(
                      child: _buildRentalInfo(
                        Icons.location_on,
                        'Location',
                        '${cycle['location'] ?? 'Unknown'}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewRentalDetails(rental),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _endRental(rental),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('End'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfo(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartRideCard(Map<String, dynamic> ride) {
    final cycle = ride['cycle'] ?? {};
    final endTime = DateTime.tryParse(ride['endTime'] ?? '') ?? DateTime.now();
    final duration = ride['duration'] ?? 0;
    final cost = ride['totalCost'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bike, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17153A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(endTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${cost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${duration}min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGorgeousEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, PageConstants.mapViewScreen),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.search),
            label: const Text('Find Cycles'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: TextButton.icon(
        onPressed: () => Navigator.pushNamed(context, PageConstants.historyScreen),
        icon: Icon(Icons.history, color: accentColor),
        label: Text(
          'View All Rides',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 