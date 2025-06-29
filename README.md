# IsubuQuiz - Flutter Quiz Application

İsparta Uygulamalı Bilimler Üniversitesi için geliştirilmiş soru-cevap uygulaması.

## 📱 Proje Hakkında

IsubuQuiz, öğrencilerin farklı derslerden testler çözebileceği, öğretmenlerin ise soru havuzları oluşturup testler düzenleyebileceği bir Flutter uygulamasıdır.

### 🌟 Özellikler

- **Öğrenci Özellikleri:**
  - Ders kataloğunu görüntüleme
  - Kayıtlı derslerdeki testleri çözme
  - Test sonuçlarını görüntüleme
  - Geçmiş test performanslarını takip etme

- **Admin/Öğretmen Özellikleri:**
  - Ders yönetimi (oluşturma, düzenleme)
  - Soru havuzu yönetimi
  - Test oluşturma ve yönetimi
  - Öğrenci sonuçlarını analiz etme
  - AI destekli soru üretimi (Gemini AI)

## 🚀 Kurulum ve Çalıştırma

### Ön Gereksinimler

1. **Flutter SDK** kurulu olmalı
   - [Flutter'ı indirin](https://docs.flutter.dev/get-started/install)
   - Flutter versiyonu: 3.0 veya üzeri

2. **Dart SDK** (Flutter ile birlikte gelir)

3. **Android Studio** veya **VS Code** (geliştirme ortamı)

4. **Git** kurulu olmalı

### 📥 Projeyi İndirme

```bash
git clone https://github.com/halilbalik/isubu-quiz.git
cd isubu-quiz
```

### 🔧 Kurulum Adımları

#### 1. Bağımlılıkları Yükleme
```bash
flutter pub get
```

#### 2. Firebase Konfigürasyonu

**Android için:**
- `android/app/google-services.json` dosyası zaten projede mevcut
- Firebase Console'da projenizi oluşturup bu dosyayı güncelleyin

**iOS için:**
- Firebase Console'dan `GoogleService-Info.plist` dosyasını indirin
- `ios/Runner/` klasörüne ekleyin

#### 3. Gemini AI API Anahtarı (ÖNEMLİ!)

⚠️ **ZORUNLU:** Proje Gemini AI kullanmaktadır ve API anahtarı olmadan çalışmaz!

**API anahtarı alma adımları:**
1. [Google AI Studio](https://makersuite.google.com/app/apikey) 'ya gidin
2. Google hesabınızla giriş yapın
3. "Create API Key" butonuna tıklayın
4. API anahtarınızı kopyalayın

**API anahtarını projeye ekleme:**
1. `lib/services/gemini_service.dart` dosyasını açın
2. 8. satırda bulunan:
   ```dart
   static const String _apiKey = 'X'; // TODO: Gerçek API key ekle
   ```
3. 'X' yerine aldığınız API anahtarını yazın:
   ```dart
   static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```
4. Dosyayı kaydedin

⚠️ **GÜVENLİK UYARISI:** API anahtarınızı GitHub'a yüklemeden önce gizleyin!

#### 4. Flutter Doctor Kontrolü
```bash
flutter doctor
```
Tüm bileşenlerin düzgün kurulu olduğundan emin olun.

### 📱 Uygulamayı Çalıştırma

#### Android Cihazda/Emülatörde
```bash
flutter run
```

#### iOS Simülatörde (macOS'ta)
```bash
flutter run -d ios
```

#### Web'de Çalıştırma
```bash
flutter run -d web
```

#### Belirli Cihazda Çalıştırma
```bash
# Mevcut cihazları listele
flutter devices

# Belirli cihazı seç
flutter run -d [device-id]
```

### 🔨 Build Alma

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS Build (macOS'ta)
```bash
flutter build ios --release
```

## 📁 Proje Yapısı

```
lib/
├── models/          # Veri modelleri
├── screens/         # Uygulama ekranları
│   ├── admin/       # Admin paneli ekranları
│   ├── auth/        # Giriş/kayıt ekranları
│   └── user/        # Kullanıcı ekranları
├── services/        # API ve servis katmanı
└── main.dart        # Ana uygulama dosyası
```

## 🔐 Kimlik Doğrulama

Uygulama Firebase Authentication kullanmaktadır:
- Email/şifre ile giriş
- Kullanıcı rolleri (öğrenci/admin)

## 💾 Veritabanı

Firestore veritabanı kullanılmaktadır:
- Gerçek zamanlı veri senkronizasyonu
- Otomatik offline destek

## 🛠️ Geliştirme

### Debug Modu
```bash
flutter run --debug
```

### Hot Reload
Uygulama çalışırken `r` tuşuna basarak hot reload yapabilirsiniz.

### Linting
```bash
flutter analyze
```

### Test Çalıştırma
```bash
flutter test
```

## 📝 Notlar

- Firebase güvenlik kuralları `firestore.rules` dosyasında tanımlanmıştır
- Uygulama çoklu platform desteği (Android, iOS, Web) sunmaktadır
- Gemini AI entegrasyonu için internet bağlantısı gereklidir

## 🐛 Sorun Giderme

### Yaygın Sorunlar

1. **"flutter: command not found"**
   - Flutter SDK'nın PATH'e eklendiğinden emin olun

2. **"Waiting for another flutter command to release the startup lock"**
   ```bash
   killall -9 dart
   ```

3. **Build hatası alıyorsanız:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Firebase bağlantı sorunu:**
   - `google-services.json` dosyasının doğru lokasyonda olduğundan emin olun
   - Firebase Console'da proje ayarlarını kontrol edin

## 📞 İletişim

Sorularınız için: l2212721046@isparta.edu.tr

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
