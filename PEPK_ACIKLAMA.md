# PEPK Aracı Açıklaması

## 🔐 PEPK Nedir?

PEPK (Play Encrypt Private Key), Google'ın "App signing by Google Play" özelliğini kullanırken, upload key'inizi Google'a güvenli bir şekilde aktarmak için kullanılan bir araçtır.

## 📋 Komut Açıklaması

```bash
java -jar pepk.jar \
  --keystore=foo.keystore \           # Şifrelenecek keystore dosyası
  --alias=foo \                        # Keystore'daki alias adı
  --output=output.zip \                # Şifrelenmiş çıktı dosyası
  --signing-keystore=uploadkey.keystore \  # İmzalama keystore'u
  --signing-key-alias=upload-key-alias \    # İmzalama alias'ı
  --rsa-aes-encryption \               # RSA-AES şifreleme kullan
  --encryption-key-path=/path/to/encryption_public_key.pem  # Şifreleme public key'i
```

## 🤔 Bizim Durumumuz

**Bizim durumumuzda PEPK aracına ihtiyacımız YOK çünkü:**

1. ✅ **Sadece certificate yüklüyoruz** (`upload_certificate_reset.pem`)
2. ✅ **Private key'i Google'a göndermiyoruz**
3. ✅ **Upload key'i kendimiz yönetiyoruz**

## 📤 Bizim Yapmamız Gerekenler

### Yöntem 1: Sadece Certificate Yükleme (Önerilen - Bizim Yöntemimiz)

1. Play Console → Setup → App signing
2. Upload key certificate bölümüne git
3. `upload_certificate_reset.pem` dosyasını yükle
4. AAB dosyasını yükle

**Avantajları:**
- ✅ Private key sizde kalır
- ✅ Daha güvenli
- ✅ Key'i istediğiniz zaman değiştirebilirsiniz

### Yöntem 2: PEPK ile Key'i Google'a Aktarma

Eğer "App signing by Google Play" kullanmak isterseniz:

1. PEPK aracını indirin (Google Play Console'dan)
2. Encryption public key'i indirin
3. Komutu çalıştırın:
   ```bash
   java -jar pepk.jar \
     --keystore=upload-keystore-reset.jks \
     --alias=upload \
     --output=encrypted_key.zip \
     --encryption-key-path=encryption_public_key.pem
   ```
4. `encrypted_key.zip` dosyasını Play Console'a yükleyin

**Avantajları:**
- ✅ Google key'i yönetir
- ✅ Key kaybı riski yok
- ❌ Key'i geri alamazsınız

## 🎯 Önerimiz

**Bizim durumumuzda Yöntem 1'i kullanıyoruz** çünkü:
- Daha basit
- Daha güvenli (key sizde)
- Key'i istediğiniz zaman değiştirebilirsiniz

## 📝 Özet

- **PEPK:** Google'a key aktarmak için (bizim durumumuzda gerekli değil)
- **Certificate yükleme:** Sadece public key'i yüklemek (bizim yöntemimiz)

Biz sadece certificate yüklüyoruz, bu yüzden PEPK aracına ihtiyacımız yok! ✅
















