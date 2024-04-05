# 🎯 IsubuQuiz

## AI Destekli Üniversite İçi Mobil Quiz Platformu

Flutter tabanlı, Firebase backend'li ve Google Gemini AI entegrasyonlu quiz uygulaması.

## ✨ Özellikler

### 👨‍🏫 Akademisyen Paneli

- **Quiz Oluşturma**: Kolay quiz oluşturma arayüzü
- **AI Soru Üretimi**: Google Gemini AI ile otomatik soru üretimi
- **Quiz Yönetimi**: Quiz'leri aktif/pasif yapma, silme
- **Sonuç Takibi**: Öğrenci performanslarını görüntüleme

### 👨‍🎓 Öğrenci Paneli

- **Aktif Quiz'ler**: Çözülebilir quiz'leri listeleme
- **Quiz Çözme**: Kullanıcı dostu quiz arayüzü
- **Sonuçlarım**: Geçmiş performansları görüntüleme
- **İstatistikler**: Detaylı başarı analizi

### 🤖 AI Özellikleri

- **Otomatik Soru Üretimi**: Konu bazlı soru havuzu
- **Zorluk Seviyeleri**: Kolay, Orta, Zor
- **Türkçe Destek**: Tam Türkçe soru üretimi
- **Akıllı Parsing**: AI yanıtlarını yapılandırılmış veriye dönüştürme

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.5.3+)
- Firebase hesabı
- Google AI Studio hesabı (Gemini API için)

### 1. Repository'yi Klonlayın

```bash
git clone https://github.com/your-username/isubu-quiz.git
cd isubu-quiz
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. Firebase Konfigürasyonu

#### Template dosyasını kopyalayın

```bash
cp lib/firebase_options_template.dart lib/firebase_options.dart
```

#### Firebase Console'dan bilgileri alın

1. [Firebase Console](https://console.firebase.google.com) → Proje oluşturun
2. Authentication → Email/Password aktifleştirin
3. Firestore Database → Test modunda oluşturun
4. Project Settings → General → SDK setup and configuration
5. Platform seçip konfigürasyon bilgilerini kopyalayın

#### firebase_options.dart dosyasını güncelleyin

- `YOUR_PROJECT_ID_HERE` → Firebase project ID'nizi
- `YOUR_*_API_KEY_HERE` → İlgili platform API key'lerini
- `YOUR_*_APP_ID_HERE` → İlgili platform App ID'lerini

### 4. AI Konfigürasyonu

#### AI template dosyasını kopyalayın

```bash
cp lib/config/app_config_template.dart lib/config/app_config.dart
```

#### Google AI Studio'dan API key alın

1. [Google AI Studio](https://makersuite.google.com/app/apikey) → API key oluşturun
2. `lib/config/app_config.dart` → `geminiApiKey` alanını güncelleyin

### 5. Uygulamayı Çalıştırın

```bash
flutter run
```

## 🏗️ Mimari

```text
lib/
├── config/           # Konfigürasyon dosyaları
├── models/           # Veri modelleri
├── services/         # İş mantığı servisleri
├── screens/          # UI ekranları
│   ├── auth/         # Giriş/Kayıt
│   ├── academic/     # Akademisyen paneli
│   └── student/      # Öğrenci paneli
└── widgets/          # Ortak bileşenler
```

### Katmanlar

- **Models**: User, Quiz, Question, QuizResult
- **Services**: AuthService, QuizService, AIService
- **UI**: Role-based navigation ve modern Material Design

## 🔧 Teknolojiler

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore)
- **AI**: Google Gemini API
- **State Management**: flutter_bloc
- **Navigation**: go_router
- **Architecture**: Clean Architecture (simplified)

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
