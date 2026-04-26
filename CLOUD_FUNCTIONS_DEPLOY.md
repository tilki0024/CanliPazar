# Cloud Functions Deploy Rehberi

## 🚀 Bildirim Başlığını Güncellemek İçin

### Adım 1: Terminal'i Açın
Terminal uygulamasını açın (Cmd+Space → "Terminal" yazın)

### Adım 2: Functions Klasörüne Gidin
```bash
cd ~/Desktop/CanliPazar-main/functions
```

### Adım 3: Bağımlılıkları Yükleyin
```bash
npm install
```

**Eğer izin hatası alırsanız:**
```bash
sudo chown -R $(whoami) ~/.npm
npm install
```

### Adım 4: TypeScript'i Derleyin
```bash
npm run build
```

### Adım 5: Cloud Functions'ı Deploy Edin
```bash
firebase deploy --only functions:onMessageCreated
```

## ✅ Başarılı Deploy Sonrası

- Bildirim başlığı "CanlıPazardan bir mesajınız var" olarak güncellenecek
- Uygulama kapalı olsa bile bildirimler gelecek
- Mesaj silme özelliği zaten çalışıyor (deploy gerekmez)

## 🔍 Kontrol

Deploy sonrası Firebase Console'dan logları kontrol edebilirsiniz:
- Firebase Console → Functions → Logs

## ⚠️ Notlar

- Deploy işlemi 2-5 dakika sürebilir
- İlk deploy daha uzun sürebilir
- Firebase CLI'nin yüklü olması gerekir: `npm install -g firebase-tools`
- Firebase'e login olmanız gerekir: `firebase login`














