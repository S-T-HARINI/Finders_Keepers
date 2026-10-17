import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detects whether Firebase has been initialized in this application.
/// Allows transparent fallback to durable local persistence when running
/// in development, testing, or offline campus environments without
/// requiring fabricated credentials.
class FirebaseService {
  static bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String get configurationStatus {
    if (isFirebaseInitialized) {
      return 'Connected to Firebase (${Firebase.app().name})';
    } else {
      return 'Local Offline Mode (Durable persistence enabled; unconfigured cloud)';
    }
  }
}

final isFirebaseInitializedProvider = Provider<bool>((ref) {
  return FirebaseService.isFirebaseInitialized;
});
