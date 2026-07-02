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

  /// Deletes every meal photo belonging to [clientId]. Used by account
  /// deletion so no personal photos outlive the account. Must be called while
  /// the client is still authenticated (storage rules only let the owner
  /// delete their folder).
  Future<void> deleteAllMealPhotos(String clientId) async {
    final folder = _storage.ref().child('meal_images/$clientId');
    final listing = await folder.listAll();
    await Future.wait(listing.items.map((item) => item.delete()));
  }
}
