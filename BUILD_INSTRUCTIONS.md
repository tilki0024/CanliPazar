# 🚀 CanlıPazar Android Release Build Talimatları

## 📋 Gerekli Ön Adımlar

### 1. Keystore Oluşturma (İlk Defa)

Eğer daha önce bir keystore dosyanız yoksa, şu komutu çalıştırın:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Bu komut size şunları soracak:
- **Password**: Güvenli bir şifre seçin (key.properties dosyasına eklenecek)
- **Name**: Adınız
- **Organizational Unit**: Departmanınız
- **Organization**: Şirket adı
- **City**: Şehir
- **State**: İl
- **Country**: TR (Türkiye için)

### 2. Keystore Dosyasını Kopyalama

Oluşturduğunuz keystore dosyasını `android/` klasörüne kopyalayın:

```bash
cp ~/upload-keystore.jks android/upload-keystore.jks
```

### 3. key.properties Dosyasını Güncelleme

`android/key.properties` dosyasını düzenleyin ve kendi bilgilerinizi girin:

```properties
storePassword=SİZİN_KEYSTORE_ŞİFRENİZ
keyPassword=SİZİN_KEY_ŞİFRENİZ
keyAlias=upload
storeFile=upload-keystore.jks
```

⚠️ **ÖNEMLİ:** 
- Bu dosya hassas bilgiler içerir, **ASLA** Git'e commit etmeyin
- `.gitignore` dosyasına `android/key.properties` ve `android/upload-keystore.jks` ekleyin

## 🔧 Release Build Oluşturma

### Seçenek 1: APK Oluşturma (Test için)

```bash
flutter build apk --release
```

Oluşturulan APK: `build/app/outputs/flutter-apk/app-release.apk`

### Seçenek 2: AAB Oluşturma (Play Store için - ÖNERİLEN)

```bash
flutter build appbundle --release
```

Oluşturulan AAB: `build/app/outputs/bundle/release/app-release.aab`

## 📱 Google Play Console'a Yükleme

1. **Google Play Console'a giriş yapın**: https://play.google.com/console
2. **CanlıPazar** uygulamanızı seçin
3. **Production** > **Create new release** tıklayın
4. **Upload** bölümünden AAB dosyanızı yükleyin (`app-release.aab`)
5. **Release notes** kısmına notlarınızı ekleyin
6. **Review** tıklayın ve gönderin

## ⚙️ Versiyon Bilgileri

Mevcut versiyon: **1.6.0+17**
- **Version Name**: 1.6.0
- **Version Code**: 17

Versiyon yükseltmek için `pubspec.yaml` dosyasını düzenleyin:

```yaml
version: 1.7.0+18  # Yeni versiyon + artırılmış build number
```

## 📊 Build Optimizasyonları

Mevcut build.gradle yapılandırması:
- ✅ ProGuard/R8 devre dışı (daha hızlı build)
- ✅ MultiDex aktif
- ✅ Min SDK: 23 (Android 6.0+)
- ✅ Target SDK: 35 (Android 15)
- ✅ Kotlin 2.2.0
- ✅ Firebase entegrasyonu

## 🔒 Güvenlik Notları

1. **key.properties** dosyası `.gitignore` içinde olmalı
2. **upload-keystore.jks** dosyası **ASLA** Git'e commit edilmemeli
3. Keystore şifrelerinizi güvenli bir yerde saklayın
4. Keystore dosyasını düzenli olarak yedekleyin

## 🐛 Sorun Giderme

### Keystore bulunamıyor hatası:

```bash
# Keystore dosyasının konumunu kontrol edin
ls -la android/upload-keystore.jks

# Eğer yoksa, keystore'u yeniden oluşturun (yukarıdaki talimatlara bakın)
```

### key.properties dosyası okunamıyor:

```bash
# Dosyanın android/ klasöründe olduğundan emin olun
ls -la android/key.properties

# İzinleri kontrol edin
chmod 600 android/key.properties
```

### Build hatası:

```bash
# Flutter clean yapın
flutter clean

# Dependencies'leri yeniden yükleyin
flutter pub get

# Tekrar build yapın
flutter build appbundle --release
```

## 📈 Performans

Release build özellikleri:
- Optimized resource shrinking
- Code obfuscation disabled
- Native debug symbols excluded
- APK size: ~25-30 MB (tahmini)

## ✅ Build Öncesi Kontrol Listesi

- [ ] Versiyon numarası güncellendi mi? (`pubspec.yaml`)
- [ ] key.properties dosyası dolu mu ve doğru mu?
- [ ] upload-keystore.jks dosyası mevcut mu?
- [ ] Firebase yapılandırması güncel mi? (`google-services.json`)
- [ ] Test build başarılı mı?
- [ ] Release notları hazırlandı mı?

## 🎯 Sonraki Adımlar

1. Build oluşturun
2. Local olarak test edin
3. Google Play Console'a yükleyin
4. Internal/Closed/Open Testing'de test edin
5. Production'a çıkın

---

**Not**: İlk kez keystore oluşturuyorsanız, komutu Mac/Windows/Linux terminalinde çalıştırmanız gerekiyor. Keystore şifrelerinizi unutmayın, kaybederseniz Play Store güncellemeleri yapamazsınız!


















