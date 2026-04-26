# Mesaj Bildirimi Sorun Giderme Rehberi

## Mesaj Bilgileri
- **MessageId**: yYfp8ZBsjdtZmdibsUrk
- **ConversationId**: CtBc8p5lhaSgQDv3oI9jfUwMAmS2-JnrVZMJgP3gmOzjuK20y6LzBIYq2
- **RecipientId**: JnrVZMJgP3gmOzjuK20y6LzBIYq2
- **SenderId**: CtBc8p5lhaSgQDv3oI9jfUwMAmS2

## Kontrol Adımları

### 1. Cloud Function Deploy Kontrolü
```bash
cd functions
firebase functions:list
```
`onConversationMessageCreated` function'ının deploy edildiğinden emin olun.

### 2. Firestore Yapısı Kontrolü
Mesaj şu path'te olmalı:
```
conversations/CtBc8p5lhaSgQDv3oI9jfUwMAmS2-JnrVZMJgP3gmOzjuK20y6LzBIYq2/messages/yYfp8ZBsjdtZmdibsUrk
```

Firebase Console → Firestore → Bu path'i kontrol edin.

### 3. Recipient Kullanıcı Bilgileri Kontrolü
Firebase Console → Firestore → `users/JnrVZMJgP3gmOzjuK20y6LzBIYq2` dokümanını kontrol edin:

**Gerekli Alanlar:**
- `fcmToken`: Boş olmamalı, geçerli bir token olmalı
- `platform`: "ios" veya "android" olmalı (büyük/küçük harf duyarsız)
- `messageNotificationsEnabled`: true olmalı (veya undefined/null ise varsayılan true)

**Kontrol Komutu:**
```javascript
// Firebase Console → Firestore → users/JnrVZMJgP3gmOzjuK20y6LzBIYq2
// Şu alanları kontrol edin:
fcmToken: "..." (boş olmamalı)
platform: "ios" veya "android" (büyük/küçük harf duyarsız)
messageNotificationsEnabled: true (veya undefined/null)
```

### 4. Cloud Function Logs Kontrolü
Firebase Console → Functions → Logs bölümünde şu log'ları arayın:

**Function Tetiklendi mi?**
```
🔵 [DEBUG] onConversationMessageCreated TRİGGER TETİKLENDİ
📨 Yeni mesaj (alt koleksiyon): yYfp8ZBsjdtZmdibsUrk
```

**Olası Hata Mesajları:**
1. **Platform Hatası:**
```
❌ [onConversationMessageCreated] Alıcının platform bilgisi geçersiz/unknown: JnrVZMJgP3gmOzjuK20y6LzBIYq2
   - Platform: unknown (veya boş)
```
**Çözüm**: Kullanıcının platform bilgisini düzeltin veya kullanıcı uygulamayı açtığında otomatik düzelecek.

2. **Token Hatası:**
```
❌ [onConversationMessageCreated] Alıcının FCM token'ı yok veya geçersiz: JnrVZMJgP3gmOzjuK20y6LzBIYq2
```
**Çözüm**: Kullanıcının token'ını kontrol edin, geçersizse silin ve kullanıcı uygulamayı açtığında yeni token kaydedilecek.

3. **Bildirim Ayarları:**
```
⏭️ Alıcı mesaj bildirimlerini kapalı: JnrVZMJgP3gmOzjuK20y6LzBIYq2
```
**Çözüm**: Kullanıcının `messageNotificationsEnabled` alanını `true` yapın.

### 5. Function Deploy Etme
Eğer function deploy edilmemişse:
```bash
cd functions
firebase deploy --only functions:onConversationMessageCreated
```

### 6. Test Mesajı Gönderme
1. Uygulamada yeni bir mesaj gönderin
2. Firebase Console → Functions → Logs kontrol edin
3. Function'ın tetiklendiğini ve log'ları kontrol edin

## Olası Sorunlar ve Çözümleri

### Sorun 1: Function Tetiklenmiyor
**Neden**: 
- Function deploy edilmemiş
- Mesaj yanlış path'te oluşturulmuş
- Firestore trigger'ı çalışmıyor

**Çözüm**:
1. Function'ı deploy edin
2. Mesaj path'ini kontrol edin: `conversations/{conversationId}/messages/{messageId}`
3. Firebase Console → Functions → Logs'ta hata var mı kontrol edin

### Sorun 2: Platform "unknown"
**Neden**: 
- Kullanıcının platform bilgisi "unknown" veya boş

**Çözüm**:
1. Kullanıcının `platform` alanını "ios" veya "android" olarak güncelleyin
2. Veya kullanıcı uygulamayı açtığında otomatik düzelecek

### Sorun 3: Token Geçersiz
**Neden**: 
- Kullanıcının `fcmToken` alanı boş veya geçersiz

**Çözüm**:
1. Kullanıcının token'ını silin
2. Kullanıcı uygulamayı açtığında yeni token kaydedilecek

### Sorun 4: Bildirim Ayarları Kapalı
**Neden**: 
- Kullanıcının `messageNotificationsEnabled` alanı `false`

**Çözüm**:
1. Kullanıcının `messageNotificationsEnabled` alanını `true` yapın

## Debug Komutları

### Firestore'da Mesaj Kontrolü
```javascript
// Firebase Console → Firestore → Console
db.collection('conversations')
  .doc('CtBc8p5lhaSgQDv3oI9jfUwMAmS2-JnrVZMJgP3gmOzjuK20y6LzBIYq2')
  .collection('messages')
  .doc('yYfp8ZBsjdtZmdibsUrk')
  .get()
  .then(doc => console.log(doc.data()));
```

### Kullanıcı Bilgileri Kontrolü
```javascript
// Firebase Console → Firestore → Console
db.collection('users')
  .doc('JnrVZMJgP3gmOzjuK20y6LzBIYq2')
  .get()
  .then(doc => {
    const data = doc.data();
    console.log('fcmToken:', data?.fcmToken ? data.fcmToken.substring(0, 20) + '...' : 'YOK');
    console.log('platform:', data?.platform || 'YOK');
    console.log('messageNotificationsEnabled:', data?.messageNotificationsEnabled ?? true);
  });
```

## Başarılı Bildirim Log'u
Eğer bildirim başarıyla gönderildiyse şu log görülür:
```
✅ [onConversationMessageCreated] Bildirim başarıyla gönderildi: {messageId}
✅ Alıcı: JnrVZMJgP3gmOzjuK20y6LzBIYq2, Platform: ios/android
✅ Token: {token ilk 20 karakter}...
✅ MessageId: {FCM message ID}
```





