import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // adding image to firebase storage
  Future<String> uploadImageToStorage(
      String childName, Uint8List file, bool isPost) async {
    // creating location to our firebase storage
    try {
      // KRİTİK: Authentication kontrolü
      if (_auth.currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final userId = _auth.currentUser!.uid;
      print('📤 [Storage] Upload başlıyor - User ID: $userId');
      
      // KRİTİK: Storage bucket URL kontrolü
      final bucket = _storage.app.options.storageBucket;
      print('📤 [Storage] Storage bucket: $bucket');
      
      // KRİTİK: Ref path oluşturma - doğru format kontrolü
      Reference ref = _storage.ref().child(childName).child(userId);
      if (isPost) {
        String id = const Uuid().v1();
        ref = ref.child(id);
      }
      
      print('📤 [Storage] Reference path: ${ref.fullPath}');
      print('📤 [Storage] Reference bucket: ${ref.bucket}');

      // KRİTİK: Metadata'yı tamamen kaldırıyoruz (412 hatası çözümü)
      // Metadata olmadan upload deniyoruz
      UploadTask uploadTask = ref.putData(file);

      // Upload tamamlanana kadar bekle - timeout ile
      TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );
      
      print('✅ [Storage] Upload tamamlandı');

      // Download URL'sini al
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ [Storage] Download URL alındı: ${downloadUrl.substring(0, 50)}...');
      return downloadUrl;
    } catch (e) {
      print('❌ [Storage] Error uploading image: $e');
      print('❌ [Storage] Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('❌ [Storage] Firebase error code: ${e.code}');
        print('❌ [Storage] Firebase error message: ${e.message}');
        print('❌ [Storage] Firebase error plugin: ${e.plugin}');
      }
      // HTTP 412 hatası için özel mesaj
      if (e.toString().contains('412') || e.toString().contains('Precondition Failed')) {
        print('❌ [Storage] HTTP 412 hatası tespit edildi!');
        print('   Olası nedenler:');
        print('   1. App Check token geçersiz');
        print('   2. Storage bucket URL uyuşmazlığı');
        print('   3. Storage rules precondition başarısız');
        print('   4. Firebase Storage bucket ayarları');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Firebase Storage by download URL
  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  // KRİTİK: Download URL'ini yenile (412 hatası çözümü)
  // Eski token'lar expire olmuş olabilir, yeni token al
  Future<String> refreshDownloadUrl(String oldUrl) async {
    try {
      final ref = _storage.refFromURL(oldUrl);
      final newUrl = await ref.getDownloadURL();
      print('✅ [Storage] Download URL yenilendi: ${newUrl.substring(0, 50)}...');
      return newUrl;
    } catch (e) {
      print('❌ [Storage] Download URL yenileme hatası: $e');
      return oldUrl; // Hata durumunda eski URL'i döndür
    }
  }

  // KRİTİK: Default profile picture için yeni download URL al
  static Future<String> getDefaultProfilePictureUrl() async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('defaultprofilephoto/defaultphoto.jpg');
      final url = await ref.getDownloadURL();
      print('✅ [Storage] Default profile picture URL alındı: ${url.substring(0, 50)}...');
      return url;
    } catch (e) {
      print('❌ [Storage] Default profile picture URL hatası: $e');
      // Fallback URL (eski token ile)
      return "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaultprofilephoto%2Fdefaultphoto.jpg?alt=media&token=1e70e65b-84f0-4819-9cd6-52104e271dd8";
    }
  }
}
