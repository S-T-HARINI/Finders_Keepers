import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

/// Production-ready Firebase Storage implementation of StorageService.
class FirebaseStorageService implements StorageService {
  FirebaseStorageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
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
  Future<String> uploadImage({
    required String localPath,
    required String folder,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      return localPath;
    }

    final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child(folder).child(filename);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
