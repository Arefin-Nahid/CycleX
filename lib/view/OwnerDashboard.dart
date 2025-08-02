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
  bool isRefreshing = false;
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
      setState(() {
        isLoading = true;
      });
      
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
        _showErrorSnackBar('Error loading dashboard data: $e');
      }
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      isRefreshing = true;
    });
    
    try {
      final stats = await ApiService.instance.getOwnerDashboardStats();
      final activities = await ApiService.instance.getRecentActivities();

      setState(() {
        dashboardStats = stats;
        recentActivities = activities;
        isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error refreshing dashboard: $e');
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
          onPressed: _loadDashboardData,
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: CustomScrollView(
                slivers: [
                  // Custom App Bar
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    actions: [
                      if (isRefreshing)
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
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.teal.shade700,
                              Colors.teal.shade600,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              user?.displayName ?? 'Cycle Owner',
                              style: TextStyle(
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
                      padding: EdgeInsets.all(16.0),
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
                                isDarkMode,
                              ),
                              SizedBox(width: 16),
                              _buildStatCard(
                                'Active Rentals',
                                dashboardStats['activeRentals'].toString(),
                                Icons.timer,
                                Colors.green,
                                isDarkMode,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatCard(
                                'Total Earnings',
                                '৳${dashboardStats['totalEarnings'].toStringAsFixed(2)}',
                                Icons.attach_money,
                                Colors.orange,
                                isDarkMode,
                              ),
                              SizedBox(width: 16),
                              _buildStatCard(
                                'Reviews',
                                '${dashboardStats['averageRating'].toStringAsFixed(1)} ★',
                                Icons.star,
                                Colors.purple,
                                isDarkMode,
                              ),
                            ],
                          ),

                          SizedBox(height: 24),
                          
                          // Quick Actions
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildActionButton(
                            'Add New Cycle',
                            Icons.add_circle_outline,
                            _navigateToAddCycle,
                            isDarkMode,
                          ),
                          SizedBox(height: 12),
                          _buildActionButton(
                            'View All Cycles',
                            Icons.list_alt,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MyCyclesScreen()),
                              );
                            },
                            isDarkMode,
                          ),
                          SizedBox(height: 12),
                          _buildActionButton(
                            'Rental History',
                            Icons.history,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RentalHistoryScreen()),
                              );
                            },
                            isDarkMode,
                          ),

                          SizedBox(height: 24),
                          
                          // Recent Activities
                          Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (recentActivities.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 60,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No recent activities',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...recentActivities.map((activity) => _buildActivityCard(
                                  activity['title'] ?? 'Unknown Activity',
                                  activity['description'] ?? 'No description',
                                  activity['time'] ?? 'Unknown time',
                                  _getActivityIcon(activity['type'] ?? 'unknown'),
                                  _getActivityColor(activity['type'] ?? 'unknown'),
                                  isDarkMode,
                                )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCycle,
        icon: Icon(Icons.add),
        label: Text('Add Cycle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
    bool isDarkMode,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios, 
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
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
      case 'cycle_added':
        return Icons.add_circle;
      case 'cycle_updated':
        return Icons.edit;
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
      case 'cycle_added':
        return Colors.teal;
      case 'cycle_updated':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 