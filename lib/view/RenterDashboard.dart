import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:CycleX/Config/routes/PageConstants.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/view/QRScannerScreen.dart';
import 'package:CycleX/view/RentCycle.dart';
import 'package:CycleX/view/RentInProgressScreen.dart';
import 'package:CycleX/view/PaymentScreen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class RenterDashboard extends StatefulWidget {
  const RenterDashboard({Key? key}) : super(key: key);

  @override
  State<RenterDashboard> createState() => _RenterDashboardState();
}

class _RenterDashboardState extends State<RenterDashboard> with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic> dashboardStats = {
    'totalRides': 0,
    'totalSpent': 0.0,
    'totalRideTime': 0, // in minutes
    'totalDistance': 0.0, // in kilometers
    'averageRideTime': 0,
    'averageCostPerRide': 0.0,
    'averageDistance': 0.0,
  };
  List<Map<String, dynamic>> activeRentals = [];
  List<Map<String, dynamic>> recentRides = [];
  bool isProcessingQR = false;
  Timer? _liveUpdateTimer;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Theme colors
  final Color primaryColor = const Color(0xFF17153A);
  final Color accentColor = const Color(0xFF00D0C3);
  final Color tealColor = const Color(0xFF20B2AA);
  final Color mintColor = const Color(0xFF98FB98);
  final Color lightBlue = const Color(0xFF87CEEB);
  
  // Gradients
  final List<Color> tealGradient = [const Color(0xFF20B2AA), const Color(0xFF00D0C3)];
  final List<Color> mintGradient = [const Color(0xFF98FB98), const Color(0xFF90EE90)];
  final List<Color> blueGradient = [const Color(0xFF4A90E2), const Color(0xFF87CEEB)];
  final List<Color> purpleGradient = [const Color(0xFF8A2BE2), const Color(0xFFBA55D3)];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _startLiveUpdates();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (activeRentals.isNotEmpty && mounted) {
        setState(() {
          // This will trigger a rebuild to update live durations and costs
        });
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('🔄 Loading dashboard data...');
      
      // Load data with individual error handling
      Map<String, dynamic> stats = {};
      List<Map<String, dynamic>> actives = [];
      List<Map<String, dynamic>> rides = [];
      
      try {
        stats = await ApiService.instance.getRenterDashboardStats();
        print('✅ Dashboard stats loaded successfully');
      } catch (e) {
        print('❌ Failed to load dashboard stats: $e');
        stats = {
          'totalRides': 0,
          'totalSpent': 0.0,
          'totalRideTime': 0,
          'totalDistance': 0.0,
          'averageRideTime': 0,
          'averageCostPerRide': 0.0,
          'averageDistance': 0.0,
        };
      }
      
      try {
        actives = await ApiService.instance.getActiveRentals();
        print('✅ Active rentals loaded successfully');
      } catch (e) {
        print('❌ Failed to load active rentals: $e');
        actives = [];
      }
      
      try {
        rides = await ApiService.instance.getRecentRides();
        print('✅ Recent rides loaded successfully');
      } catch (e) {
        print('❌ Failed to load recent rides: $e');
        rides = [];
      }

      print('📊 Dashboard Stats: $stats');
      print('🚴 Active Rentals: $actives');
      print('📋 Recent Rides: $rides');

      setState(() {
        dashboardStats = {
          'totalRides': (stats['totalRides'] ?? 0).toInt(),
          'totalSpent': (stats['totalSpent'] ?? 0.0).toDouble(),
          'totalRideTime': (stats['totalRideTime'] ?? 0).toInt(), // in minutes from backend
          'totalDistance': (stats['totalDistance'] ?? 0.0).toDouble(), // in km from backend
          'averageRideTime': (stats['averageRideTime'] ?? 0).toInt(),
          'averageCostPerRide': (stats['averageCostPerRide'] ?? 0.0).toDouble(),
          'averageDistance': (stats['averageDistance'] ?? 0.0).toDouble(),
        };
        activeRentals = actives;
        recentRides = rides;
        isLoading = false;
      });
      
      print('✅ Dashboard data loaded successfully');
      
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() {
        // Set default values on error
        dashboardStats = {
          'totalRides': 0,
          'totalSpent': 0.0,
          'totalRideTime': 0,
          'totalDistance': 0.0,
          'averageRideTime': 0,
          'averageCostPerRide': 0.0,
          'averageDistance': 0.0,
        };
        activeRentals = [];
        recentRides = [];
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Some dashboard data could not be loaded. Pull to refresh to try again.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadDashboardData(),
            ),
          ),
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
      
      // Debug: Test API call first to check cycle availability
      print('🔍 Testing API call to get cycle details...');
      try {
        final cycleResponse = await ApiService.instance.getCycleById(cycleId);
        print('✅ Cycle details retrieved: ${cycleResponse['cycle']?['brand']} ${cycleResponse['cycle']?['model']}');
        
        // Check if cycle is available for rent
        final cycle = cycleResponse['cycle'];
        if (cycle == null) {
          throw Exception('Cycle not found');
        }
        
        if (cycle['isRented'] == true) {
          throw Exception('This cycle is already rented');
        }
        
        if (cycle['isActive'] != true) {
          throw Exception('This cycle is not available for rent');
        }
        
        print('✅ Cycle is available for rent');
        
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
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error processing QR code: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
    final backgroundColor = Colors.grey.shade50;
    final cardColor = Colors.white;
    final textColor = const Color(0xFF17153A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your dashboard...',
                            style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                        children: [
                                                // Modern Header
                        _buildModernHeader(),

                        // Primary Action Buttons
                        _buildPrimaryActions(),

                        const SizedBox(height: 20),

                        // Main Content Area
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: RefreshIndicator(
                              onRefresh: _loadDashboardData,
                              color: accentColor,
                              child: ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  // Enhanced Stats Panel (2x2 Grid)
                                  _buildEnhancedStatsPanel(cardColor, textColor),

                                  const SizedBox(height: 28),

                                  // Active Ride Section
                                  if (activeRentals.isNotEmpty) ...[
                                    _buildActiveRideSection(cardColor, textColor),
                                    const SizedBox(height: 28),
                                  ],

                                  // Recent Rides Section
                                  _buildRecentRidesSection(cardColor, textColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                            ],
                          ),
                        ),
                ),
        ),
      ),
    );
  }

  // ===== NEW MODERN UI COMPONENTS =====

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renter Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Welcome back! Ready for your next ride?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildModernActionButton(
              icon: Icons.map_rounded,
              label: 'Find Cycles',
              subtitle: 'Discover nearby bikes',
              gradient: tealGradient,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, PageConstants.mapViewScreen);
              },
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildModernActionButton(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              subtitle: 'Quick start',
              gradient: [Colors.white, Colors.grey.shade100],
              textColor: primaryColor,
              onPressed: isProcessingQR ? null : () {
                HapticFeedback.mediumImpact();
                _scanQRCode();
              },
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback? onPressed,
    required bool isPrimary,
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: textColor, size: 24),
                ),
                if (isProcessingQR && !isPrimary)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: isPrimary ? 18 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.trending_up_rounded, color: Colors.white, size: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsPanel(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Ride Statistics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your cycling journey',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260, // Increased height to accommodate all cards
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4, // Wider cards to prevent overflow
            children: [
              _buildEnhancedStatCard(
                title: 'Total Rides',
                value: '${(dashboardStats['totalRides'] ?? 0).toInt()}',
                subtitle: 'Completed successfully',
                icon: Icons.pedal_bike_rounded,
                gradient: tealGradient,
              ),
              _buildEnhancedStatCard(
                title: 'Total Spent',
                value: '৳${_formatCurrency(dashboardStats['totalSpent'] ?? 0.0)}',
                subtitle: 'Total investment',
                icon: Icons.account_balance_wallet_rounded,
                gradient: blueGradient,
              ),
              _buildEnhancedStatCard(
                title: 'Ride Time',
                value: _formatRideTime((dashboardStats['totalRideTime'] ?? 0).toInt()),
                subtitle: 'Time on road',
                icon: Icons.timer_rounded,
                gradient: mintGradient,
              ),
              _buildEnhancedStatCard(
                title: 'Distance',
                value: _formatDistance(dashboardStats['totalDistance'] ?? 0.0),
                subtitle: 'Distance traveled',
                icon: Icons.route_rounded,
                gradient: purpleGradient,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRideTime(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    }
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    if (amount < 10) return amount.toStringAsFixed(0);
    if (amount < 100) return amount.toStringAsFixed(0);
    if (amount < 1000) return amount.toStringAsFixed(0);
    return '${(amount / 1000).toStringAsFixed(1)}k';
  }

  String _formatDistance(double distance) {
    if (distance == 0) return '0 km';
    if (distance < 0.1) return '${(distance * 1000).toStringAsFixed(0)}m';
    if (distance < 1) return '${distance.toStringAsFixed(1)} km';
    if (distance < 10) return '${distance.toStringAsFixed(1)} km';
    return '${distance.toStringAsFixed(0)} km';
  }

  Widget _buildActiveRideSection(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_circle_filled_rounded, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ongoing Ride',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Your current cycling session',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...activeRentals.map((rental) => _buildLiveRentalCard(rental, cardColor, textColor)),
      ],
    );
  }

  Widget _buildRecentRidesSection(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.history_rounded, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Rides',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentRides.isEmpty)
          _buildEnhancedEmptyState()
        else ...[
          ...recentRides.take(3).map((ride) => _buildModernRideCard(ride, cardColor, textColor)),
        ],
      ],
    );
  }

  Widget _buildLiveRentalCard(Map<String, dynamic> rental, Color cardColor, Color textColor) {
    final cycle = rental['cycle'] ?? {};
    final startTime = DateTime.tryParse(rental['startTime'] ?? '') ?? DateTime.now();
    final currentTime = DateTime.now();
    final duration = currentTime.difference(startTime);
    
    // Calculate live duration and estimated cost
    final liveDurationMinutes = duration.inMinutes;
    final hourlyRate = cycle['hourlyRate']?.toDouble() ?? 20.0;
    final estimatedCost = (liveDurationMinutes / 60.0) * hourlyRate;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background elements
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with cycle info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                          style: const TextStyle(
                            color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'ID: ${rental['_id']?.substring(0, 8) ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Live stats grid
                Row(
                  children: [
                    Expanded(
                      child: _buildLiveStatItem(
                        icon: Icons.access_time_rounded,
                        label: 'Duration',
                        value: '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}',
                        isLive: true,
                      ),
                    ),
                    Expanded(
                      child: _buildLiveStatItem(
                        icon: Icons.attach_money_rounded,
                        label: 'Est. Cost',
                        value: '৳${estimatedCost.toStringAsFixed(2)}',
                        isLive: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildLiveStatItem(
                        icon: Icons.speed_rounded,
                        label: 'Rate',
                        value: '৳${hourlyRate.toStringAsFixed(0)}/hr',
                        isLive: false,
                      ),
                    ),
                    Expanded(
                      child: _buildLiveStatItem(
                        icon: Icons.location_on_rounded,
                        label: 'Started',
                        value: DateFormat('HH:mm').format(startTime),
                        isLive: false,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewRentalDetails(rental),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        label: const Text(
                          'View Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showEnhancedEndRideDialog(rental),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 20),
                      label: const Text(
                        'End Ride',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildLiveStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isLive,
  }) {
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
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isLive) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildModernRideCard(Map<String, dynamic> ride, Color cardColor, Color textColor) {
    final cycle = ride['cycle'] ?? {};
    final endTime = DateTime.tryParse(ride['endTime'] ?? '') ?? DateTime.now();
    final duration = (ride['duration'] ?? 0).toInt(); // in minutes
    final cost = (ride['totalCost'] ?? 0.0).toDouble();
    final distance = (ride['distance'] ?? 0.0).toDouble();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [blueGradient[0], blueGradient[1]],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cycle['brand'] ?? 'Unknown'} ${cycle['model'] ?? 'Cycle'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: textColor.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd • HH:mm').format(endTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 14, color: textColor.withOpacity(0.6)),
                    const SizedBox(width: 4),
                Text(
                      _formatRideTime(duration),
                  style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (distance > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.route_rounded, size: 14, color: textColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDistance(distance),
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'COMPLETED',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bike_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No rides yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first cycling adventure!\nFind nearby cycles and begin your journey.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, PageConstants.mapViewScreen),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text(
              'Find Cycles',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _showEnhancedEndRideDialog(Map<String, dynamic> rental) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'End Ride',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to end this ride?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please ensure you have parked the cycle in a safe and designated area before ending your ride.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'End Ride',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _endRental(rental);
    }
  }

  Future<void> _endRental(Map<String, dynamic> rental) async {
    try {
      HapticFeedback.heavyImpact();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
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
      final rentalId = rental['_id'] ?? rental['id'];
      final response = await ApiService.endRental(rentalId);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to payment screen
      if (mounted) {
        final completedRental = response['rental'] ?? rental;
        final amount = (completedRental['totalCost'] ?? 0.0).toDouble();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              rental: completedRental,
              amount: amount,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error ending ride: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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
} 