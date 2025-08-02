import 'package:flutter/material.dart';
import 'package:CycleX/services/api_service.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({Key? key}) : super(key: key);

  @override
  _RentalHistoryScreenState createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  List<Map<String, dynamic>> rentals = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final data = await ApiService.getRentalHistory();
      setState(() {
        rentals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error loading rental history: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshRentals() async {
    setState(() {
      isRefreshing = true;
    });
    
    try {
      final data = await ApiService.getRentalHistory();
      setState(() {
        rentals = data;
        isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isRefreshing = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error refreshing rental history: ${e.toString()}');
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
          onPressed: _loadRentals,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Rental History',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text(
                    'Loading rental history...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshRentals,
              child: rentals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 80,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No rental history found',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your rental history will appear here',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: rentals.length,
                      itemBuilder: (context, index) {
                        final rental = rentals[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rental #${rental['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    _getStatusChip(rental['status'] ?? 'Unknown', isDarkMode),
                                  ],
                                ),
                                SizedBox(height: 12),
                                _buildRentalInfo(
                                  'Duration',
                                  '${rental['duration'] ?? 0} hours',
                                  Icons.timer,
                                  isDarkMode,
                                ),
                                SizedBox(height: 8),
                                _buildRentalInfo(
                                  'Total Cost',
                                  '৳${rental['totalCost']?.toStringAsFixed(2) ?? '0.00'}',
                                  Icons.attach_money,
                                  isDarkMode,
                                ),
                                if (rental['startTime'] != null) ...[
                                  SizedBox(height: 8),
                                  _buildRentalInfo(
                                    'Start Time',
                                    _formatDateTime(rental['startTime']),
                                    Icons.access_time,
                                    isDarkMode,
                                  ),
                                ],
                                if (rental['endTime'] != null) ...[
                                  SizedBox(height: 8),
                                  _buildRentalInfo(
                                    'End Time',
                                    _formatDateTime(rental['endTime']),
                                    Icons.access_time_filled,
                                    isDarkMode,
                                  ),
                                ],
                                if (rental['cycleDetails'] != null) ...[
                                  SizedBox(height: 8),
                                  _buildRentalInfo(
                                    'Cycle',
                                    '${rental['cycleDetails']['brand'] ?? ''} ${rental['cycleDetails']['model'] ?? ''}',
                                    Icons.pedal_bike,
                                    isDarkMode,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildRentalInfo(String label, String value, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? Colors.teal[300] : Colors.teal[600],
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getStatusChip(String status, bool isDarkMode) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'completed':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        break;
      case 'cancelled':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      default:
        backgroundColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
        textColor = isDarkMode ? Colors.white : Colors.black87;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
      
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
} 