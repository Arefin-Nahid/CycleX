import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String baseUrl;
  late Map<String, String> _headers;

  ApiService({required this.baseUrl}) {
    _headers = {
      'Content-Type': 'application/json',
    };
  }

  // Static instance for global access
  static late ApiService instance;

  // Initialize the singleton instance
  static void initialize(String baseUrl) {
    instance = ApiService(baseUrl: baseUrl);
  }

  // Update headers with Firebase token
  Future<void> _updateAuthHeader() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        _headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting Firebase token: $e');
    }
  }

  // Verify if user has profile
  static Future<bool> verifyLogin(String uid) async {
    try {
      await instance._updateAuthHeader();
      final response = await instance.get('users/$uid');
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get nearby cycles
  static Future<List<Map<String, dynamic>>> getNearbyCycles({
    required double lat,
    required double lng
  }) async {
    try {
      await instance._updateAuthHeader();
      final response = await instance.get(
        'cycles/nearby?lat=$lat&lng=$lng'
      );
      if (response['cycles'] is List) {
        return List<Map<String, dynamic>>.from(
          response['cycles'].where((cycle) => cycle['isActive'])
        );
      }
      return [];
    } catch (e) {
      print('Error getting nearby cycles: $e');
      return [];
    }
  }

  // Get rental history - static method
  static Future<List<Map<String, dynamic>>> getRentalHistory() async {
    try {
      await instance._updateAuthHeader();
      final response = await instance.get('rentals/my-rentals');
      final data = response;
      return List<Map<String, dynamic>>.from(data['rentals']);
    } catch (e) {
      print('Error getting rental history: $e');
      return [];
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    try {
      await instance._updateAuthHeader();
      final response = await instance.post('users/create', userData);
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error registering user: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  // Basic HTTP methods
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform GET request: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Add a new cycle
  Future<Map<String, dynamic>> addCycle(Map<String, dynamic> cycleData) async {
    try {
      await _updateAuthHeader();
      final response = await http.post(
        Uri.parse('$baseUrl/owner/cycles'),
        headers: _headers,
        body: json.encode(cycleData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to add cycle: $e');
    }
  }

  // Get owner's cycles
  Future<List<Map<String, dynamic>>> getMyCycles() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/owner/cycles'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['cycles']);
    } catch (e) {
      throw Exception('Failed to get cycles: $e');
    }
  }

  // Get owner dashboard stats
  Future<Map<String, dynamic>> getOwnerDashboardStats() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/owner/dashboard'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/owner/activities'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['activities']);
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  // Get renter dashboard stats
  Future<Map<String, dynamic>> getRenterDashboardStats() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/renter/dashboard'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get renter dashboard stats: $e');
    }
  }

  // Get active rentals
  Future<List<Map<String, dynamic>>> getActiveRentals() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/renter/active-rentals'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['rentals']);
    } catch (e) {
      throw Exception('Failed to get active rentals: $e');
    }
  }

  // Get recent rides
  Future<List<Map<String, dynamic>>> getRecentRides() async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/renter/recent-rides'),
        headers: _headers,
      );
      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['rides']);
    } catch (e) {
      throw Exception('Failed to get recent rides: $e');
    }
  }

  // Get cycle details by ID
  Future<Map<String, dynamic>> getCycleById(String cycleId) async {
    try {
      await _updateAuthHeader();
      final response = await http.get(
        Uri.parse('$baseUrl/cycles/$cycleId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get cycle details: $e');
    }
  }

  // Rent cycle by scanning QR code
  Future<Map<String, dynamic>> rentCycleByQR(String cycleId) async {
    try {
      await _updateAuthHeader();
      final response = await http.post(
        Uri.parse('$baseUrl/rentals/scan-qr'),
        headers: _headers,
        body: json.encode({'cycleId': cycleId}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to rent cycle via QR: $e');
    }
  }
// Toggle cycle status
  Future<Map<String, dynamic>> toggleCycleStatus(
    String cycleId, 
    {Map<String, dynamic>? coordinates}
  ) async {
    try {
      await _updateAuthHeader();
      final response = await http.patch(
        Uri.parse('$baseUrl/owner/cycles/$cycleId/toggle-status'),
        headers: _headers,
        body: json.encode({
          'coordinates': coordinates,
          'location': coordinates?['address'], // Include the address
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to toggle cycle status: $e');
    }
  }
  // rentCycle method
  Future<void> rentCycle(String cycleId) async {
    try {
      await _updateAuthHeader(); // Ensure headers are updated with Firebase token
      final response = await post('rentals', {'cycleId': cycleId});
      return response; // Assuming your API responds with a success message
    } catch (e) {
      throw Exception('Failed to rent cycle: $e');
    }
  }

  // Delete cycle
  Future<void> deleteCycle(String cycleId) async {
    try {
      await _updateAuthHeader();
      final response = await http.delete(
        Uri.parse('$baseUrl/owner/cycles/$cycleId'),
        headers: _headers,
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete cycle: $e');
    }
  }
}