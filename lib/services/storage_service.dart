import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles all Firebase Storage uploads for the app.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a meal photo for [clientId] and returns its public download URL.
  ///
  /// Images are stored at: meal_images/{clientId}/{timestamp}.jpg
  Future<String> uploadMealPhoto(String clientId, Uint8List imageBytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('meal_images/$clientId/$fileName');

    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }
}
