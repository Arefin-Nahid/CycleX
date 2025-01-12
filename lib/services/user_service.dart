import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<Map<String, dynamic>> createUserProfile({
    required String name,
    required String studentId,
    required String department,
    required String phone,
    required String address,
  }) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    return await _apiService.post('users/create', {
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'studentId': studentId,
      'department': department,
      'phone': phone,
      'address': address,
    });
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    return await _apiService.get('users/${user.uid}');
  }

  Future<Map<String, dynamic>> updateUserRole(String role) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    return await _apiService.post('users/update-role', {
      'uid': user.uid,
      'role': role,
    });
  }
} 