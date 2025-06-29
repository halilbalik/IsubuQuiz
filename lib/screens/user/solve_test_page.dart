import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/question.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'test_list_page.dart';
import '../../services/question_pool_service.dart';

class SolveTestPage extends StatefulWidget {
  final String testId;
  final List<Map<String, dynamic>> questions;
  final int duration;
  final String testTitle;

  const SolveTestPage({
    super.key,
    required this.testId,
    required this.questions,
    required this.duration,
    required this.testTitle,
  });

  @override
  State<SolveTestPage> createState() => _SolveTestPageState();
}

class _SolveTestPageState extends State<SolveTestPage> {
  late final List<Question> _questions;
  late Timer _timer;
  int _currentQuestionIndex = 0;
  List<int> selectedAnswers = [];
  int _remainingSeconds = 0;
  final Map<String, Uint8List> _imageCache = {};
  bool isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions.map((q) => Question.fromMap(q)).toList();
    selectedAnswers = List.filled(_questions.length, -1);
    _remainingSeconds = widget.duration * 60;
    _startTimer();
    _cacheImages();
  }

  Future<void> _cacheImages() async {
    for (var question in _questions) {
      if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
        try {
          final imageData = base64Decode(question.imageUrl!.split(',')[1]);
          _imageCache[question.imageUrl!] = imageData;
        } catch (e) {
          debugPrint('Görsel önbelleğe alınırken hata: $e');
        }
      }
    }
  }

  Widget _buildQuestionImage(String imageUrl) {
    if (_imageCache.containsKey(imageUrl)) {
      return Image.memory(
        _imageCache[imageUrl]!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Görsel yükleme hatası: $error');
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.grey, size: 48),
          );
        },
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          isTimeUp = true;
          _timer.cancel();
          _submitTest();
        }
      });
    });
  }

  Future<void> _submitTest() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Doğru cevap sayısını hesapla
      int correctAnswers = 0;
      int answeredQuestions = 0;

      // İşaretlenen tüm soruları kontrol et
      for (int i = 0; i < _questions.length; i++) {
        if (selectedAnswers[i] != -1) {
          answeredQuestions++;
          if (selectedAnswers[i] == _questions[i].correctAnswerIndex) {
            correctAnswers++;
          }
        }
      }

      // Puanı hesapla (cevaplanmış sorular üzerinden)
      double score = 0;
      if (answeredQuestions > 0) {
        score = (correctAnswers / _questions.length) * 100;
      }

      final resultData = {
        'userId': user.uid,
        'userEmail': user.email,
        'testId': widget.testId,
        'submissionType': isTimeUp ? 'timeout' : 'manual',
        'score': score,
        'correctCount': correctAnswers,
        'totalQuestions': _questions.length,
        'answeredQuestions': answeredQuestions,
        'userAnswers': selectedAnswers,
        'timeSpent': widget.duration - _remainingSeconds ~/ 60,
        'completedAt': Timestamp.now(),
      };

      // Sonucu Firestore'a kaydet
      debugPrint('🎯 Test sonucu kaydediliyor...');
      debugPrint('👤 User ID: ${user.uid}');
      debugPrint('📝 Test ID: ${widget.testId}');
      debugPrint('📊 Score: $score');
      debugPrint('✅ Correct: $correctAnswers/${_questions.length}');

      await FirebaseFirestore.instance
          .collection('test_results')
          .add(resultData);

      debugPrint('✅ Test sonucu başarıyla kaydedildi!');

      // Test dokümanını al ve questionIds varsa soru havuzu istatistiklerini güncelle
      final testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .get();

      debugPrint('🔍 Test dokümanı kontrol ediliyor...');
      debugPrint('📄 Test exists: ${testDoc.exists}');

      if (testDoc.exists) {
        final testData = testDoc.data()!;
        debugPrint('📊 Test data keys: ${testData.keys.toList()}');

        // Güvenli tür dönüşümü: List<dynamic> -> List<String>
        final questionIdsRaw = testData['questionIds'] as List<dynamic>?;
        final questionIds = questionIdsRaw?.map((e) => e.toString()).toList();

        debugPrint('🔍 questionIdsRaw: $questionIdsRaw');
        debugPrint('🔍 questionIds: $questionIds');
        debugPrint('🔍 questionIds length: ${questionIds?.length ?? 0}');

        if (questionIds != null && questionIds.isNotEmpty) {
          // Her soru için doğru/yanlış bilgisini hazırla
          final isCorrectList = <bool>[];

          for (int i = 0;
              i < _questions.length && i < questionIds.length;
              i++) {
            bool isCorrect;
            if (selectedAnswers[i] != -1) {
              isCorrect =
                  selectedAnswers[i] == _questions[i].correctAnswerIndex;
            } else {
              isCorrect = false; // Cevaplanmamış sorular yanlış sayılır
            }
            isCorrectList.add(isCorrect);

            debugPrint(
                '🎯 Soru ${i + 1}: ID=${questionIds[i]}, Doğru=$isCorrect');
          }

          debugPrint('📈 Soru havuzu istatistikleri güncelleniyor...');
          debugPrint('📝 Question IDs: $questionIds');
          debugPrint('✅ Is Correct List: $isCorrectList');

          // Soru havuzu istatistiklerini güncelle
          await QuestionPoolService.updateMultipleQuestionPerformance(
            questionIds.take(_questions.length).toList(),
            isCorrectList,
          );

          debugPrint(
              '✅ ${questionIds.length} sorunun başarı oranı güncellendi');
        } else {
          debugPrint(
              '⚠️ questionIds null veya boş - soru havuzu güncellemesi yapılmadı');
          debugPrint('🔍 Bu test soru havuzundan oluşturulmamış olabilir');
        }
      } else {
        debugPrint('❌ Test dokümanı bulunamadı: ${widget.testId}');
      }

      // Timer'ı durdur
      _timer.cancel();

      // Test listesi sayfasına yönlendir
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TestListPage(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Test sonucu kaydetme hatası: $e');

      if (!mounted) return;

      // Kullanıcı dostu hata mesajı
      String errorMessage = 'Test sonucu kaydedilemedi';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Yetkisiz erişim hatası. Lütfen tekrar giriş yapın.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'İnternet bağlantısı hatası. Lütfen tekrar deneyin.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Console\'da detaylı hata bilgisi var',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade100,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            textColor: Colors.white,
            onPressed: () => _submitTest(),
          ),
        ),
      );
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: Color(0xFF3A6EA5),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A6EA5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: Color(0xFF3A6EA5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          color: Color(0xFF3A6EA5),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3A6EA5)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                currentQuestion.text,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ),
            if (currentQuestion.imageUrl != null &&
                currentQuestion.imageUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                  minHeight: 100,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildQuestionImage(currentQuestion.imageUrl!),
                ),
              ),
            const SizedBox(height: 20),
            ...List.generate(
              currentQuestion.options.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ElevatedButton(
                  onPressed: () => _selectAnswer(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedAnswers[_currentQuestionIndex] == index
                            ? const Color(0xFF3A6EA5)
                            : Colors.white,
                    foregroundColor:
                        selectedAnswers[_currentQuestionIndex] == index
                            ? Colors.white
                            : Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selectedAnswers[_currentQuestionIndex] == index
                            ? const Color(0xFF3A6EA5)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedAnswers[_currentQuestionIndex] == index
                              ? Colors.white
                              : const Color(0xFF3A6EA5).withOpacity(0.1),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: selectedAnswers[_currentQuestionIndex] ==
                                      index
                                  ? const Color(0xFF3A6EA5)
                                  : const Color(0xFF3A6EA5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentQuestion.options[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                selectedAnswers[_currentQuestionIndex] == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Önceki'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF3A6EA5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLastQuestion ? _submitTest : _nextQuestion,
                      icon: Icon(
                          isLastQuestion ? Icons.check : Icons.arrow_forward),
                      label: Text(isLastQuestion ? 'Bitir' : 'Sonraki'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6EA5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _imageCache.clear();
    super.dispose();
  }
}
