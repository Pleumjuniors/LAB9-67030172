import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final extension = imageFile.path.contains('.')
        ? imageFile.path.split('.').last.toLowerCase()
        : 'jpg';
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child('listings/$sellerId/$fileName');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }
}
