import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// In-memory & testable AuthRepository implementation that supports
/// realistic auth state changes and offline development without requiring
/// a live Firebase project connection during initial setup.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({UserModel? initialUser}) : _currentUser = initialUser {
    _controller.add(_currentUser);
  }

  UserModel? _currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
    _currentUser = user;
    _controller.add(_currentUser);
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
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
    _currentUser = user;
    _controller.add(_currentUser);
    return user;
  }

  @override
  Future<UserModel> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final guest = UserModel.guest();
    _currentUser = guest;
    _controller.add(_currentUser);
    return guest;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = MockAuthRepository(initialUser: UserModel.guest());
  ref.onDispose(() {
    repo.dispose();
  });
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
