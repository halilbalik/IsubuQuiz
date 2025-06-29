import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/question_pool.dart';

class GeminiService {
  static const String _apiKey =
      'X'; // TODO: Gerçek API key ekle
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash-exp', // En yeni model
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    return _model!;
  }

  /// Belirli bir konu için AI ile soru üret
  static Future<List<PoolQuestion>> generateQuestions({
    required String courseId,
    required String courseTitle,
    required String topic,
    required String createdBy,
    required QuestionDifficulty difficulty,
    int questionCount = 5,
    List<String> existingQuestions = const [],
  }) async {
    try {
      debugPrint('🤖 AI ile soru üretiliyor...');
      debugPrint('📚 Ders: $courseTitle');
      debugPrint('📝 Konu: $topic');
      debugPrint('🎯 Zorluk: ${difficulty.displayName}');
      debugPrint('🔢 Soru sayısı: $questionCount');

      final prompt = _buildPrompt(
        courseTitle: courseTitle,
        topic: topic,
        difficulty: difficulty,
        questionCount: questionCount,
        existingQuestions: existingQuestions,
      );

      debugPrint('📤 Prompt gönderiliyor...');
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('Gemini\'den boş yanıt geldi');
      }

      debugPrint('📥 Gemini yanıtı alındı');
      debugPrint('📄 Yanıt uzunluğu: ${response.text!.length} karakter');

      // JSON çıktısını parse et
      final questions = _parseGeminiResponse(
        response.text!,
        courseId: courseId,
        topic: topic,
        difficulty: difficulty,
        createdBy: createdBy,
      );

      debugPrint('✅ ${questions.length} soru başarıyla oluşturuldu');
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ AI soru üretme hatası: $e');
      debugPrint('📊 Stack trace: $stackTrace');

      // Fallback: Örnek sorular üret
      return _generateFallbackQuestions(
        courseId: courseId,
        topic: topic,
        difficulty: difficulty,
        createdBy: createdBy,
        questionCount: questionCount,
      );
    }
  }

  /// Gemini için prompt oluştur
  static String _buildPrompt({
    required String courseTitle,
    required String topic,
    required QuestionDifficulty difficulty,
    required int questionCount,
    required List<String> existingQuestions,
  }) {
    final difficultyDescription = {
      QuestionDifficulty.easy: 'Kolay seviye - Temel kavramlar, basit tanımlar',
      QuestionDifficulty.medium:
          'Orta seviye - Uygulama, analiz, karşılaştırma',
      QuestionDifficulty.hard:
          'Zor seviye - Sentez, değerlendirme, problem çözme',
    };

    return '''
Sen bir eğitim uzmanısın. Aşağıdaki kriterlere göre çoktan seçmeli sorular oluştur:

DERS: $courseTitle
KONU: $topic
ZORLUK SEVİYESİ: ${difficulty.displayName} - ${difficultyDescription[difficulty]}
SORU SAYISI: $questionCount

GEREKSINIMLER:
1. Her soru Türkçe olmalı
2. 4 seçenekli çoktan seçmeli format
3. Akademik ve eğitici içerik
4. Zorluk seviyesine uygun detay
5. Seçenekler mantıklı ve yanıltıcı olmalı
${existingQuestions.isNotEmpty ? '6. Şu sorulardan farklı olmalı: ${existingQuestions.take(3).join(", ")}' : ''}

ÇIKTI FORMATI (JSON):
{
  "questions": [
    {
      "text": "Soru metni?",
      "options": ["A) Seçenek 1", "B) Seçenek 2", "C) Seçenek 3", "D) Seçenek 4"],
      "correctAnswerIndex": 0,
      "tags": ["tag1", "tag2"]
    }
  ]
}

SADECE JSON FORMATINDA YANIT VER, BAŞKA METİN EKLEME!
''';
  }

  /// Gemini yanıtını parse et
  static List<PoolQuestion> _parseGeminiResponse(
    String response, {
    required String courseId,
    required String topic,
    required QuestionDifficulty difficulty,
    required String createdBy,
  }) {
    try {
      // JSON kısmını çıkar (bazen ekstra metin olabiliyor)
      String jsonString = response.trim();

      // JSON başlangıç ve bitişini bul
      final jsonStart = jsonString.indexOf('{');
      final jsonEnd = jsonString.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('JSON formatı bulunamadı');
      }

      jsonString = jsonString.substring(jsonStart, jsonEnd);

      final parsed = json.decode(jsonString);
      final questionsJson = parsed['questions'] as List;

      return questionsJson.map((questionJson) {
        return PoolQuestion(
          id: '', // Firestore otomatik atayacak
          courseId: courseId,
          topic: topic,
          text: questionJson['text'] as String,
          options: List<String>.from(questionJson['options']),
          correctAnswerIndex: questionJson['correctAnswerIndex'] as int,
          difficulty: difficulty,
          source: QuestionSource.ai,
          createdBy: createdBy,
          tags: List<String>.from(questionJson['tags'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ JSON parse hatası: $e');
      debugPrint('📄 Raw response: $response');
      throw Exception('AI yanıtı parse edilemedi: $e');
    }
  }

  /// Hata durumunda fallback sorular
  static List<PoolQuestion> _generateFallbackQuestions({
    required String courseId,
    required String topic,
    required QuestionDifficulty difficulty,
    required String createdBy,
    required int questionCount,
  }) {
    debugPrint('🔄 Fallback sorular oluşturuluyor...');

    return List.generate(questionCount, (index) {
      return PoolQuestion(
        id: '',
        courseId: courseId,
        topic: topic,
        text: '$topic konusu ile ilgili örnek soru ${index + 1}?',
        options: [
          'A) Seçenek 1',
          'B) Seçenek 2',
          'C) Seçenek 3',
          'D) Seçenek 4'
        ],
        correctAnswerIndex: 0,
        difficulty: difficulty,
        source: QuestionSource.ai,
        createdBy: createdBy,
        tags: ['örnek', topic.toLowerCase()],
      );
    });
  }

  /// Konu önerileri al
  static Future<List<String>> suggestTopics({
    required String courseTitle,
    required String courseDescription,
  }) async {
    try {
      final prompt = '''
"$courseTitle" dersi için konu başlıkları öner.
Ders açıklaması: $courseDescription

10 adet konu başlığı öner. Her başlık 2-5 kelime olsun.
Sadece liste halinde döndür, başka açıklama ekleme:

1. Konu 1
2. Konu 2
...
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) return [];

      // Yanıtı parse et ve liste oluştur
      final lines = response.text!.split('\n');
      final topics = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && RegExp(r'^\d+\.').hasMatch(trimmed)) {
          final topic = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          if (topic.isNotEmpty) {
            topics.add(topic);
          }
        }
      }

      return topics.take(10).toList();
    } catch (e) {
      debugPrint('❌ Konu önerisi hatası: $e');
      return [
        'Giriş ve Temel Kavramlar',
        'Temel Prensipler',
        'Uygulama Örnekleri',
        'İleri Konular',
        'Pratik Uygulamalar'
      ];
    }
  }
}
