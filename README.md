# Sürü Gardaş

Android telefona APK olarak kurulabilecek, internetsiz çalışan küçükbaş çiftlik yönetim uygulaması.

## Özellikler

- Hayvan kartları, hızlı küpe arama ve arşiv durumu
- Kuzulama/doğum, otomatik kuzu oluşturma ve anne-kuzu bağlantısı
- Çiftleşme/gebelik takibi ve tahmini doğum tarihi
- Sağlık, aşı, ilaç, tedavi ve sonraki kontrol hatırlatmaları
- Yem alımı, stok ve günlük tüketim takibi
- Gelir-gider, alım-satım ve otomatik para kayıtları
- Padok/ağıl takibi
- Rapor ekranları
- SQLite yerel veritabanı

## Çalıştırma

```bash
cd suru_gardas_flutter
flutter pub get
flutter run
```

## APK Alma

```bash
cd suru_gardas_flutter
flutter pub get
flutter build apk --release
```

APK çıktı yolu:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Android platform dosyalarını yenilemek gerekirse:

```bash
flutter create --platforms=android .
flutter pub get
flutter build apk --release
```

## Gelecek Geliştirme İçin Hazır Alanlar

`lib/data/app_database.dart` veritabanı şemasını tek yerde tutar. Excel/PDF/yedek alma için yeni servisler `lib/data` altına eklenebilir.
