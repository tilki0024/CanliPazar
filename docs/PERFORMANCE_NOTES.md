# CanlıPazar — Performans ve yayın notları

## Release derlemesi
- **Android:** `flutter build apk --release` veya `flutter build appbundle --release`
- **iOS:** `flutter build ipa --release` veya Xcode **Archive**
- Debug modundaki jank ve düşük FPS genelde **profil çıkarmak için yanıltıcıdır**; gerçek cihazda mutlaka release ile test edin.

## Ana sayfa liste
- İlanlar **SliverGrid / SliverList** ile tembel (lazy) oluşturulur; tüm kartlar tek seferde çizilmez.

## Firestore indeksleri
- `firestore.indexes.json` güncellendiyse: `firebase deploy --only firestore:indexes`
- Konsolda index linki çıkarsa ilgili bileşik indeksi oluşturun.
