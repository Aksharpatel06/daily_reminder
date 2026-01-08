import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  static AuthService authServices = AuthService._();
  AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String username,
    required String area,
    bool isAdmin = false, // Optional parameter, defaults to false
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: '12345678');

      final uid = userCredential.user?.uid;
      if (uid == null) return null;

      // Create user model with isAdmin defaulting to false
      final user = UserModel(
        userId: uid,
        name: username.trim(),
        email: email.trim(),
        area: area,
        createdAt: DateTime.now(),
        isAdmin: isAdmin, // This will be false unless explicitly set
      );

      // Store user data in Firestore
      await _firestore.collection("area").doc(uid).set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({required String area, required String email}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: '12345678');

      final uid = userCredential.user?.uid;
      if (uid == null) return null;

      // Fetch user data from Firestore
      final doc = await _firestore.collection('area').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('area').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user admin status (for admin users only)
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('area').doc(userId).update({'isAdmin': isAdmin});
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
}
