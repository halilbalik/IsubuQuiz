import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_result.dart';

// Öğrencinin kendi istatistiklerini gördüğü ekran.
class StudentStatisticsScreen extends StatefulWidget {
  const StudentStatisticsScreen({super.key});

  @override
  State<StudentStatisticsScreen> createState() =>
      _StudentStatisticsScreenState();
}

class _StudentStatisticsScreenState extends State<StudentStatisticsScreen> {
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  List<QuizResult> _results = []; // Öğrencinin tüm sonuçları.

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Verileri yükleyen metot.
  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        // Stream'i dinleyerek sonuçları anlık olarak alıyoruz.
        _quizService.getStudentResults(user.id).listen((results) {
          setState(() {
            _results = results;
            _isLoading = false;
          });
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İstatistiklerim'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // İstatistikleri hesapla.
    final totalQuizzes = _results.length;
    final passedQuizzes = _results.where((r) => r.scorePercentage >= 70).length;
    final averageScore = _results.isEmpty
        ? 0.0
        : _results.map((r) => r.scorePercentage).reduce((a, b) => a + b) /
            _results.length;
    // fold metodu ile listedeki tüm elemanları toplayabiliyoruz.
    final totalCorrectAnswers =
        _results.fold(0, (sum, r) => sum + r.correctAnswers);
    final totalQuestions = _results.fold(0, (sum, r) => sum + r.totalQuestions);
    final overallAccuracy = totalQuestions == 0
        ? 0.0
        : (totalCorrectAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistiklerim'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel performans başlığı.
            const Text(
              'Genel Performansım',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dörtlü istatistik kartları.
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Çözülen Quiz',
                  value: totalQuizzes.toString(),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Geçilen Quiz',
                  value: passedQuizzes.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Ortalama Puan',
                  value: '${averageScore.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Doğruluk Oranı',
                  value: '${overallAccuracy.toStringAsFixed(1)}%',
                  icon: Icons.precision_manufacturing,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Son sonuçlar başlığı.
            const Text(
              'Son Quiz Sonuçlarım',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Hiç sonuç yoksa bilgi ver.
            if (_results.isEmpty)
              const Center(
                child: Text(
                  'Henüz quiz çözmediniz',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              // Son 10 sonucu listele.
              ..._results.take(10).map((result) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    // Sol tarafta yüzdelik skoru gösteren yuvarlak.
                    leading: CircleAvatar(
                      backgroundColor: _getScoreColor(result.scorePercentage)
                          .withOpacity(0.2),
                      child: Text(
                        '${result.scorePercentage.toInt()}%',
                        style: TextStyle(
                          color: _getScoreColor(result.scorePercentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: const Text(
                      'Quiz Sonucu',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${result.correctAnswers}/${result.totalQuestions} doğru • ${_formatDuration(result.completionTime)}',
                    ),
                    // Sağ tarafta "Mükemmel", "İyi" gibi bir etiket.
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(result.scorePercentage)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getScoreLabel(result.scorePercentage),
                        style: TextStyle(
                          color: _getScoreColor(result.scorePercentage),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Puana göre renk döndüren bir metot.
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  // Puana göre etiket döndüren bir metot.
  String _getScoreLabel(double score) {
    if (score >= 90) return 'Mükemmel';
    if (score >= 70) return 'İyi';
    if (score >= 50) return 'Orta';
    return 'Düşük';
  }

  // Süreyi formatlayan bir metot.
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}dk ${seconds}sn';
  }
}

// İstatistik kartları için widget.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}