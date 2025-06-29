import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/question_pool.dart';
import '../models/course.dart';
import 'auth_service.dart';
import 'gemini_service.dart';

class QuestionPoolService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'question_pools';

  /// Manuel soru ekleme
  static Future<String> addQuestion({
    required String courseId,
    required String topic,
    required String text,
    required List<String> options,
    required int correctAnswerIndex,
    String? imageUrl,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    List<String> tags = const [],
  }) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Sadece akademisyen ve admin soru ekleyebilir
      final hasAccess = await AuthService.hasManagementAccess();
      if (!hasAccess) throw Exception('Soru ekleme yetkiniz yok');

      final question = PoolQuestion(
        id: '', // Firestore tarafından atanacak
        courseId: courseId,
        topic: topic,
        text: text,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        imageUrl: imageUrl,
        difficulty: difficulty,
        source: QuestionSource.manual,
        createdBy: currentUser,
        tags: tags,
      );

      final docRef =
          await _firestore.collection(_collection).add(question.toMap());
      debugPrint('✅ Manual soru eklendi: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Soru ekleme hatası: $e');
      throw Exception('Soru eklenirken hata: $e');
    }
  }

  /// AI ile soru üretme ve ekleme
  static Future<List<String>> generateAndAddQuestions({
    required String courseId,
    required String courseTitle,
    required String topic,
    required QuestionDifficulty difficulty,
    int questionCount = 5,
  }) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Sadece akademisyen ve admin AI soru üretebilir
      final hasAccess = await AuthService.hasManagementAccess();
      if (!hasAccess) throw Exception('AI soru üretme yetkiniz yok');

      debugPrint('🤖 AI ile soru üretme başlatılıyor...');

      // Mevcut soruları al (tekrar önlemek için)
      final existingQuestions = await getQuestionTexts(courseId, topic);

      // Gemini ile sorular üret
      final aiQuestions = await GeminiService.generateQuestions(
        courseId: courseId,
        courseTitle: courseTitle,
        topic: topic,
        createdBy: currentUser,
        difficulty: difficulty,
        questionCount: questionCount,
        existingQuestions: existingQuestions,
      );

      debugPrint(
          '📝 ${aiQuestions.length} AI soru üretildi, Firestore\'a ekleniyor...');

      // Üretilen soruları Firestore'a ekle
      final questionIds = <String>[];
      for (final question in aiQuestions) {
        final docRef =
            await _firestore.collection(_collection).add(question.toMap());
        questionIds.add(docRef.id);
      }

      debugPrint('✅ ${questionIds.length} AI soru başarıyla eklendi');
      return questionIds;
    } catch (e) {
      debugPrint('❌ AI soru üretme hatası: $e');
      throw Exception('AI soru üretimi başarısız: $e');
    }
  }

  /// Kursa ait tüm soruları getir
  static Stream<List<PoolQuestion>> getCourseQuestions(String courseId) {
    return _firestore
        .collection(_collection)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PoolQuestion.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Konuya göre soruları getir
  static Stream<List<PoolQuestion>> getQuestionsByTopic(
      String courseId, String topic) {
    return _firestore
        .collection(_collection)
        .where('courseId', isEqualTo: courseId)
        .where('topic', isEqualTo: topic)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PoolQuestion.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Zorluk seviyesine göre soruları getir
  static Future<List<PoolQuestion>> getQuestionsByDifficulty(
      String courseId, QuestionDifficulty difficulty) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .where('difficulty', isEqualTo: difficulty.name)
          .get();

      return snapshot.docs.map((doc) {
        return PoolQuestion.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Zorluk bazlı soru getirme hatası: $e');
    }
  }

  /// Rastgele soru seçimi (test oluşturma için)
  static Future<List<PoolQuestion>> getRandomQuestions({
    required String courseId,
    String? topic,
    QuestionDifficulty? difficulty,
    int count = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId);

      if (topic != null) {
        query = query.where('topic', isEqualTo: topic);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      final snapshot = await query.get();
      final allQuestions = snapshot.docs.map((doc) {
        return PoolQuestion.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Rastgele seç
      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Rastgele soru seçme hatası: $e');
    }
  }

  /// Kurs konularını getir
  static Future<List<String>> getCourseTopics(String courseId) async {
    try {
      print('=== KONULAR GETİRİLİYOR ===');
      print('Course ID: $courseId');

      final snapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .get();

      final topics = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final topic = data['topic'] as String?;
        if (topic != null && topic.isNotEmpty) {
          topics.add(topic);
        }
      }

      print('Bulunan konular: ${topics.toList()}');
      return topics.toList()..sort();
    } catch (e) {
      print('=== 🔥 FIRESTORE INDEX HATASI YAKALANDI 🔥 ===');
      print('Hata Türü: ${e.runtimeType}');
      print('Hata Mesajı: $e');
      print('=== 👆 YUKARDA Kİ LİNKİ FIREBASE CONSOLE\'A YAPIŞTIRUN 👆 ===');

      debugPrint('=== 🔥 FIRESTORE INDEX HATASI YAKALANDI 🔥 ===');
      debugPrint('Hata Türü: ${e.runtimeType}');
      debugPrint('Hata Mesajı: $e');
      debugPrint(
          '=== 👆 YUKARDA Kİ LİNKİ FIREBASE CONSOLE\'A YAPIŞTIRUN 👆 ===');

      // Console'a da yazdır
      if (kDebugMode) {
        // ignore: avoid_print
        print('FLUTTER LOG: $e');
        debugPrint('FLUTTER DEBUG: $e');
      }

      throw Exception('INDEX_ERROR: $e');
    }
  }

  /// Mevcut soru metinlerini getir (tekrar önleme)
  static Future<List<String>> getQuestionTexts(String courseId,
      [String? topic]) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId);

      if (topic != null) {
        query = query.where('topic', isEqualTo: topic);
      }

      final snapshot = await query.limit(50).get(); // Son 50 soru

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['text'] as String? ?? '';
      }).toList();
    } catch (e) {
      debugPrint('❌ Soru metinleri getirme hatası: $e');
      return [];
    }
  }

  /// Soru güncelleme
  static Future<void> updateQuestion(
    String questionId, {
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
    String? imageUrl,
    String? topic,
    QuestionDifficulty? difficulty,
    List<String>? tags,
  }) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Soru sahibi mi kontrol et
      final questionDoc =
          await _firestore.collection(_collection).doc(questionId).get();
      if (!questionDoc.exists) throw Exception('Soru bulunamadı');

      final questionData = questionDoc.data()!;
      final isAdmin = await AuthService.isAdmin();

      if (!isAdmin && questionData['createdBy'] != currentUser) {
        throw Exception('Bu soruyu güncelleme yetkiniz yok');
      }

      final updateData = <String, dynamic>{};

      if (text != null) updateData['text'] = text;
      if (options != null) updateData['options'] = options;
      if (correctAnswerIndex != null)
        updateData['correctAnswerIndex'] = correctAnswerIndex;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (topic != null) updateData['topic'] = topic;
      if (difficulty != null) updateData['difficulty'] = difficulty.name;
      if (tags != null) updateData['tags'] = tags;

      await _firestore
          .collection(_collection)
          .doc(questionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Soru güncelleme hatası: $e');
    }
  }

  /// Soru silme
  static Future<void> deleteQuestion(String questionId) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Soru sahibi mi kontrol et
      final questionDoc =
          await _firestore.collection(_collection).doc(questionId).get();
      if (!questionDoc.exists) throw Exception('Soru bulunamadı');

      final questionData = questionDoc.data()!;
      final isAdmin = await AuthService.isAdmin();

      if (!isAdmin && questionData['createdBy'] != currentUser) {
        throw Exception('Bu soruyu silme yetkiniz yok');
      }

      await _firestore.collection(_collection).doc(questionId).delete();
      debugPrint('✅ Soru silindi: $questionId');
    } catch (e) {
      throw Exception('Soru silme hatası: $e');
    }
  }

  /// İstatistikler
  static Future<Map<String, dynamic>> getCourseQuestionStats(
      String courseId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .get();

      int totalQuestions = snapshot.docs.length;
      int manualQuestions = 0;
      int aiQuestions = 0;
      final topicCounts = <String, int>{};
      final difficultyCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Kaynak
        final source = data['source'] as String? ?? 'manual';
        if (source == 'manual') {
          manualQuestions++;
        } else {
          aiQuestions++;
        }

        // Konu
        final topic = data['topic'] as String? ?? 'Genel';
        topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;

        // Zorluk
        final difficulty = data['difficulty'] as String? ?? 'medium';
        difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
      }

      return {
        'totalQuestions': totalQuestions,
        'manualQuestions': manualQuestions,
        'aiQuestions': aiQuestions,
        'topicCounts': topicCounts,
        'difficultyCounts': difficultyCounts,
      };
    } catch (e) {
      throw Exception('İstatistik getirme hatası: $e');
    }
  }

  /// Soru havuzundan test oluşturma helper
  static Future<List<PoolQuestion>> selectQuestionsForTest({
    required String courseId,
    required int questionCount,
    Map<String, int>? topicDistribution, // {"Konu1": 3, "Konu2": 2}
    Map<QuestionDifficulty, int>?
        difficultyDistribution, // {easy: 2, medium: 6, hard: 2}
  }) async {
    try {
      final selectedQuestions = <PoolQuestion>[];

      // Konu bazlı dağıtım varsa
      if (topicDistribution != null) {
        for (final entry in topicDistribution.entries) {
          final topicQuestions = await getRandomQuestions(
            courseId: courseId,
            topic: entry.key,
            count: entry.value,
          );
          selectedQuestions.addAll(topicQuestions);
        }
      }
      // Zorluk bazlı dağıtım varsa
      else if (difficultyDistribution != null) {
        for (final entry in difficultyDistribution.entries) {
          final difficultyQuestions = await getRandomQuestions(
            courseId: courseId,
            difficulty: entry.key,
            count: entry.value,
          );
          selectedQuestions.addAll(difficultyQuestions);
        }
      }
      // Sadece toplam sayı verilmişse rastgele seç
      else {
        return await getRandomQuestions(
          courseId: courseId,
          count: questionCount,
        );
      }

      // Eksik varsa rastgele tamamla
      if (selectedQuestions.length < questionCount) {
        final remainingCount = questionCount - selectedQuestions.length;
        final usedIds = selectedQuestions.map((q) => q.id).toSet();

        final extraQuestions = await getRandomQuestions(
          courseId: courseId,
          count: remainingCount + 10, // Biraz fazla al
        );

        // Daha önce seçilmemiş soruları ekle
        for (final question in extraQuestions) {
          if (!usedIds.contains(question.id) &&
              selectedQuestions.length < questionCount) {
            selectedQuestions.add(question);
          }
        }
      }

      // Fazlalık varsa kırp
      if (selectedQuestions.length > questionCount) {
        selectedQuestions.shuffle();
        return selectedQuestions.take(questionCount).toList();
      }

      selectedQuestions.shuffle();
      return selectedQuestions;
    } catch (e) {
      throw Exception('Test soruları seçme hatası: $e');
    }
  }

  /// Test oluşturulduktan sonra seçilen soruların kullanım sayılarını toplu güncelle
  static Future<void> updateMultipleQuestionUsage(
      List<String> questionIds) async {
    debugPrint('🏗️ updateMultipleQuestionUsage başlatıldı (test oluşturma)');
    debugPrint('📝 Question IDs: $questionIds');

    try {
      final batch = _firestore.batch();

      for (final questionId in questionIds) {
        final questionRef = _firestore.collection(_collection).doc(questionId);
        final questionDoc = await questionRef.get();

        if (questionDoc.exists) {
          final currentUsage = questionDoc.data()?['usageCount'] ?? 0;
          final newUsage = currentUsage + 1;

          batch.update(questionRef, {'usageCount': newUsage});
          debugPrint('🔄 Soru kullanım güncellendi: $questionId -> $newUsage');
        } else {
          debugPrint('❌ Soru bulunamadı: $questionId');
        }
      }

      await batch.commit();
      debugPrint(
          '✅ ${questionIds.length} sorunun kullanım sayısı güncellendi (test oluşturma)');
    } catch (e) {
      debugPrint('❌ Toplu kullanım güncelleme hatası: $e');
    }
  }

  /// Test sonucu sonrası soruların başarı oranlarını güncelle (kullanım sayısına dokunmaz)
  static Future<void> updateMultipleQuestionPerformance(
      List<String> questionIds, List<bool> isCorrectList) async {
    if (questionIds.length != isCorrectList.length) {
      debugPrint('❌ Soru ID ve doğruluk listesi boyutları eşleşmiyor');
      debugPrint('📝 Question IDs length: ${questionIds.length}');
      debugPrint('✅ IsCorrect List length: ${isCorrectList.length}');
      return;
    }

    debugPrint('🎯 updateMultipleQuestionPerformance başlatıldı (test çözme)');
    debugPrint('📝 Question IDs: $questionIds');
    debugPrint('✅ IsCorrect List: $isCorrectList');

    try {
      final batch = _firestore.batch();

      for (int i = 0; i < questionIds.length; i++) {
        final questionId = questionIds[i];
        final isCorrect = isCorrectList[i];

        debugPrint(
            '🔄 İşleniyor: $questionId (${i + 1}/${questionIds.length})');

        final questionRef = _firestore.collection(_collection).doc(questionId);
        final questionDoc = await questionRef.get();

        if (questionDoc.exists) {
          final data = questionDoc.data()!;
          final currentAvg = (data['avgPerformance'] ?? 0.0).toDouble();
          final usageCount = (data['usageCount'] ?? 0);

          debugPrint(
              '📊 Mevcut veriler: avgPerformance=$currentAvg, usageCount=$usageCount');

          // Sadece başarı oranını güncelle (usageCount'a dokunma)
          double newAvg;
          if (usageCount == 0) {
            // Henüz hiç kullanılmamış (ilk değer)
            newAvg = isCorrect ? 1.0 : 0.0;
            debugPrint('🔸 İlk değer: newAvg=$newAvg');
          } else {
            // Exponential Moving Average (EMA) kullan
            // newAvg = α * newValue + (1 - α) * oldAvg
            final alpha = 0.15; // Yeni sonuçların ağırlığı
            final newValue = isCorrect ? 1.0 : 0.0;
            newAvg = alpha * newValue + (1 - alpha) * currentAvg;

            debugPrint(
                '🔸 EMA güncelleme: $currentAvg → $newAvg (α=$alpha, yeni=${isCorrect ? "✅" : "❌"})');
          }

          // Sadece avgPerformance'ı güncelle
          batch.update(questionRef, {
            'avgPerformance': newAvg,
          });

          debugPrint(
              '✅ Batch\'e eklendi: $questionId -> Başarı: ${(newAvg * 100).toStringAsFixed(1)}% (usageCount değişmedi: $usageCount)');
        } else {
          debugPrint('❌ Soru bulunamadı: $questionId');
        }
      }

      debugPrint('💾 Batch commit ediliyor...');
      await batch.commit();
      debugPrint('✅ ${questionIds.length} sorunun başarı oranı güncellendi');
    } catch (e) {
      debugPrint('❌ Toplu başarı güncelleme hatası: $e');
      debugPrint('🔍 Hata stackTrace: ${StackTrace.current}');
    }
  }
}
