# Bildirim İzni Nasıl Verilir?

## 📱 Bildirim İzni Nasıl Çalışır?

### 1. Otomatik İzin İsteği
**Bildirim izni Firebase'den değil, iOS sisteminden istenir.** Kod zaten hazır ve uygulama açıldığında otomatik olarak izin isteği gösterilir.

### 2. İzin İsteği Ne Zaman Gösterilir?

Uygulama ilk açıldığında otomatik olarak şu sırayla izin istenir:

1. **AppDelegate.swift** - `requestPushAuthorization()` fonksiyonu çağrılır
2. **main.dart** - `requestNotificationPermissions()` fonksiyonu çağrılır
3. **FCMTokenService** - Token alınmadan önce izin kontrol edilir

### 3. İzin İsteği Ekranı

iOS otomatik olarak şu ekranı gösterir:
```
"CanlıPazar" Bildirimler Göndermek İstiyor
Bildirimler size önemli güncellemeler hakkında bilgi verebilir.

[İzin Verme] [İzin Verme]
```

### 4. İzin Durumları

- ✅ **İzin Verildi** → Bildirimler çalışır
- ❌ **İzin Reddedildi** → Bildirimler çalışmaz, manuel olarak açılmalı

## 🔧 Manuel İzin Verme (Eğer Reddedildiyse)

### iOS Ayarlar'dan İzin Verme

1. **iOS Ayarlar** uygulamasını açın
2. **Bildirimler** bölümüne gidin
3. **CanlıPazar** uygulamasını bulun
4. **Bildirimleri Açın** (toggle'ı açın)
5. İstediğiniz bildirim seçeneklerini işaretleyin:
   - ✅ Bildirimleri İzin Ver
   - ✅ Sesler
   - ✅ Rozetler
   - ✅ Ekranın Üstünde Göster

### Uygulama İçinden İzin Kontrolü

Eğer izin reddedildiyse, uygulama içinde tekrar istenebilir:

1. Uygulamayı açın
2. Bildirim izni isteği tekrar gösterilir
3. Veya iOS Ayarlar'dan manuel olarak açın

## 🔍 İzin Durumunu Kontrol Etme

### Xcode Console'da Kontrol

Uygulamayı çalıştırdığınızda Xcode Console'da şu mesajları göreceksiniz:

**İzin Verildi:**
```
✅ iOS AppDelegate: Bildirim izni verildi
✅ FCM Token Service: Bildirim izni verildi (authorized)
```

**İzin Reddedildi:**
```
❌ iOS AppDelegate: Bildirim izni reddedildi
❌ FCM Token Service: Bildirim izni reddedildi (denied)
```

### Kod İçinde Kontrol

```dart
// main.dart içinde
NotificationSettings settings = await messaging.requestPermission(...);
print('User granted permission: ${settings.authorizationStatus}');
// authorized, denied, notDetermined, provisional
```

## 🚨 Sorun Giderme

### İzin İsteği Gösterilmiyor

**Neden:**
- İzin daha önce reddedilmiş ve "Bir Daha Sorma" seçilmiş
- Uygulama daha önce açılmış ve izin durumu belirlenmiş

**Çözüm:**
1. iOS Ayarlar > Bildirimler > CanlıPazar
2. Bildirimleri açın
3. Veya uygulamayı silip yeniden yükleyin

### İzin Verildi Ama Bildirimler Çalışmıyor

**Kontrol Listesi:**
1. ✅ Bildirim izni verildi mi? (iOS Ayarlar'dan kontrol edin)
2. ✅ Token Firestore'a kaydedildi mi?
3. ✅ Cloud Functions deploy edildi mi?
4. ✅ APNs sertifikası Firebase Console'da yüklü mü?
5. ✅ Capability'ler Xcode'da eklendi mi?

## 📋 İzin İsteği Kodları

### AppDelegate.swift
```swift
func requestPushAuthorization() {
  UNUserNotificationCenter.current().requestAuthorization(
    options: [.alert, .badge, .sound]
  ) { granted, error in
    if granted {
      print("✅ Bildirim izni verildi")
    } else {
      print("❌ Bildirim izni reddedildi")
    }
  }
}
```

### main.dart
```dart
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  print('User granted permission: ${settings.authorizationStatus}');
}
```

### FCMTokenService
```dart
NotificationSettings settings = await _messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

## ✅ Özet

1. **Bildirim izni Firebase'den değil, iOS sisteminden istenir**
2. **Uygulama açıldığında otomatik olarak izin isteği gösterilir**
3. **Kod zaten hazır** - hiçbir şey yapmanıza gerek yok
4. **İzin reddedilirse** iOS Ayarlar'dan manuel olarak açılabilir
5. **İzin durumunu** Xcode Console'da kontrol edebilirsiniz

## 🧪 Test

1. Uygulamayı temiz bir şekilde çalıştırın (ilk kez açılıyormuş gibi)
2. Bildirim izni isteği otomatik olarak gösterilmeli
3. "İzin Ver" butonuna tıklayın
4. Xcode Console'da "✅ Bildirim izni verildi" mesajını kontrol edin








