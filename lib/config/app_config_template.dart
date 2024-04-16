// Bu dosya app_config.dart için bir şablon, yani örnek.
// Kopyalayıp adını 'app_config.dart' yap ve kendi bilgilerini gir.
// Sakın bu halini kullanma, çalışmaz.

class AppConfig {
  // Google Gemini AI API anahtarın buraya gelecek.
  // https://makersuite.google.com/app/apikey adresinden alabilirsin.
  static const String geminiApiKey = 'SENIN_GEMINI_API_KEYIN_BURAYA';

  // Firebase proje ID'n. Bu çok da önemli değil, opsiyonel.
  static const String firebaseProjectId = 'SENIN_FIREBASE_PROJE_IDN';

  // Uygulamanın genel ayarları, adıdır, sürümüdür falan.
  static const String appName = 'IsubuQuiz';
  static const String appVersion = '1.0.0';

  // Yapay zeka ayarları.
  static const int maxQuestionsPerGeneration = 10; // Tek seferde en fazla 10 soru üretsin.
  static const String defaultLanguage = 'tr'; // Varsayılan dil Türkçe.
}