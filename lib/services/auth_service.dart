import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String get userId => _auth.currentUser?.uid ?? '';

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required String location,
    double latitude = 0.0,
    double longitude = 0.0,
    Map<String, dynamic>? roleSpecificData,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        location: location,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        roleSpecificData: roleSpecificData,
      );

      await _firestore
          .collection(AppConstants.colUsers)
          .doc(credential.user!.uid)
          .set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserById(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> signInAnonymously(
      {String role = AppConstants.roleContributor}) async {
    try {
      final credential = await _auth.signInAnonymously();

      final user = UserModel(
        id: credential.user!.uid,
        name: 'Guest User',
        email: '',
        phone: '',
        role: role,
        location: 'Unknown',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.colUsers)
          .doc(credential.user!.uid)
          .set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    return getUserById(currentUser!.uid);
  }

  Stream<UserModel?> streamCurrentUser() {
    if (currentUser == null) return Stream.value(null);
    return _firestore
        .collection(AppConstants.colUsers)
        .doc(currentUser!.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(user.id)
        .update({...user.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
