import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'auth_repository.dart';
import 'user_model.dart';

/// Production-ready Firebase Authentication implementation.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserModel? _cachedUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        return null;
      }
      try {
        final doc = await _userDoc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _cachedUser = UserModel.fromFirestore(doc.data()!);
          return _cachedUser;
        }
      } catch (_) {}

      // Fallback if Firestore document is still propagating
      _cachedUser = UserModel(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? 'Campus Member',
        photoUrl: fbUser.photoURL,
        isAnonymous: fbUser.isAnonymous,
        createdAt: DateTime.now(),
      );
      return _cachedUser;
    });
  }

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _userDoc(uid).get();
    if (doc.exists && doc.data() != null) {
      _cachedUser = UserModel.fromFirestore(doc.data()!);
      return _cachedUser!;
    }
    _cachedUser = UserModel(
      id: uid,
      email: email.trim(),
      displayName: cred.user?.displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
    );
    return _cachedUser!;
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String campusId,
    UserRole role = UserRole.student,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(displayName);

    final user = UserModel(
      id: uid,
      email: email.trim(),
      displayName: displayName,
      campusId: campusId,
      role: role,
      createdAt: DateTime.now(),
    );

    await _userDoc(uid).set(user.toFirestore());
    _cachedUser = user;
    return user;
  }

  @override
  Future<UserModel> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final user = UserModel(
      id: cred.user!.uid,
      email: '',
      displayName: 'Campus Guest',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
    _cachedUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _cachedUser = null;
  }
}
