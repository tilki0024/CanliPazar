# iOS Launch Error - Sorun Giderme Rehberi

## "Error launching application on Ahmet iPhone'u (wireless)" Hatası

Bu hata genellikle şu nedenlerden kaynaklanır:

### 1. Code Signing Sorunları

**Kontrol:**
- Xcode → Runner target → Signing & Capabilities
- **Team**: 9W44LA8URS seçili olmalı
- **Bundle Identifier**: `com.canlipazar.app` olmalı
- **Provisioning Profile**: Otomatik veya geçerli bir profile seçili olmalı

**Çözüm:**
1. Xcode'u açın: `open ios/Runner.xcworkspace`
2. Runner target'ı seçin
3. Signing & Capabilities sekmesine gidin
4. "Automatically manage signing" işaretli olmalı
5. Team'i seçin (9W44LA8URS)
6. Eğer hata varsa, "Fix Issue" butonuna tıklayın

### 2. Provisioning Profile Sorunları

**Kontrol:**
- Apple Developer hesabınızda cihaz kayıtlı mı?
- Provisioning profile geçerli mi?

**Çözüm:**
1. Apple Developer Portal → Devices → Cihazınızın kayıtlı olduğundan emin olun
2. Xcode → Preferences → Accounts → Apple ID'nizi ekleyin
3. "Download Manual Profiles" butonuna tıklayın

### 3. Bundle ID Uyuşmazlığı

**Kontrol:**
- Xcode'da Bundle ID: `com.canlipazar.app`
- Firebase Console'da Bundle ID: `com.canlipazar.app`
- Apple Developer Portal'da Bundle ID: `com.canlipazar.app`

**Hepsi aynı olmalı!**

### 4. Cihaz Bağlantı Sorunları (Wireless)

**Kontrol:**
- Cihaz ve Mac aynı WiFi ağında mı?
- Cihazda "Connect via Network" açık mı?

**Çözüm:**
1. Cihazı USB ile bağlayın (daha güvenilir)
2. Veya Xcode → Window → Devices and Simulators → Cihazınızı seçin → "Connect via Network" işaretini kaldırıp tekrar açın

### 5. Xcode Build Ayarları

**Kontrol:**
- Xcode → Product → Scheme → Runner seçili mi?
- Build Configuration: Debug/Release doğru mu?

**Çözüm:**
1. Xcode'da Product → Clean Build Folder (Shift+Cmd+K)
2. Product → Build (Cmd+B)
3. Hata varsa, hata mesajını kontrol edin

### 6. Pod Dependencies Sorunları

**Kontrol:**
- Pod install başarılı mı?

**Çözüm:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### 7. Flutter Build Sorunları

**Kontrol:**
- Flutter dependencies güncel mi?

**Çözüm:**
```bash
flutter clean
flutter pub get
cd ios
pod install
```

### 8. Detaylı Hata Mesajı Alma

**Xcode'dan:**
1. Xcode'u açın: `open ios/Runner.xcworkspace`
2. Product → Run (Cmd+R)
3. Xcode Console'da (Alt+Cmd+C) hata mesajını görün

**Terminal'den:**
```bash
flutter run -v
```
`-v` flag'i detaylı log gösterir

### 9. Yaygın Hata Mesajları ve Çözümleri

#### "No signing certificate found"
**Çözüm:** Xcode → Preferences → Accounts → Apple ID → "Download Manual Profiles"

#### "Provisioning profile doesn't match"
**Çözüm:** Xcode → Runner → Signing & Capabilities → "Automatically manage signing" işaretleyin

#### "Device not registered"
**Çözüm:** Apple Developer Portal → Devices → Cihazınızı ekleyin

#### "Bundle identifier is already in use"
**Çözüm:** Farklı bir Bundle ID kullanın veya mevcut uygulamayı silin

### 10. Manuel Build ve Install

**Xcode'dan:**
1. Xcode'u açın: `open ios/Runner.xcworkspace`
2. Cihazınızı seçin (üstteki device selector'dan)
3. Product → Run (Cmd+R)
4. Hata mesajını Xcode Console'da görün

**Terminal'den:**
```bash
flutter build ios --debug
# Sonra Xcode'dan açıp run edin
```

## Hızlı Çözüm Adımları

1. **Xcode'u açın:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Signing'i kontrol edin:**
   - Runner target → Signing & Capabilities
   - Team: 9W44LA8URS
   - Bundle ID: com.canlipazar.app
   - "Automatically manage signing" işaretli

3. **Clean ve Build:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)

4. **Cihazı seçin ve Run:**
   - Üstteki device selector'dan cihazınızı seçin
   - Product → Run (Cmd+R)

5. **Hata mesajını kontrol edin:**
   - Xcode Console'da (Alt+Cmd+C) hata mesajını görün
   - Hata mesajını paylaşın, daha spesifik çözüm önerebilirim

## İletişim

Eğer hata devam ederse, Xcode Console'daki tam hata mesajını paylaşın. Bu sayede daha spesifik bir çözüm önerebilirim.





