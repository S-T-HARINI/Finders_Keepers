import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/local_cache_service.dart';
import 'claim_model.dart';
import 'firestore_claim_repository.dart';

abstract class ClaimRepository {
  Future<String> submitClaim(ClaimModel claim);
  Future<List<ClaimModel>> getClaimsForItem(String itemId);
  Future<List<ClaimModel>> getClaimsByUser(String uid);
  Future<void> updateClaimStatus(String claimId, ClaimStatus status, {String? notes});
  Stream<List<ClaimModel>> watchClaimsByUser(String uid);
}

class MockClaimRepository implements ClaimRepository {
  MockClaimRepository({LocalCacheService? cacheService}) : _cacheService = cacheService {
    _initFromCache();
  }

  final LocalCacheService? _cacheService;
  final List<ClaimModel> _claims = [];
  final _controller = StreamController<List<ClaimModel>>.broadcast();

  Future<void> _initFromCache() async {
    if (_cacheService != null) {
      final cached = await _cacheService.loadClaims();
      if (cached.isNotEmpty) {
        _claims.clear();
        _claims.addAll(cached);
      }
    }
    _broadcast();
  }

  void _broadcast() {
    _controller.add(List.unmodifiable(_claims));
    _cacheService?.saveClaims(_claims);
  }

  @override
  Future<String> submitClaim(ClaimModel claim) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final claimId = claim.id.isNotEmpty ? claim.id : 'clm_${DateTime.now().millisecondsSinceEpoch}';
    final savedClaim = claim.copyWith(id: claimId);
    _claims.insert(0, savedClaim);
    _broadcast();
    return claimId;
  }

  @override
  Future<List<ClaimModel>> getClaimsForItem(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _claims.where((c) => c.itemId == itemId).toList();
  }

  @override
  Future<List<ClaimModel>> getClaimsByUser(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _claims.where((c) => c.claimantUid == uid).toList();
  }

  @override
  Future<void> updateClaimStatus(String claimId, ClaimStatus status, {String? notes}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index != -1) {
      final updated = _claims[index].copyWith(
        status: status,
        reviewedAt: DateTime.now(),
        reviewNotes: notes,
      );
      _claims[index] = updated;
      _broadcast();
    }
  }

  @override
  Stream<List<ClaimModel>> watchClaimsByUser(String uid) async* {
    yield _claims.where((c) => c.claimantUid == uid).toList();
    yield* _controller.stream.map((list) => list.where((c) => c.claimantUid == uid).toList());
  }

  void dispose() {
    _controller.close();
  }
}

final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  if (FirebaseService.isFirebaseInitialized) {
    return FirestoreClaimRepository();
  }
  final cache = ref.watch(localCacheServiceProvider);
  final repo = MockClaimRepository(cacheService: cache);
  ref.onDispose(repo.dispose);
  return repo;
});

final userClaimsStreamProvider = StreamProvider.autoDispose.family<List<ClaimModel>, String>((ref, uid) {
  final repo = ref.watch(claimRepositoryProvider);
  return repo.watchClaimsByUser(uid);
});

final itemClaimsProvider = FutureProvider.autoDispose.family<List<ClaimModel>, String>((ref, itemId) {
  final repo = ref.watch(claimRepositoryProvider);
  return repo.getClaimsForItem(itemId);
});
