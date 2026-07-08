import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save basic user data after sign up
  Future<void> createUserProfile({
    required String email,
    required String region,
    required String province,
    required String municipality,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'region': region,
      'province': province,
      'municipality': municipality,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update survey answers (e.g. gender, age, etc.)
  Future<void> updateSurveyData(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Fetch user profile
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    return _firestore.collection('users').doc(uid).get();
  }
}
