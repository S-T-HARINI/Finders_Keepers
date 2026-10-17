import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'claim_model.dart';
import 'claim_repository.dart';

/// Production-ready Cloud Firestore implementation of ClaimRepository.
class FirestoreClaimRepository implements ClaimRepository {
  FirestoreClaimRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _claimsRef =>
      _firestore.collection('claims');

  @override
  Future<String> submitClaim(ClaimModel claim) async {
    final docRef = claim.id.isNotEmpty ? _claimsRef.doc(claim.id) : _claimsRef.doc();
    await docRef.set(claim.toFirestore());
    return docRef.id;
  }

  @override
  Future<List<ClaimModel>> getClaimsForItem(String itemId) async {
    final snapshot = await _claimsRef
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ClaimModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<ClaimModel>> getClaimsByUser(String uid) async {
    final snapshot = await _claimsRef
        .where('claimantUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ClaimModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> updateClaimStatus(
    String claimId,
    ClaimStatus status, {
    String? notes,
  }) async {
    await _claimsRef.doc(claimId).update({
      'status': status.name,
      'reviewedAt': DateTime.now().toIso8601String(),
      if (notes != null) 'reviewNotes': notes,
    });
  }

  @override
  Stream<List<ClaimModel>> watchClaimsByUser(String uid) {
    return _claimsRef
        .where('claimantUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClaimModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
