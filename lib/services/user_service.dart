import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Promote a user to manager/admin role
  static Future<void> promoteToManager({
    required String userId,
    required String organisationId,
  }) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      await userDocRef.update({
        'role': 'manager',
        'organisationId': organisationId,
      });
    } else {
      throw Exception('User not found for promotion: $userId');
    }
  }

  // Demote a manager back to employee role
  static Future<void> demoteToEmployee({required String userId}) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      await userDocRef.update({'role': 'employee'});
    } else {
      throw Exception('User not found for demotion: $userId');
    }
  }

  static Future<String?> getUserRole(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['role'] is String) {
        return data['role'] as String;
      }
    }
    return null;
  }
}
