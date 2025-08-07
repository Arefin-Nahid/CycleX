import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:CycleX/view/owner/AddCycleScreen.dart';
import 'package:CycleX/view/owner/MyCyclesScreen.dart';
import 'package:CycleX/view/owner/RentalHistoryScreen.dart';
import 'package:CycleX/services/api_service.dart';
import 'package:CycleX/services/timezone_service.dart';
import 'package:CycleX/Config/Allcolors.dart';
import 'package:CycleX/Config/AllDimensions.dart';
import 'package:CycleX/Config/AllTitles.dart';
import 'package:CycleX/Config/AllImages.dart';
import 'package:CycleX/view/MapView.dart';
import 'package:CycleX/view/ProfileScreen.dart';
import 'package:CycleX/view/QRScannerScreen.dart';
import 'package:CycleX/view/EditProfileScreen.dart';
import 'package:CycleX/view/NotificationsScreen.dart';
import 'package:CycleX/view/SecurityScreen.dart';
import 'package:CycleX/view/HelpSupportScreen.dart';

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
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        activity,
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
      Map<String, dynamic>? activity,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (activity != null) {
            _showActivityDetailsDialog(context, activity, color);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RentalHistoryScreen()),
            );
          }
        },
        child: Container(
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 18),
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
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          _formatActivityTime(time),
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 12,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetailsDialog(BuildContext context, Map<String, dynamic> activity, Color color) {
    final type = activity['type'] ?? 'unknown';
    final title = activity['title'] ?? 'Unknown Activity';
    final description = activity['description'] ?? 'No description';
    final time = activity['time'] ?? 'Unknown time';
    final amount = activity['amount'];
    final rating = activity['rating'];
    final duration = activity['duration'];
    final cycleModel = activity['cycleModel'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double maxDialogWidth = constraints.maxWidth < 350 ? constraints.maxWidth - 24 : 350;
            return Dialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: maxDialogWidth,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Changed for overflow fix
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getActivityIcon(type),
                          color: color,
                          size: 38,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      if (cycleModel != null)
                        Text(
                          cycleModel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      SizedBox(height: 10),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                      SizedBox(height: 18),
                      Divider(),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.teal, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Time:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                _formatActivityTime(time),
                                style: TextStyle(fontSize: 15),
                              )),
                        ],
                      ),
                      if (duration != null)
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.teal, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Duration:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("$duration hours", style: TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      if (amount != null)
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.teal, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("৳${amount.toStringAsFixed(2)}", style: TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      if (rating != null)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Rating:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text("$rating ★", style: TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                textStyle: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: Icon(Icons.visibility),
                              label: Text('View Details'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                switch (type) {
                                  case 'rental_request':
                                  case 'payment':
                                  case 'review':
                                  case 'rental_cancelled':
                                  case 'rental_update':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const RentalHistoryScreen()),
                                    );
                                    break;
                                  case 'cycle_added':
                                  case 'cycle_updated':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MyCyclesScreen()),
                                    );
                                    break;
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(color: color, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                                textStyle: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              icon: Icon(Icons.close),
                              label: Text('Close'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
      case 'rental_cancelled':
        return Icons.cancel;
      case 'rental_update':
        return Icons.update;
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
      case 'rental_cancelled':
        return Colors.red;
      case 'rental_update':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';

    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return 'Invalid Date';
      }

      // Use Bangladesh timezone for formatting
      return TimezoneService.formatTime(dt, format: 'dd/MM/yyyy HH:mm');
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatActivityTime(String time) {
    if (time == null || time == 'Unknown time') return 'Just now';

    try {
      DateTime dt = DateTime.parse(time);
      // Use Bangladesh timezone for relative time calculation
      return TimezoneService.getRelativeTime(dt);
    } catch (e) {
      return 'Unknown time';
    }
  }
}