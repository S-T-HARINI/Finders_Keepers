import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_service.dart';
import 'firebase_storage_service.dart';

abstract class StorageService {
  Future<String?> pickImage({bool fromCamera = false});
  Future<String> uploadImage({required String localPath, required String folder});
}

class LocalStorageService implements StorageService {
  LocalStorageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickImage({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      return pickedFile?.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> uploadImage({required String localPath, required String folder}) async {
    // When Firebase Storage is unconfigured, keep local path or generate mock URL
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return localPath;
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  if (FirebaseService.isFirebaseInitialized) {
    return FirebaseStorageService();
  }
  return LocalStorageService();
});
