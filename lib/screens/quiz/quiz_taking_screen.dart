import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/quiz_service.dart';
import '../../../models/quiz.dart';
import '../../../models/quiz_result.dart';
import '../student/student_home_screen.dart';
import '../student/my_results_screen.dart';

// Öğrencinin quizi çözdüğü ekran.
class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz; // Hangi quizi çözeceği bilgisi.

  const QuizTakingScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();
  final PageController _pageController = PageController(); // Sorular arasında geçiş için.

  int _currentQuestionIndex = 0; // Şu an hangi soruda olduğumuz.
  final Map<String, int> _answers = {}; // Cevapları tutan map. Soru ID -> Cevap Index.
  DateTime? _startTime; // Quize başlama zamanı.
  bool _isSubmitting = false; // Quiz gönderiliyor mu?

  @override
  void initState() {
    super.initState();
    // Ekran açılınca başlama zamanını kaydet.
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Quizi bitirip sonucu gönderen metot.
  Future<void> _submitQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Doğru cevap sayısını hesapla.
      int correctAnswers = 0;
      for (int i = 0; i < widget.quiz.questions.length; i++) {
        final question = widget.quiz.questions[i];
        final userAnswer = _answers[question.id];
        if (userAnswer != null && userAnswer == question.correctAnswer) {
          correctAnswers++;
        }
      }

      // Sonuç objesini oluştur.
      final result = QuizResult(
        id: '',
        quizId: widget.quiz.id,
        studentId: currentUser.id,
        answers: _answers,
        startTime: _startTime!,
        endTime: DateTime.now(),
        score: correctAnswers,
        totalQuestions: widget.quiz.questions.length,
      );

      // Sonucu Firebase'e kaydet.
      await _quizService.submitQuizResult(result);

      if (mounted) {
        // Sonuç ekranına yönlendir.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              result: result,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz gönderme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bir şık seçildiğinde bu metot çalışır.
  void _selectAnswer(String questionId, int answerIndex) {
    setState(() {
      _answers[questionId] = answerIndex;
    });
  }

  // Sonraki soruya geç.
  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Önceki soruya dön.
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        // Çıkış butonu.
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitDialog();
          },
        ),
      ),
      body: Column(
        children: [
          // Ne kadar ilerlediğini gösteren çubuk.
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),

          // Soru numarası.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Soru ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Soruların gösterildiği PageView.
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, index) {
                final question = widget.quiz.questions[index];
                final selectedAnswer = _answers[question.id];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Soru metni.
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            question.questionText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Şıklar.
                      ...List.generate(question.options.length, (optionIndex) {
                        final isSelected = selectedAnswer == optionIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            color: isSelected
                                ? Colors.blue.shade100
                                : Colors.white,
                            child: InkWell(
                              onTap: () =>
                                  _selectAnswer(question.id, optionIndex),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: optionIndex,
                                      groupValue: selectedAnswer,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _selectAnswer(question.id, value);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ['A', 'B', 'C', 'D'][optionIndex],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        question.options[optionIndex],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // İleri/Geri/Bitir butonları.
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Önceki'),
                    ),
                  ),
                if (_currentQuestionIndex > 0 &&
                    _currentQuestionIndex < widget.quiz.questions.length - 1)
                  const SizedBox(width: 16),
                if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      child: const Text('Sonraki'),
                    ),
                  ),
                // Son soruya gelince "Bitir" butonu göster.
                if (_currentQuestionIndex == widget.quiz.questions.length - 1)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text('Quiz\'i Bitir'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quizden çıkmak isteyince emin misin diye sor.
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz\'den Çık'),
        content: const Text(
          'Quiz\'den çıkmak istediğinizden emin misiniz? '
          'İlerlemeniz kaydedilmeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat.
              Navigator.pop(context); // Quiz ekranını kapat.
            },
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }
}

// Quiz bittikten sonra gösterilen sonuç ekranı.
class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = result.scorePercentage;
    final isPassed = percentage >= 70; // Geçme notu 70.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Sonucu'),
        backgroundColor: isPassed ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Geri butonu olmasın.
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Geçtiyse tik, kaldıysa çarpı ikonu.
              Icon(
                isPassed ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),

              // Tebrikler veya Daha İyi Şanslar başlığı.
              Text(
                isPassed ? 'Tebrikler!' : 'Daha İyi Şanslar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              // Yüzdelik skor.
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Doğru/Toplam soru sayısı.
              Text(
                '${result.correctAnswers}/${result.totalQuestions} doğru cevap',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Diğer detaylar.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'Quiz',
                        value: quiz.title,
                      ),
                      const Divider(),
                      _ResultRow(
                        label: 'Süre',
                        value: _formatDuration(result.completionTime),
                      ),
                      const Divider(),
                      _ResultRow(
                        label: 'Doğru Cevaplar',
                        value: '${result.correctAnswers}',
                      ),
                      const Divider(),
                      _ResultRow(
                        label: 'Yanlış Cevaplar',
                        value: '${result.wrongAnswers}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Ana Sayfa ve Sonuçlarım butonları.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Ana Sayfa'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyResultsScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Sonuçlarım'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Süreyi "Xdk Ysn" formatına çeviren metot.
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}dk ${seconds}sn';
  }
}

// Sonuç ekranındaki her bir satır için küçük bir widget.
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}