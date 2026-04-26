# iOS Push Notification Yapılandırma Adımları

## Tamamlanan Adımlar

1. ✅ `ios/Runner/Runner.entitlements` dosyası oluşturuldu ve `aps-environment` production olarak ayarlandı
2. ✅ AppDelegate.swift'te Firebase Messaging ve UNUserNotificationCenter delegate'leri ayarlandı
3. ✅ Foreground notification handling kodları eklendi

## Xcode'da Yapılması Gereken Adımlar

### 1. Entitlements Dosyasını Projeye Ekleme

1. Xcode'u açın: `open ios/Runner.xcworkspace`
2. Sol panelde `Runner` projesini seçin
3. `Runner` klasörüne sağ tıklayın → "Add Files to Runner..."
4. `ios/Runner/Runner.entitlements` dosyasını seçin
5. "Copy items if needed" seçeneğini işaretleyin
6. "Add" butonuna tıklayın

### 2. Build Settings'te Entitlements Ayarlama

1. Xcode'da `Runner` target'ını seçin
2. "Signing & Capabilities" sekmesine gidin
3. "+ Capability" butonuna tıklayın
4. "Push Notifications" ekleyin
5. "Background Modes" ekleyin ve "Remote notifications" seçeneğini işaretleyin

### 3. Code Signing Entitlements Ayarlama

1. "Build Settings" sekmesine gidin
2. "Code Signing Entitlements" araması yapın
3. Debug ve Release için `Runner/Runner.entitlements` değerini girin

### 4. Firebase Console'da APNs Ayarları

1. Firebase Console → Project Settings → Cloud Messaging
2. APNs Authentication Key bölümünde:
   - Key ID: `94D623ABF4`
   - Team ID: `9W44LABURS`
   - Key dosyasını yükleyin (AuthKey_94D623ABF4.p8)

## Test Etme

1. Uygulamayı iOS cihazda çalıştırın
2. Bildirim izni verin
3. Başka bir cihazdan mesaj gönderin
4. Foreground ve background'da bildirimlerin geldiğini kontrol edin

## Sorun Giderme

- Eğer bildirimler gelmiyorsa, Firebase Console'da APNs sertifikasının doğru yüklendiğini kontrol edin
- Xcode'da "Product" → "Clean Build Folder" yapın
- `flutter clean` ve `pod install` komutlarını çalıştırın





