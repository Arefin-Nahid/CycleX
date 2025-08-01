import 'package:flutter/material.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/view/QRScannerScreen.dart';
import 'package:CycleX/view/RentCycle.dart';
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
                                _buildSectionHeader('Active Rental'),
                                const SizedBox(height: 12),
                                ...activeRentals.map((rental) => _buildActiveRentalCard(rental)),
                                const SizedBox(height: 24),
                              ],

                              // Recent Rides
                              _buildSectionHeader(
                                'Recent Rides',
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
                              ...recentRides.map((ride) => _buildRecentRideCard(ride)),
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

  Widget _buildActiveRentalCard(Map<String, dynamic> rental) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rental['model'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRentalDetail(Icons.access_time, 'Start Time: ${rental['startTime']}'),
          _buildRentalDetail(Icons.timer, 'Duration: ${rental['duration']} hours'),
          _buildRentalDetail(Icons.attach_money, 'Cost: ৳${rental['cost']}'),
          _buildRentalDetail(Icons.location_on, rental['location']),
        ],
      ),
    );
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

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        if (action != null) action,
      ],
    );
  }
} 