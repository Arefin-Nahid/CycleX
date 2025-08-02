import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CycleX/view/owner/AddCycleScreen.dart';
import 'package:CycleX/view/owner/MyCyclesScreen.dart';
import 'package:CycleX/view/owner/RentalHistoryScreen.dart';
import 'package:CycleX/services/api_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({Key? key}) : super(key: key);

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  Map<String, dynamic> dashboardStats = {
    'totalCycles': 0,
    'activeRentals': 0,
    'totalEarnings': 0.0,
    'averageRating': 0.0,
  };
  List<Map<String, dynamic>> recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final stats = await ApiService.instance.getOwnerDashboardStats();
      final activities = await ApiService.instance.getRecentActivities();

      setState(() {
        dashboardStats = stats;
        recentActivities = activities;
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

  Future<void> _navigateToAddCycle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCycleScreen()),
    );
    if (result == true) {
      // Refresh dashboard data when a new cycle is added
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.teal.shade700,
                            Colors.teal.shade700,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user?.displayName ?? 'Cycle Owner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dashboard Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Cards
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Cycles',
                              dashboardStats['totalCycles'].toString(),
                              Icons.pedal_bike,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Active Rentals',
                              dashboardStats['activeRentals'].toString(),
                              Icons.timer,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Earnings',
                              '৳${dashboardStats['totalEarnings'].toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.orange,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Reviews',
                              '${dashboardStats['averageRating'].toStringAsFixed(1)} ★',
                              Icons.star,
                              Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionButton(
                          'Add New Cycle',
                          Icons.add_circle_outline,
                          _navigateToAddCycle,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'View All Cycles',
                          Icons.list_alt,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyCyclesScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'Rental History',
                          Icons.history,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RentalHistoryScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        
                        // Recent Activities
                        const Text(
                          'Recent Activities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...recentActivities.map((activity) => _buildActivityCard(
                              activity['title'],
                              activity['description'],
                              activity['time'],
                              _getActivityIcon(activity['type']),
                              _getActivityColor(activity['type']),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCycle,
        icon: const Icon(Icons.add),
        label: const Text('Add Cycle'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
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
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              // Handle activity tap
            },
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'rental_request':
        return Icons.notifications_active;
      case 'payment':
        return Icons.payments;
      case 'review':
        return Icons.star;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'rental_request':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 