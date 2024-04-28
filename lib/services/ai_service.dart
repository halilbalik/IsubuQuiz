import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/question.dart';

// Bu servis, Google Gemini AI ile konuşup ondan soru üretmesini istiyor.
class AIService {
  late final GenerativeModel _model;

  // Servis oluşturulduğunda Gemini modelini hazırlıyoruz.
  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Hızlı ve ucuz olan modeli seçtik.
      apiKey: AppConfig.geminiApiKey, // API key'i config dosyasından alıyoruz.
    );
  }

  // Dışarıdan çağrılacak ana metot bu. Konu, sayı ve zorluk verip soru listesi alıyoruz.
  Future<List<Question>> generateQuestions({
    required String topic,
    required int count,
    required QuestionDifficulty difficulty,
  }) async {
    try {
      // Önce Gemini'ye göndereceğimiz metni (prompt) hazırlıyoruz.
      final prompt = _buildPrompt(topic, count, difficulty);
      // Sonra bu metni Gemini'ye gönderip cevap bekliyoruz.
      final response = await _model.generateContent([Content.text(prompt)]);

      // Cevap geldiyse ve içinde metin varsa, bu metni işleyip soru listesine çeviriyoruz.
      if (response.text != null) {
        return _parseQuestions(response.text!);
      } else {
        throw Exception('Gemini API den boş yanıt geldi, bir sorun var.');
      }
    } catch (e) {
      throw Exception('AI soru üretirken bir hata oluştu: $e');
    }
  }

  // Gemini'ye ne soracağımızı hazırlayan metot.
  // Buna "prompt engineering" deniyor, havalı bir isim.
  String _buildPrompt(String topic, int count, QuestionDifficulty difficulty) {
    return '''
Konu: $topic
Zorluk Seviyesi: ${difficulty.displayName}
Soru Sayısı: $count

Bu konuda $count adet çoktan seçmeli soru oluştur. Her soru şu formatta olmalı:

SORU: [Soru metni]
A) [Seçenek A]
B) [Seçenek B]
C) [Seçenek C]
D) [Seçenek D]
DOĞRU: [A, B, C veya D]
AÇIKLAMA: [Kısa açıklama]
---

Kurallar:
- Sorular Türkçe olmalı.
- ${difficulty.displayName} seviyesinde olmalı.
- Her soru net ve anlaşılır olmalı.
- Seçenekler mantıklı olmalı.
- Açıklama kısa ve öz olmalı.
- Her sorudan sonra --- ile ayır.

Örnek:
SORU: Flutter'da StatefulWidget ve StatelessWidget arasındaki temel fark nedir?
A) StatefulWidget daha hızlı çalışır
B) StatefulWidget durumu değişebilen widget'lardır
C) StatelessWidget sadece Text widget'ında kullanılır
D) Fark yoktur
DOĞRU: B
AÇIKLAMA: StatefulWidget durumu değişebilen widget'lar iken StatelessWidget durumu değişmeyen widget'lardır.
---
''';
  }

  // Gemini'den gelen uzun metni parçalayıp Question listesine dönüştüren metot.
  List<Question> _parseQuestions(String response) {
    final questions = <Question>[];
    // Cevabı "---" karakterine göre bölerek her bir soruyu ayrı bir blok haline getiriyoruz.
    final questionBlocks =
        response.split('---').where((block) => block.trim().isNotEmpty);

    for (int i = 0; i < questionBlocks.length; i++) {
      final block = questionBlocks.elementAt(i).trim();
      try {
        // Her bir bloğu tek tek parse edip soruya çeviriyoruz.
        final question = _parseSingleQuestion(block, i);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        // Eğer bir soru bloğu hatalıysa onu atlayıp devam ediyoruz.
        continue;
      }
    }

    return questions;
  }

  // Tek bir soru bloğunu (string) alıp Question objesine çeviren metot.
  Question? _parseSingleQuestion(String block, int index) {
    try {
      // Bloğu satırlara ayırıyoruz.
      final lines =
          block.split('\n').where((line) => line.trim().isNotEmpty).toList();

      String? questionText;
      final options = <String>[];
      String? correctAnswer;
      String? explanation;

      // Her satırı tek tek gezip "SORU:", "A)", "DOĞRU:" gibi etiketlere göre bilgileri çekiyoruz.
      for (final line in lines) {
        final trimmedLine = line.trim();

        if (trimmedLine.startsWith('SORU:')) {
          questionText = trimmedLine.substring(5).trim();
        } else if (trimmedLine.startsWith('A)')) {
          options.add(trimmedLine.substring(2).trim());
        } else if (trimmedLine.startsWith('B)')) {
          options.add(trimmedLine.substring(2).trim());
        } else if (trimmedLine.startsWith('C)')) {
          options.add(trimmedLine.substring(2).trim());
        } else if (trimmedLine.startsWith('D)')) {
          options.add(trimmedLine.substring(2).trim());
        } else if (trimmedLine.startsWith('DOĞRU:')) {
          correctAnswer = trimmedLine.substring(6).trim().toUpperCase();
        } else if (trimmedLine.startsWith('AÇIKLAMA:')) {
          explanation = trimmedLine.substring(9).trim();
        }
      }

      // Gerekli bilgiler eksikse (örn: 4 şık yoksa) bu bloğu geçersiz sayıyoruz.
      if (questionText == null ||
          options.length != 4 ||
          correctAnswer == null ||
          !['A', 'B', 'C', 'D'].contains(correctAnswer)) {
        return null;
      }

      // Doğru cevabın harfini (A, B, C, D) index'e (0, 1, 2, 3) çeviriyoruz.
      int correctIndex;
      switch (correctAnswer) {
        case 'A':
          correctIndex = 0;
          break;
        case 'B':
          correctIndex = 1;
          break;
        case 'C':
          correctIndex = 2;
          break;
        case 'D':
          correctIndex = 3;
          break;
        default:
          return null;
      }

      // Her şey yolundaysa, Question objesini oluşturup döndürüyoruz.
      return Question(
        id: 'ai_generated_${DateTime.now().millisecondsSinceEpoch}_$index',
        questionText: questionText,
        options: options,
        correctAnswer: correctIndex,
        explanation: explanation,
        isAIGenerated: true, // Bu sorunun AI tarafından üretildiğini belirtiyoruz.
      );
    } catch (e) {
      // Herhangi bir hata olursa null döndür, program çökmesin.
      return null;
    }
  }

  // AI servisinin çalışıp çalışmadığını kontrol etmek için basit bir metot.
  Future<bool> checkAIHealth() async {
    try {
      final response = await _model.generateContent(
          [Content.text('Merhaba, çalışıyor musun? Kısa yanıt ver.')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}