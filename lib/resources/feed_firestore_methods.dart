import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animal_trade/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';
import '../models/feed_post.dart';

class FeedFirestoreMethods {
  // KRİTİK: Lazy getter kullan - instance'ı hemen başlatma
  // Bu, Firestore settings'in AppDelegate'te ayarlanması için zaman tanır
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Yem ilanı yükleme
  Future<String> uploadFeed({
    required String description,
    required List<Uint8List> files,
    required String uid,
    required String username,
    required String profImage,
    required String country,
    required String state,
    required String city,
    required String feedType,
    required String feedCategory,
    required String animalType,
    required double quantityInKg,
    required String quantityUnit,
    required double priceInTL,
    required String priceUnit,
    required String brand,
    required String? productionDate,
    required String? expiryDate,
    required double? proteinPercentage,
    required double? energyValue,
    required bool isOrganic,
    required String packagingType,
    required bool isUrgentSale,
    required bool isBulkSale,
    required bool isLocal,
    required String sellerType,
    required String transportInfo,
    required bool isNegotiable,
    required Map<String, dynamic>? additionalInfo,
  }) async {
    String res = "Some error occurred";
    try {
      // Resim sayısını 10 ile sınırla
      List<Uint8List> limitedFiles =
          files.length > 10 ? files.sublist(0, 10) : files;

      List<String> photoUrls = [];
      // Her resmi yükle ve URL'leri al
      for (var file in limitedFiles) {
        String photoUrl =
            await StorageMethods().uploadImageToStorage('feeds', file, true);
        photoUrls.add(photoUrl);
      }

      String feedId = const Uuid().v1();
      FeedPost feed = FeedPost(
        description: description,
        uid: uid,
        username: username,
        postId: feedId,
        datePublished: DateTime.now(),
        photoUrls: photoUrls,
        profImage: profImage,
        country: country,
        state: state,
        city: city,
        feedType: feedType,
        feedCategory: feedCategory,
        animalType: animalType,
        quantityInKg: quantityInKg,
        quantityUnit: quantityUnit,
        priceInTL: priceInTL,
        priceUnit: priceUnit,
        brand: brand,
        productionDate: productionDate,
        expiryDate: expiryDate,
        proteinPercentage: proteinPercentage,
        energyValue: energyValue,
        isOrganic: isOrganic,
        packagingType: packagingType,
        isUrgentSale: isUrgentSale,
        isBulkSale: isBulkSale,
        isLocal: isLocal,
        sellerType: sellerType,
        transportInfo: transportInfo,
        isNegotiable: isNegotiable,
        additionalInfo: additionalInfo,
        likes: [],
        saved: [],
        isActive: true,
        soldDate: null,
        buyerUid: null,
        viewCount: 0,
        saleStatus: "active",
        salePrice: null,
        hasRating: false,
        ratingId: null,
        canBeRated: false,
      );

      // Feeds koleksiyonuna kaydet
      await _firestore
          .collection('feeds')
          .doc(feedId)
          .set({"random": FieldValue.serverTimestamp(), ...feed.toJson()});

      // Kullanıcının feeds array'ine ekle
      await _firestore.collection('users').doc(uid).update({
        'feeds': FieldValue.arrayUnion([feedId])
      });

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını beğenme
  Future<String> likeFeed(String feedId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        // Beğeniyi kaldır
        await _firestore.collection('feeds').doc(feedId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        // Beğeni ekle
        await _firestore.collection('feeds').doc(feedId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını kaydetme
  Future<String> saveFeed(String feedId, String uid, List saved) async {
    String res = "Some error occurred";
    try {
      if (saved.contains(uid)) {
        // Kaydetmekten çıkar
        await _firestore.collection('feeds').doc(feedId).update({
          'saved': FieldValue.arrayRemove([uid])
        });
      } else {
        // Kaydet
        await _firestore.collection('feeds').doc(feedId).update({
          'saved': FieldValue.arrayUnion([uid])
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını silme
  Future<String> deleteFeed(String feedId) async {
    String res = "Some error occurred";
    try {
      // Önce yem dokümanını al
      DocumentSnapshot feedDoc =
          await _firestore.collection('feeds').doc(feedId).get();
      if (!feedDoc.exists) {
        return "Feed does not exist";
      }

      Map<String, dynamic> feedData =
          feedDoc.data() as Map<String, dynamic>;
      String uid = feedData['uid'];

      // Batch işlem başlat
      WriteBatch batch = _firestore.batch();

      // Yem ile ilgili yorumları sil
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('feeds')
          .doc(feedId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Yem ile ilgili bildirimleri sil
      QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('postId', isEqualTo: feedId)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Kullanıcının feeds array'inden kaldır
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('feeds') && userData['feeds'] is List) {
          batch.update(_firestore.collection('users').doc(uid), {
            'feeds': FieldValue.arrayRemove([feedId])
          });
        }
      }

      // Yem dokümanını sil
      batch.delete(_firestore.collection('feeds').doc(feedId));

      // Batch'i commit et
      await batch.commit();

      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını satıldı olarak işaretle
  Future<String> markFeedAsSold(String feedId, String? buyerUid) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('feeds').doc(feedId).update({
        'isActive': false,
        'soldDate': DateTime.now(),
        'buyerUid': buyerUid,
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını güncelleme
  Future<String> updateFeed(
      String feedId, Map<String, dynamic> updates) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('feeds').doc(feedId).update(updates);
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanı yorumu ekleme
  Future<String> postFeedComment(String feedId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('feeds')
            .doc(feedId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanı yorumu silme
  Future<void> deleteFeedComment(String feedId, String commentId) async {
    try {
      await _firestore
          .collection('feeds')
          .doc(feedId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Yem ilanı bildirim ekleme
  Future<String> addFeedNotification(
      String type,
      String feedId,
      String feedOwnerId,
      String userId,
      String userName,
      String notificationText) async {
    String res = "Some error occurred";
    try {
      String notificationId = const Uuid().v1();
      await _firestore.collection('notifications').doc(notificationId).set({
        'type': type,
        'postId': feedId,
        'postOwnerId': feedOwnerId,
        'userId': userId,
        'userName': userName,
        'notificationText': notificationText,
        'date': DateTime.now()
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Yem ilanını rapor etme
  Future<void> reportFeed(String uid, String feedId, String reason) async {
    try {
      await _firestore.collection('feed_reports').add({
        'reporterId': uid,
        'feedId': feedId,
        'reason': reason,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Yem ilanını gizleme
  Future<void> hideFeed(String uid, String feedId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hiddenFeeds': FieldValue.arrayUnion([feedId])
      });
    } catch (e) {
      print(e.toString());
    }
  }
}










