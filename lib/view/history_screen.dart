import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _rentals = [];
  Map<String, dynamic> _stats = {};
  String _error = '';
  String _selectedFilter = 'all';

  final List<String> _filterOptions = ['all', 'completed', 'cancelled', 'active'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final data = await ApiService.getRentalHistory();
      if (mounted) {
        setState(() {
          _rentals = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
          _isRefreshing = false;
        });

        _calculateStats();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load rental history';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _calculateStats() {
    if (_rentals.isEmpty) {
      _stats = {
        'totalRides': 0,
        'totalSpent': 0.0,
        'totalDistance': 0.0,
        'totalTime': 0,
        'averageRating': 0.0,
        'completedRides': 0,
        'cancelledRides': 0,
      };
      return;
    }
    double totalSpent = 0.0;
    double totalDistance = 0.0;
    int totalTime = 0;
    double totalRating = 0.0;
    int ratingCount = 0;
    int completedRides = 0;
    int cancelledRides = 0;
    for (final rental in _rentals) {
      final cost = (rental['totalCost'] ?? 0.0).toDouble();
      final distance = (rental['distance'] ?? 0.0).toDouble();
      final duration = rental['duration'] ?? 0;
      final rating = rental['rating'];
      final status = rental['status'];

      totalSpent += cost;
      totalDistance += distance;
      totalTime += (duration as num).toInt();

      if (rating != null && rating > 0) {
        totalRating += rating.toDouble();
        ratingCount++;
      }

      if (status == 'completed') {
        completedRides++;
      } else if (status == 'cancelled') {
        cancelledRides++;
      }
    }

    _stats = {
      'totalRides': _rentals.length,
      'totalSpent': totalSpent,
      'totalDistance': totalDistance,
      'totalTime': totalTime,
      'averageRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
      'completedRides': completedRides,
      'cancelledRides': cancelledRides,
    };
  }

  List<Map<String, dynamic>> _getFilteredRentals() {
    if (_selectedFilter == 'all') {
      return _rentals;
    }
    return _rentals.where((rental) => rental['status'] == _selectedFilter).toList();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  String _formatCurrency(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'active':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'active':
        return Icons.pending_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  // ---- SMALLER Stats Card ----
  Widget _buildStatsCard(
      String title,
      String value,
      IconData icon,
      Color color, {
        String? subtitle,
      }) {
    // Use a higher contrast color for text/icons
    final Color foregroundColor = Colors.teal.shade800; // or Colors.black87

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: foregroundColor, size: 14), // DARKER ICON
              ),
              const Spacer(),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: foregroundColor, // DARKER TEXT
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: foregroundColor, // DARKER TEXT
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              color: foregroundColor, // DARKER TEXT
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final status = rental['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final startTime = DateTime.tryParse(rental['startTime'] ?? '') ?? DateTime.now();
    final endTime = rental['endTime'] != null ? DateTime.tryParse(rental['endTime'] ?? '') : null;
    final duration = rental['duration']?.toInt() ?? 0;
    final distance = rental['distance']?.toDouble() ?? 0.0;
    final cost = rental['totalCost']?.toDouble() ?? 0.0;
    final rating = rental['rating']?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental['cycleModel'] ?? 'Unknown Cycle',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating != null && rating > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rental['location'] ?? 'Unknown Location',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time and duration
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy\nHH:mm').format(startTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (endTime != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'End Time',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy\nHH:mm').format(endTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Duration',
                        _formatDuration(duration),
                        Icons.timer_outlined,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Distance',
                        _formatDistance(distance),
                        Icons.straighten_outlined,
                        const Color(0xFF10B981),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Cost',
                        _formatCurrency(cost),
                        Icons.account_balance_wallet_outlined,
                        const Color(0xFFF59E0B),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(7), // smaller
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.13),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.17), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, color: color, size: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Renting History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your renting history will appear here\nonce you start using our service.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.directions_bike),
            label: const Text('Start Riding', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                HapticFeedback.lightImpact();
              },
              backgroundColor: Colors.grey.shade50,
              selectedColor: const Color(0xFF667eea),
              checkmarkColor: Colors.black,
              side: BorderSide(
                color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRentals = _getFilteredRentals();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar and Stats area with changed gradient!
            Container(
              padding: const EdgeInsets.all(12), // smaller
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.teal.shade700,
                    Colors.teal.shade700,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade900.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Rent History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadHistory,
                        icon: Icon(
                          _isRefreshing ? Icons.refresh : Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Stats Cards
                  if (!_isLoading && _stats.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            'Total Rides',
                            _stats['totalRides'].toString(),
                            Icons.directions_bike_rounded,
                            Colors.grey[100]!,
                          ),
                        ),
                        Expanded(
                          child: _buildStatsCard(
                            'Total Spent',
                            _formatCurrency(_stats['totalSpent']),
                            Icons.account_balance_wallet_rounded,
                            Colors.grey[100]!,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            'Total Distance',
                            _formatDistance(_stats['totalDistance']),
                            Icons.straighten_rounded,
                            Colors.grey[100]!,
                          ),
                        ),
                        Expanded(
                          child: _buildStatsCard(
                            'Total Time',
                            _formatDuration(_stats['totalTime']),
                            Icons.timer_rounded,
                            Colors.grey[100]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Filter Chips
            if (!_isLoading && _rentals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFilterChips(),
            ],

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
                child: _buildTabContent(filteredRentals),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> rentals) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 16),
            Text(
              'Loading rental history...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (rentals.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isRefreshing = true;
          });
          await _loadHistory();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rentals.length,
          itemBuilder: (context, index) {
            return _buildRentalCard(rentals[index]);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}