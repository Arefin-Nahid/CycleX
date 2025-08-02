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
  String selectedFilter = 'all'; // all, active, completed, cancelled

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
      
      final data = await ApiService.instance.getOwnerRentalHistory();
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
      final data = await ApiService.instance.getOwnerRentalHistory();
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

  List<Map<String, dynamic>> get filteredRentals {
    return rentals.where((rental) {
      // Apply status filter only
      if (selectedFilter != 'all' && rental['status']?.toString().toLowerCase() != selectedFilter) {
        return false;
      }
      
      return true;
    }).toList();
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
          : Column(
              children: [
                                 // Filter Section
                 Container(
                   padding: EdgeInsets.all(16),
                   child: SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: [
                         _buildFilterChip('All', 'all', isDarkMode),
                         SizedBox(width: 8),
                         _buildFilterChip('Active', 'active', isDarkMode),
                         SizedBox(width: 8),
                         _buildFilterChip('Completed', 'completed', isDarkMode),
                         SizedBox(width: 8),
                         _buildFilterChip('Cancelled', 'cancelled', isDarkMode),
                       ],
                     ),
                   ),
                 ),
                
                // Results Count
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredRentals.length} rental${filteredRentals.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (filteredRentals.isNotEmpty)
                        Text(
                          'Total: ৳${_calculateTotalEarnings().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Rental List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshRentals,
                    child: filteredRentals.isEmpty
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
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredRentals.length,
                            itemBuilder: (context, index) {
                              final rental = filteredRentals[index];
                              return _buildRentalCard(rental, isDarkMode);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDarkMode) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      selectedColor: Colors.teal,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental, bool isDarkMode) {
    final status = rental['status'] ?? 'unknown';
    final cycleModel = rental['cycleModel'] ?? 'Unknown Cycle';
    final duration = rental['duration'] ?? 0;
    final totalCost = rental['totalCost'] ?? 0.0;
    final rating = rental['rating'];
    final review = rental['review'];
    final startTime = rental['startTime'];
    final endTime = rental['endTime'];
    final location = rental['location'] ?? 'Unknown Location';
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cycleModel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                _getStatusChip(status, isDarkMode),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Duration and Cost
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Duration',
                    '$duration hours',
                    Icons.timer,
                    Colors.blue,
                    isDarkMode,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Total Cost',
                    '৳${totalCost.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Timing Information
            if (startTime != null || endTime != null) ...[
              Row(
                children: [
                  if (startTime != null) ...[
                    Expanded(
                      child: _buildInfoItem(
                        'Start Time',
                        _formatDateTime(startTime),
                        Icons.access_time,
                        Colors.green,
                        isDarkMode,
                      ),
                    ),
                  ],
                  if (startTime != null && endTime != null) ...[
                    SizedBox(width: 16),
                  ],
                  if (endTime != null) ...[
                    Expanded(
                      child: _buildInfoItem(
                        'End Time',
                        _formatDateTime(endTime),
                        Icons.access_time_filled,
                        Colors.red,
                        isDarkMode,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
            ],
            
            // Rating and Review
            if (rating != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$rating ★',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (review != null && review.toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.toString(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12),
            ],
            
            // Rental ID
            Row(
              children: [
                Icon(
                  Icons.tag,
                  size: 14,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                ),
                SizedBox(width: 8),
                Text(
                  'ID: ${rental['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
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

  double _calculateTotalEarnings() {
    return filteredRentals
        .where((rental) => rental['status']?.toString().toLowerCase() == 'completed')
        .fold(0.0, (sum, rental) => sum + (rental['totalCost'] ?? 0.0));
  }
} 