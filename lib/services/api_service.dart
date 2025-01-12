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
      final response = await instance.get('cycles/nearby?lat=$lat&lng=$lng');
      if (response['cycles'] is List) {
        return List<Map<String, dynamic>>.from(response['cycles']);
      }
      return [];
    } catch (e) {
      print('Error getting nearby cycles: $e');
      return [];
    }
  }

  // Get rental history
  static Future<List<Map<String, dynamic>>> getRentalHistory() async {
    try {
      await instance._updateAuthHeader();
      final response = await instance.get('rentals/history');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
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
}