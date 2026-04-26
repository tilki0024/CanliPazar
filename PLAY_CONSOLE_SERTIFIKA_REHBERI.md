# Play Console Sertifika İndirme Rehberi

## 🔐 İki Tür Sertifika Var:

### 1. **App Signing Key Certificate** (İmzalama Anahtarı Sertifikası)
- **Ne işe yarar:** Sadece public key (certificate)
- **Private key içerir mi:** ❌ HAYIR
- **AAB imzalamak için kullanılabilir mi:** ❌ HAYIR
- **Ne için kullanılır:** Sadece görüntüleme/doğrulama için

### 2. **Upload Key Certificate** (Yükleme Anahtarı Sertifikası)
- **Ne işe yarar:** Sadece public key (certificate)
- **Private key içerir mi:** ❌ HAYIR
- **AAB imzalamak için kullanılabilir mi:** ❌ HAYIR
- **Ne için kullanılır:** Play Console'a yüklemek için

## ⚠️ ÖNEMLİ:

**Play Console'dan indirebileceğiniz sertifikalar SADECE PUBLIC KEY içerir!**

Private key'i Play Console'dan indiremezsiniz. Private key sadece keystore dosyasında (.jks) bulunur.

## 💡 ÇÖZÜM:

### Senaryo 1: Bu SHA-1'e sahip keystore'unuz varsa
- Keystore dosyasının tam yolunu paylaşın
- Ben AAB'yi imzalarım

### Senaryo 2: Keystore'u kaybettiyseniz
1. Play Console → Setup → App signing
2. "Reset upload key" yapın
3. Yeni bir keystore oluşturun
4. Certificate'ini Play Console'a yükleyin
5. Yeni keystore ile AAB'yi imzalayın

## 📋 Şu Anki Durum:

- ✅ AAB dosyası hazır (yeni keystore ile imzalandı)
- ⚠️ SHA-1 eşleşmiyor (yeni keystore'un SHA-1'i farklı)
- 💡 Çözüm: Play Console'a yeni certificate'i yükleyin
















