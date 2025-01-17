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

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    try {
      final data = await ApiService.getRentalHistory(); // Use static method
      setState(() {
        rentals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental History'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
              ? const Center(child: Text('No rental history found'))
              : ListView.builder(
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Rental #${rental['_id']}'),
                        subtitle: Text(
                          'Duration: ${rental['duration']} hours\n'
                          'Total Cost: ৳${rental['totalCost']}\n'
                          'Status: ${rental['status']}',
                        ),
                        trailing: _getStatusChip(rental['status']),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status),
      backgroundColor: color,
    );
  }
} 