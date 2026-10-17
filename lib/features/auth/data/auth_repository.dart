import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/local_cache_service.dart';
import 'firebase_auth_repository.dart';
import 'user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String campusId,
    UserRole role = UserRole.student,
  });
  Future<UserModel> signInAnonymously();
  Future<void> signOut();
}

/// Durable local AuthRepository implementation that supports
/// realistic auth state changes, local session persistence across restarts,
/// and offline campus use without requiring a live cloud project.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    UserModel? initialUser,
    LocalCacheService? cacheService,
  })  : _currentUser = initialUser,
        _cacheService = cacheService {
    _initFromCache();
  }

  final LocalCacheService? _cacheService;
  UserModel? _currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  Future<void> _initFromCache() async {
    if (_cacheService != null) {
      final cached = await _cacheService.loadCurrentUser();
      if (cached != null) {
        _currentUser = cached;
      }
    }
    _controller.add(_currentUser);
  }

  void _persistUser(UserModel? user) {
    _currentUser = user;
    _controller.add(_currentUser);
    _cacheService?.saveCurrentUser(user);
  }

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@')) {
      throw ArgumentError('Please enter a valid campus email address.');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }

    final user = UserModel(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      createdAt: DateTime.now(),
      campusId: 'CAMPUS-${email.hashCode.abs().toString().substring(0, 5)}',
      role: email.contains('admin') ? UserRole.admin : UserRole.student,
    );
    _persistUser(user);
    return user;
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String campusId,
    UserRole role = UserRole.student,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@')) {
      throw ArgumentError('Please enter a valid campus email address.');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }

    final user = UserModel(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      campusId: campusId,
      role: role,
    );
    _persistUser(user);
    return user;
  }

  @override
  Future<UserModel> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final guest = UserModel.guest();
    _persistUser(guest);
    return guest;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _persistUser(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider for AuthRepository with automatic dual-mode resolution
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (FirebaseService.isFirebaseInitialized) {
    return FirebaseAuthRepository();
  }
  final cache = ref.watch(localCacheServiceProvider);
  final repo = MockAuthRepository(
    initialUser: UserModel.guest(),
    cacheService: cache,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Stream provider for listening to authentication state changes
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Provider for the current user model
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull ?? ref.watch(authRepositoryProvider).currentUser;
});
