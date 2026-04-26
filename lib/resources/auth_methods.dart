import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animal_trade/models/user.dart' as model;
import 'package:animal_trade/resources/storage_methods.dart';
import 'package:animal_trade/services/fcm_token_manager.dart';
import 'dart:io' if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthMethods {
  // Use lazy getter to avoid initializing Firestore before settings are configured
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // KRİTİK: Default profile picture URL'i (412 hatası çözümü - token kaldırıldı)
  // Eski token expire olmuş olabilir, token olmadan URL kullanıyoruz (Storage rules herkese açık)
  String photoUrl =
      "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaultprofilephoto%2Fdefaultphoto.jpg?alt=media";

  // get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    return await getUserDetailsFromFirestore(currentUser.uid);
  }

  // Get user details from Firestore using uid
  // KRİTİK: Timeout eklenmiş (2 saniye) - beyaz ekran sorununu önlemek için
  Future<model.User> getUserDetailsFromFirestore(String uid) async {
    try {
      // Timeout ekle - Firestore bağlantısı yoksa veya yavaşsa takılmasın
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            Duration(seconds: 2),
            onTimeout: () {
              print('⚠️ AuthMethods: Firestore get timeout (2 saniye), varsayılan kullanıcı döndürülüyor');
              // Timeout durumunda boş bir snapshot döndür (exists false olacak)
              throw TimeoutException('Firestore get timeout', Duration(seconds: 2));
            },
          );

      if (documentSnapshot.exists) {
        return model.User.fromSnap(documentSnapshot);
      } else {
        // Return a default user if document doesn't exist
        print('⚠️ AuthMethods: Kullanıcı dokümanı Firestore\'da yok: $uid');
        return model.User(
          username: "",
          uid: uid,
          email: "",
          bio: "",
          followers: [],
          following: [],
          blocked: [],
          blockedBy: [],
        );
      }
    } on TimeoutException catch (e) {
      print("⚠️ AuthMethods: getUserDetailsFromFirestore timeout: $e");
      // Return a default user on timeout
      return model.User(
        username: "",
        uid: uid,
        email: "",
        bio: "",
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    } catch (e) {
      print("❌ AuthMethods: Error getting user details: $e");
      // Return a default user on error
      return model.User(
        username: "",
        uid: uid,
        email: "",
        bio: "",
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }

  // Signing Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List? file,
  }) async {
    String res = "Some error Occurred";
    try {
      final normalizedUsername = username.trim();
      if (password.length < 6) {
        res = "Password should be at least 6 characters long";
      } else if (normalizedUsername.isEmpty || normalizedUsername.length > 25) {
        res = "Username should be between 1 and 25 characters long";
      } else if (bio.length > 100) {
        res = "Bio should be at most 150 characters long";
      } else {
        // Create user with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Prepare profile picture
        if (file != null) {
          photoUrl = await StorageMethods()
              .uploadImageToStorage('profilePics', file, true);
        } else {
          photoUrl =
              "https://firebasestorage.googleapis.com/v0/b/canlipazar-b3697.firebasestorage.app/o/defaultprofilephoto%2Fdefaultphoto.jpg?alt=media&token=1e70e65b-84f0-4819-9cd6-52104e271dd8";
        }

        // Prepare user data as a Map directly, avoiding potential issues with User model
        // KRİTİK: Platform bilgisini belirle
        String platform = 'unknown';
        if (!kIsWeb) {
          if (io.Platform.isIOS) {
            platform = 'ios';
          } else if (io.Platform.isAndroid) {
            platform = 'android';
          }
        }
        
        final userData = {
          'username': normalizedUsername,
          'uid': cred.user!.uid,
          'photoUrl': photoUrl,
          'email': email,
          'bio': bio,
          'matched_with': null,
          'followers': [],
          'following': [],
          'blocked': [],
          'blockedBy': [],
          'country': "",
          'state': "",
          'city': "",
          'match_count': 0,
          'is_premium': false,
          'number_of_sent_gifts': 0,
          'number_of_unsent_gifts': 0,
          'gift_sending_rate': "",
          'isVerified': false,
          'isConfirmed': false,
          'gift_point': 0.0,
          'isRated': false,
          'rateCount': 0,
          'fcmToken': "",
          'platform': platform, // ✅ Platform bilgisi eklendi
          'credit': 0,
          'referralCode': "",
          'referredBy': "",
        };
        
        print('✅ AuthMethods: Kullanıcı kaydı yapılıyor, platform: $platform');

        // Save user data to Firestore
        await _firestore.collection("users").doc(cred.user!.uid).set(userData);

        // FCM Token'ı kaydet (kayıt başarılı olduktan sonra) - YENİ FCMTokenManager kullan
        try {
          print('🔄 AuthMethods: Kullanıcı kaydı başarılı, FCM token kaydı başlatılıyor...');
          final fcmManager = FCMTokenManager();
          await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
          final success = await fcmManager.saveTokenToFirestore(forceRetry: true);
          
          if (success) {
            // Token'ın kaydedildiğini doğrula (kısa bir gecikme sonrası)
            await Future.delayed(Duration(milliseconds: 1000));
            final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
            final storedToken = userDoc.data()?['fcmToken'] as String?;
            final storedPlatform = userDoc.data()?['platform'] as String?;
            
            if (storedToken != null && storedToken.trim().isNotEmpty) {
              print('✅ AuthMethods: FCM Token başarıyla kaydedildi ve doğrulandı (signup)');
              print('✅ AuthMethods: Token: ${storedToken.substring(0, 20)}...');
              print('✅ AuthMethods: Platform: $storedPlatform');
            } else {
              print('⚠️ AuthMethods: FCM Token kaydedildi ama doğrulanamadı (signup) - Firestore gecikmesi olabilir');
            }
          } else {
            print('⚠️ AuthMethods: FCM Token kaydı başarısız (signup) - UserProvider\'da tekrar denenecek');
          }
        } catch (e, stackTrace) {
          print('❌ AuthMethods: FCM Token kaydı başarısız (signup): $e');
          print('❌ AuthMethods: Stack trace: $stackTrace');
          // Hata olsa bile devam et - UserProvider'da tekrar denenecek
        }

        res = "success";
      }
    } catch (err) {
      print("Error during signup: $err");
      return err.toString();
    }
    return res;
  }

  // logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error Occurred";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        FirebaseAuth.instance.idTokenChanges().listen((User? user) {
          if (user == null) {
            print('User is currently signed out!');
          } else {
            print('User is signed in!');
          }
        });

        QuerySnapshot deletedUserQuery = await _firestore
            .collection("deleted_users")
            .where("email", isEqualTo: email)
            .get();
        if (deletedUserQuery.docs.isNotEmpty) {
          res = "Deleted account. Please contact support";
        } else {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // FCM Token'ı kaydet (giriş başarılı olduktan sonra) - YENİ FCMTokenManager kullan
          try {
            print('🔄 AuthMethods: Kullanıcı girişi başarılı, FCM token kaydı başlatılıyor...');
            final fcmManager = FCMTokenManager();
            await fcmManager.checkAndSavePendingToken(); // Geçici token varsa kaydet
            final success = await fcmManager.saveTokenToFirestore(forceRetry: true);
            
            if (success) {
              // Token'ın kaydedildiğini doğrula (kısa bir gecikme sonrası)
              await Future.delayed(Duration(milliseconds: 1000));
              final currentUser = _auth.currentUser;
              if (currentUser != null) {
                final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
                final storedToken = userDoc.data()?['fcmToken'] as String?;
                final storedPlatform = userDoc.data()?['platform'] as String?;
                
                if (storedToken != null && storedToken.trim().isNotEmpty) {
                  print('✅ AuthMethods: FCM Token başarıyla kaydedildi ve doğrulandı (login)');
                  print('✅ AuthMethods: Token: ${storedToken.substring(0, 20)}...');
                  print('✅ AuthMethods: Platform: $storedPlatform');
                } else {
                  print('⚠️ AuthMethods: FCM Token kaydedildi ama doğrulanamadı (login) - Firestore gecikmesi olabilir');
                }
              }
            } else {
              print('⚠️ AuthMethods: FCM Token kaydı başarısız (login) - UserProvider\'da tekrar denenecek');
            }
          } catch (e, stackTrace) {
            print('❌ AuthMethods: FCM Token kaydı başarısız (login): $e');
            print('❌ AuthMethods: Stack trace: $stackTrace');
            // Hata olsa bile devam et - UserProvider'da tekrar denenecek
          }
          
          res = "success";
        }
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      return "Invalid email or password";
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();

    FirebaseAuth.instance.idTokenChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  // image variable is of type Uint8List
  Future<String> updateProfilePic(Uint8List image) async {
    String res = "Some error Occurred";
    try {
      String photoUrl = await StorageMethods()
          .uploadImageToStorage('profilePics', image, true);

      User currentUser = _auth.currentUser!;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'photoUrl': photoUrl,
      });

      res = "success";
    } catch (err) {
      return err.toString();
    }
    return res;
  }
}
