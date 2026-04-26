import UIKit
import Flutter
import Firebase
import FirebaseAnalytics
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // MARK: - Application Lifecycle
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 AppDelegate: Uygulama başlatılıyor...")
    
    // KRİTİK 1: Flutter plugins'i ÖNCE kaydet (Firebase'den önce)
    // Flutter engine'in hazır olması için gerekli
    GeneratedPluginRegistrant.register(with: self)
    print("✅ AppDelegate: Flutter plugins kaydedildi")
    
    // KRİTİK 2: Firebase'i yapılandır (iOS bildirimleri için MUTLAKA gerekli)
    // Firebase zaten initialize edilmişse tekrar initialize etme (crash önleme)
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("✅ AppDelegate: Firebase yapılandırıldı")
    } else {
      print("✅ AppDelegate: Firebase zaten yapılandırılmış")
    }
    
    // KRİTİK 3: Firestore settings KALDIRILDI
    // 
    // SORUN: Firestore.firestore() çağrısı instance'ı başlatır
    // Eğer Flutter tarafında FirebaseFirestore.instance daha önce kullanılmışsa,
    // instance zaten başlatılmış olur ve settings ayarlanamaz → CRASH
    // 
    // ÇÖZÜM: iOS'ta Firestore settings'i AppDelegate'te ayarlamayı TAMAMEN KALDIRIYORUZ
    // iOS Firestore SDK default settings kullanacak (persistence enabled, unlimited cache)
    // Flutter tarafında da settings ayarlanmıyor (main.dart'ta)
    // 
    // NOT: iOS Firestore SDK default olarak persistence enabled ve unlimited cache kullanır
    // Bu yüzden manuel settings ayarlamaya gerek yok
    print("✅ AppDelegate: Firestore settings iOS default ayarları kullanılacak (manuel ayarlama kaldırıldı)")
    
    // KRİTİK 2.1: Firebase Analytics collection'ı etkinleştir
    // Bu, Firebase Console'da platform bilgisinin doğru görünmesi için GEREKLİ
    Analytics.setAnalyticsCollectionEnabled(true)
    print("✅ AppDelegate: Firebase Analytics collection enabled")
    
    // KRİTİK 2.2: iOS platform bilgisini Analytics'e gönder
    // Bu, Firebase Console → Users bölümünde platform'un "ios" olarak görünmesi için GEREKLİ
    Analytics.setUserProperty("ios", forName: "platform")
    print("✅ AppDelegate: Firebase Analytics platform user property ayarlandı: ios")
    
    // KRİTİK 4: Firebase Messaging delegate'i ayarla (APNs token almak için gerekli)
    // Bu delegate FCM token'ı almak için MUTLAKA gerekli
    Messaging.messaging().delegate = self
    print("✅ AppDelegate: Firebase Messaging delegate ayarlandı")
    
    // KRİTİK 5: UNUserNotificationCenter delegate'i ayarla (iOS 10+ için gerekli)
    // Bu delegate foreground/background notification handling için gerekli
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("✅ AppDelegate: UNUserNotificationCenter delegate ayarlandı")
    }
    
    // KRİTİK 6: Notification permission request (iOS 10+ için)
    // Permission request'i Flutter engine hazır olduktan sonra yap
    // Bu gecikme Flutter engine'in tam olarak hazır olması için gerekli
    if #available(iOS 10.0, *) {
      // Flutter engine hazır olana kadar bekle (0.5 saniye - daha hızlı)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { granted, error in
            if granted {
              print("✅ [AppDelegate] iOS Bildirim izni verildi")
              DispatchQueue.main.async {
                print("📱 [AppDelegate] Remote notifications kaydediliyor...")
                application.registerForRemoteNotifications()
              }
            } else {
              print("iOS Bildirim izni reddedildi")
            }
          }
        )
      }
    } else {
      // For iOS 9 and below (legacy support)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
      }
    }
    
    // StoreKit method channel setup (window hazır olduktan sonra)
    DispatchQueue.main.async {
      guard let window = self.window,
            let controller = window.rootViewController as? FlutterViewController else {
        print("⚠️ iOS AppDelegate: Window veya FlutterViewController hazır değil, method channel kurulamadı")
        return
      }
      
      let storeReviewChannel = FlutterMethodChannel(
        name: "com.freecycle/storeReview",
        binaryMessenger: controller.binaryMessenger
      )
      
      // Handle method calls from Flutter
      storeReviewChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "requestReview" {
          if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
            result(nil)
          } else {
            // Fallback for older iOS versions
            let appStoreURL = URL(string: "https://apps.apple.com/us/app/free-stuff-freecycle/id6476391295?action=write-review")!
            if UIApplication.shared.canOpenURL(appStoreURL) {
              UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
            result(nil)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
      
      // KRİTİK: FCM Token MethodChannel (iOS UserDefaults'tan token almak için)
      let fcmTokenChannel = FlutterMethodChannel(
        name: "com.canlipazar/fcm_token",
        binaryMessenger: controller.binaryMessenger
      )
      
      fcmTokenChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "getPendingToken" {
          // UserDefaults'tan token'ı al
          let token = UserDefaults.standard.string(forKey: "fcmToken_pending")
          result(token)
        } else if call.method == "removePendingToken" {
          // UserDefaults'tan token'ı sil
          UserDefaults.standard.removeObject(forKey: "fcmToken_pending")
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
    
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    print("✅ AppDelegate: Super application çağrıldı, result: \(result)")
    
    return result
  }
  
  // MARK: - App State Management
  
  // KRİTİK 7: App açıldığında badge'i sıfırla (kullanıcı deneyimi için önemli)
  // Kullanıcı uygulamayı açtığında notification badge'i sıfırlanmalı
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // Badge'i sıfırla
    UIApplication.shared.applicationIconBadgeNumber = 0
    print("✅ AppDelegate: Notification badge sıfırlandı")
  }
  
  // MARK: - Remote Notification Registration
  
  // KRİTİK 8: APNs token alındığında FCM'e ver (iOS bildirimleri için MUTLAKA gerekli)
  // Bu method iOS'tan APNs token'ı alır ve Firebase Messaging'e verir
  // Firebase Messaging bu token'ı kullanarak FCM token üretir
  // 
  // iOS Push Bildirimleri için KRİTİK Sıra:
  // 1. Bildirim izni verilmeli (UNUserNotificationCenter)
  // 2. APNs token alınmalı (bu method)
  // 3. APNs token Firebase Messaging'e verilmeli
  // 4. FCM token alınmalı (didReceiveRegistrationToken)
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 [AppDelegate] ========== APNs TOKEN ALINDI ==========")
    print("📱 [AppDelegate] APNs device token: \(tokenString.prefix(20))...")
    print("📱 [AppDelegate] APNs token uzunluğu: \(deviceToken.count) bytes")
    print("📱 [AppDelegate] APNs token tam: \(tokenString)")
    
    // KRİTİK: APNs token'ı Firebase Messaging'e ver
    // Bu olmadan FCM token alınamaz!
    Messaging.messaging().apnsToken = deviceToken
    print("✅ [AppDelegate] APNs token Firebase Messaging'e verildi")
    print("📱 [AppDelegate] FCM token üretimi başlatılıyor...")
    
    // KRİTİK: FCM token'ı hemen kontrol et (hemen almayı dene)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      print("⏳ [AppDelegate] FCM token hemen kontrol ediliyor...")
      self.getAndSaveFCMToken()
    }
    
    // KRİTİK: FCM token'ı almak için APNs token'ın FCM tarafından işlenmesi gerekiyor
    // didReceiveRegistrationToken callback'i otomatik çağrılacak
    // Eğer callback çağrılmazsa, 3 saniye sonra tekrar manuel al
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
      // didReceiveRegistrationToken çağrılmadıysa manuel al
      print("⏳ [AppDelegate] FCM token tekrar kontrol ediliyor (didReceiveRegistrationToken çağrılmadıysa manuel alınacak)...")
      self.getAndSaveFCMToken(retryCount: 1)
    }
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    print("📱 [AppDelegate] ======================================")
  }
  
  // KRİTİK 9: Remote notification registration hatası (error handling)
  // Bu method registration başarısız olduğunda çağrılır
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Remote notification registration hatası: \(error.localizedDescription)")
    
    // Hata detaylarını logla
    if let nsError = error as NSError? {
      print("❌ Error domain: \(nsError.domain)")
      print("❌ Error code: \(nsError.code)")
      print("❌ Error userInfo: \(nsError.userInfo)")
    }
    
    // Retry mekanizması (5 saniye sonra tekrar dene)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      print("🔄 Remote notification registration tekrar deneniyor...")
      application.registerForRemoteNotifications()
    }
    
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // MARK: - Silent Push Notification Handling
  
  // KRİTİK 10: Silent push notification handling (background data sync için gerekli)
  // Bu method silent push notification'ları handle eder
  // Background'da data sync yapmak için kullanılır
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📱 Silent push notification alındı: \(userInfo)")
    
    // Firebase Messaging'e bildir
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Background fetch sonucunu bildir
    completionHandler(.newData)
  }
  
  // MARK: - Foreground Notification Handling
  
  // KRİTİK 11: Foreground notification handling (iOS 10+ için gerekli)
  // Bu method uygulama açıkken notification geldiğinde çağrılır
  // 
  // ÖNEMLİ: ÇİFT BİLDİRİM SORUNU ÇÖZÜMÜ
  // Flutter tarafında (main.dart) FirebaseMessaging.onMessage.listen ile
  // foreground notification'lar zaten dinleniyor ve local notification gösteriliyor.
  // Burada bildirim gösterirsek ÇİFT BİLDİRİM olur!
  // 
  // ÇÖZÜM: Burada bildirim gösterme, sadece Firebase Messaging'e bildir
  // Flutter tarafı bildirim gösterecek (main.dart -> _handleForegroundMessage)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    
    print("📱 [AppDelegate] Foreground notification alındı: \(userInfo)")
    
    // KRİTİK: Firebase Messaging'e bildir (analytics için)
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // KRİTİK: ÇİFT BİLDİRİM SORUNU ÇÖZÜMÜ
    // Bildirim gösterme! Flutter tarafı gösterecek (main.dart -> FirebaseMessaging.onMessage.listen)
    // Boş array vererek bildirimin iOS tarafından gösterilmesini engelliyoruz
    // Bu sayede sadece Flutter tarafında gösterilir ve çift bildirim önlenir
    completionHandler([])
    
    print("✅ [AppDelegate] Foreground notification Firebase'e bildirildi")
    print("✅ [AppDelegate] Bildirim gösterimi Flutter tarafına bırakıldı (çift bildirim önlendi)")
  }
  
  // MARK: - Notification Tap Handling
  
  // KRİTİK 12: Notification'a tıklandığında (iOS 10+ için gerekli)
  // Bu method kullanıcı notification'a tıkladığında çağrılır
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    print("📱 Notification'a tıklandı: \(userInfo)")
    
    // Firebase Messaging'e bildir (analytics için)
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    completionHandler()
  }
  
  // MARK: - Universal Links Handling
  
  /// KRİTİK: Universal Links - Uygulama açıkken veya kapalıyken link'ten açıldığında
  /// iOS 9+ için gerekli
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    print("🔗 [AppDelegate] Universal Link alındı")
    
    // Universal Link kontrolü
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      guard let url = userActivity.webpageURL else {
        print("❌ [AppDelegate] Universal Link URL bulunamadı")
        return false
      }
      
      print("🔗 [AppDelegate] Universal Link URL: \(url)")
      
      // Flutter tarafına bildir
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.canlipazar/universal_link",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("handleUniversalLink", arguments: url.absoluteString)
        print("✅ [AppDelegate] Universal Link Flutter'a gönderildi")
      }
      
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  /// KRİTİK: Custom URL Scheme - canlipazar://ilan/{postId}
  /// iOS 9+ için gerekli
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("🔗 [AppDelegate] Custom URL Scheme alındı: \(url)")
    
    // Custom scheme kontrolü
    if url.scheme == "canlipazar" {
      // Flutter tarafına bildir
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.canlipazar/universal_link",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("handleUniversalLink", arguments: url.absoluteString)
        print("✅ [AppDelegate] Custom URL Scheme Flutter'a gönderildi")
      }
      
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}

// MARK: - MessagingDelegate

// KRİTİK 13: Firebase Messaging Delegate (FCM token almak için MUTLAKA gerekli)
// Bu extension FCM token'ı almak için gerekli
// didReceiveRegistrationToken method'u FCM token alındığında otomatik çağrılır
extension AppDelegate: MessagingDelegate {
  
  // KRİTİK 14: FCM token alındığında (otomatik çağrılır)
  // Bu method FCM token alındığında otomatik olarak çağrılır
  // Token'ı Firestore'a kaydetmek için kullanılır
  // 
  // iOS Push Bildirimleri için KRİTİK:
  // - Bu method APNs token Firebase Messaging'e verildikten sonra otomatik çağrılır
  // - FCM token başarıyla alındığında bu method çağrılır
  // - Platform = "ios" kesin olarak kaydedilir
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔄 [AppDelegate] ========== FCM TOKEN ALINDI ==========")
    print("🔄 [AppDelegate] didReceiveRegistrationToken çağrıldı")
    
    guard let fcmToken = fcmToken, !fcmToken.isEmpty else {
      print("❌ [AppDelegate] FCM token nil veya boş!")
      print("❌ [AppDelegate] Olası nedenler:")
      print("   - APNs token Firebase Messaging'e verilmemiş")
      print("   - Bildirim izni verilmemiş")
      print("   - Firebase yapılandırması hatalı")
      print("   - Network bağlantısı yok")
      print("❌ [AppDelegate] Manuel token alma deneniyor...")
      // Manuel token alma dene
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.getAndSaveFCMToken()
      }
      return
    }
    
    print("✅ [AppDelegate] Firebase registration token alındı: \(fcmToken.prefix(20))...")
    print("📱 [AppDelegate] Token uzunluğu: \(fcmToken.count) karakter")
    print("📱 [AppDelegate] Token tam: \(fcmToken)")
    print("📱 [AppDelegate] Platform: ios (kesin)")
    
    // KRİTİK: Token'ı NotificationCenter'a post et (Flutter tarafında dinlenebilir)
    // Flutter tarafında FCMTokenManager bu token'ı dinleyebilir
    let dataDict: [String: String] = ["token": fcmToken]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    print("✅ [AppDelegate] FCM token NotificationCenter'a post edildi")
    
    // KRİTİK: Firestore kullanımını TAMAMEN KALDIRIYORUZ
    // Token kaydı Flutter tarafından yapılacak (FCMTokenManager veya main.dart)
    // Bu, "Firestore instance has already been started" hatasını önler
    print("✅ [AppDelegate] Token Flutter tarafından Firestore'a kaydedilecek")
    print("   - Token UserDefaults'a kaydedildi: fcmToken_pending")
    print("   - Flutter tarafı (FCMTokenManager/main.dart) bu token'ı alıp Firestore'a kaydedecek")
    print("📱 [AppDelegate] ======================================")
  }
  
  // MARK: - Token Management
  
  /// FCM token'ı al ve Firestore'a kaydet (retry mekanizması ile)
  /// Bu method FCM token'ı manuel olarak alır (didReceiveRegistrationToken çağrılmadıysa)
  func getAndSaveFCMToken(retryCount: Int = 0) {
    let maxRetries = 3
    
    print("🔄 [AppDelegate] FCM token manuel olarak alınıyor (deneme \(retryCount + 1)/\(maxRetries))...")
    
    Messaging.messaging().token { [weak self] token, error in
      guard let self = self else { return }
      
      if let error = error {
        print("❌ [AppDelegate] FCM token alınamadı (deneme \(retryCount + 1)/\(maxRetries)): \(error.localizedDescription)")
        print("❌ [AppDelegate] Olası nedenler:")
        print("   - APNs token Firebase Messaging'e verilmemiş")
        print("   - Bildirim izni verilmemiş")
        print("   - Firebase yapılandırması hatalı")
        print("   - Network bağlantısı yok")
        
        // Retry mekanizması (exponential backoff)
        if retryCount < maxRetries - 1 {
          let delay = Double(retryCount + 1) * 2.0
          print("⏳ [AppDelegate] \(delay) saniye sonra tekrar deneniyor...")
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.getAndSaveFCMToken(retryCount: retryCount + 1)
          }
        } else {
          print("❌ [AppDelegate] FCM token alınamadı, maksimum deneme sayısına ulaşıldı")
        }
        return
      }
      
      guard let token = token, !token.isEmpty else {
        print("❌ [AppDelegate] FCM token nil veya boş")
        return
      }
      
      print("✅ [AppDelegate] FCM token alındı: \(token.prefix(20))...")
      print("📱 [AppDelegate] Token uzunluğu: \(token.count) karakter")
      // KRİTİK: Firestore kullanımını TAMAMEN KALDIRIYORUZ
      // Token kaydı Flutter tarafından yapılacak (FCMTokenManager veya main.dart)
      // Token'ı UserDefaults'a kaydet (Flutter tarafı alacak)
      UserDefaults.standard.set(token, forKey: "fcmToken_pending")
      print("✅ [AppDelegate] Token UserDefaults'a kaydedildi (Flutter tarafı Firestore'a kaydedecek)")
    }
  }
  
  // KRİTİK: saveTokenToFirestore metodu KALDIRILDI
  // Firestore kullanımı Flutter tarafına taşındı
  // Bu, "Firestore instance has already been started" hatasını önler
  // Token kaydı Flutter tarafından yapılacak (FCMTokenManager veya main.dart)
}
