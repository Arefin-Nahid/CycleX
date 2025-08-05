import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDatabaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Update the lock status of a cycle in Firebase Realtime Database
  /// [cycleId] - The cycle ID
  /// [isLocked] - 1 for locked, 0 for unlocked
  static Future<Map<String, dynamic>> updateCycleLockStatus(String cycleId, int isLocked) async {
    try {
      print('Firebase: Updating lock status for cycle $cycleId to $isLocked');
      
      // Update the cycle's lock status in Firebase Realtime Database
      await _database.child('cycles').child(cycleId).update({
        'isLocked': isLocked,
        'lastUpdated': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

              print('Firebase: Successfully updated lock status for cycle $cycleId');
      
      return {
        'success': true,
        'cycleId': cycleId,
        'isLocked': isLocked,
        'message': 'Cycle lock status updated to ${isLocked == 1 ? 'locked' : 'unlocked'}'
      };
    } catch (error) {
              print('Firebase: Error updating lock status for cycle $cycleId: $error');
      throw Exception('Failed to update cycle lock status: $error');
    }
  }

  /// Get the current lock status of a cycle from Firebase Realtime Database
  /// [cycleId] - The cycle ID
  static Future<Map<String, dynamic>> getCycleLockStatus(String cycleId) async {
    try {
      print('Firebase: Getting lock status for cycle $cycleId');
      
      final snapshot = await _database.child('cycles').child(cycleId).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
                  print('Firebase: No data found for cycle $cycleId');
        return {
          'success': false,
          'cycleId': cycleId,
          'message': 'Cycle not found in Firebase'
        };
      }

              print('Firebase: Retrieved lock status for cycle $cycleId: $data');
      
      return {
        'success': true,
        'cycleId': cycleId,
        'isLocked': data['isLocked'] ?? 0,
        'lastUpdated': data['lastUpdated'],
        'timestamp': data['timestamp'],
        'data': data
      };
    } catch (error) {
              print('Firebase: Error getting lock status for cycle $cycleId: $error');
      throw Exception('Failed to get cycle lock status: $error');
    }
  }

  /// Initialize a cycle in Firebase Realtime Database
  /// [cycleId] - The cycle ID
  /// [cycleData] - Initial cycle data
  static Future<Map<String, dynamic>> initializeCycle(String cycleId, Map<String, dynamic> cycleData) async {
    try {
      print('🔧 Firebase: Initializing cycle $cycleId in Realtime Database');
      
      await _database.child('cycles').child(cycleId).set({
        'isLocked': 0, // Default to unlocked
        'lastUpdated': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...cycleData
      });

              print('Firebase: Successfully initialized cycle $cycleId');
      
      return {
        'success': true,
        'cycleId': cycleId,
        'message': 'Cycle initialized in Firebase Realtime Database'
      };
    } catch (error) {
              print('Firebase: Error initializing cycle $cycleId: $error');
      throw Exception('Failed to initialize cycle: $error');
    }
  }

  /// Delete a cycle from Firebase Realtime Database
  /// [cycleId] - The cycle ID
  static Future<Map<String, dynamic>> deleteCycle(String cycleId) async {
    try {
      print('🗑️ Firebase: Deleting cycle $cycleId from Realtime Database');
      
      await _database.child('cycles').child(cycleId).remove();

              print('Firebase: Successfully deleted cycle $cycleId');
      
      return {
        'success': true,
        'cycleId': cycleId,
        'message': 'Cycle deleted from Firebase Realtime Database'
      };
    } catch (error) {
              print('Firebase: Error deleting cycle $cycleId: $error');
      throw Exception('Failed to delete cycle: $error');
    }
  }

  /// Get all cycles from Firebase Realtime Database
  static Future<Map<String, dynamic>> getAllCycles() async {
    try {
      print('Firebase: Getting all cycles from Realtime Database');
      
      final snapshot = await _database.child('cycles').once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

              print('Firebase: Retrieved ${data?.length ?? 0} cycles');
      
      return {
        'success': true,
        'cycles': data ?? {},
        'count': data?.length ?? 0
      };
    } catch (error) {
              print('Firebase: Error getting all cycles: $error');
      throw Exception('Failed to get all cycles: $error');
    }
  }

  /// Listen to real-time updates for a specific cycle
  /// [cycleId] - The cycle ID
  /// [onData] - Callback function to handle data updates
  static Stream<DatabaseEvent> listenToCycleUpdates(String cycleId) {
    return _database.child('cycles').child(cycleId).onValue;
  }

  /// Listen to real-time updates for all cycles
  /// [onData] - Callback function to handle data updates
  static Stream<DatabaseEvent> listenToAllCyclesUpdates() {
    return _database.child('cycles').onValue;
  }

  /// Lock a cycle (set isLocked to 1)
  /// [cycleId] - The cycle ID
  static Future<Map<String, dynamic>> lockCycle(String cycleId) async {
    return await updateCycleLockStatus(cycleId, 1);
  }

  /// Unlock a cycle (set isLocked to 0)
  /// [cycleId] - The cycle ID
  static Future<Map<String, dynamic>> unlockCycle(String cycleId) async {
    return await updateCycleLockStatus(cycleId, 0);
  }

  /// Check if a cycle is currently locked
  /// [cycleId] - The cycle ID
  static Future<bool> isCycleLocked(String cycleId) async {
    try {
      final status = await getCycleLockStatus(cycleId);
      if (status['success']) {
        return status['isLocked'] == 1;
      }
      return false;
    } catch (error) {
              print('Firebase: Error checking if cycle is locked: $error');
      return false;
    }
  }
} 