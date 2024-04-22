import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz.dart';
import '../../models/quiz_result.dart';

// Akademisyenin kendi quizlerinin istatistiklerini gördüğü ekran.
class AcademicStatisticsScreen extends StatefulWidget {
  const AcademicStatisticsScreen({super.key});

  @override
  State<AcademicStatisticsScreen> createState() =>
      _AcademicStatisticsScreenState();
}

class _AcademicStatisticsScreenState extends State<AcademicStatisticsScreen> {
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();

  bool _isLoading = true; // Veriler yükleniyor mu?
  List<Quiz> _quizzes = []; // Akademisyenin oluşturduğu quizler.
  List<QuizResult> _allResults = []; // Tüm quizlere ait tüm sonuçlar.

  @override
  void initState() {
    super.initState();
    // Ekran açılınca verileri yükle.
    _loadData();
  }

  // Bütün verileri Firebase'den çeken metot.
  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        // Önce akademisyenin kendi quizlerini çekiyoruz.
        _quizService.getAcademicQuizzes(user.id).listen((quizzes) async {
          setState(() {
            _quizzes = quizzes;
          });

          // Sonra her bir quiz için girilen sonuçları çekiyoruz.
          // Bu biraz yavaş olabilir ama şimdilik böyle idare edelim.
          List<QuizResult> allResults = [];
          for (Quiz quiz in quizzes) {
            final results = await _quizService.getQuizResults(quiz.id);
            allResults.addAll(results);
          }

          setState(() {
            _allResults = allResults;
            _isLoading = false; // Yükleme bitti.
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
    // Yükleniyorsa dönen yuvarlak.
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İstatistikler'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // İstatistikleri hesaplayalım.
    final totalQuizzes = _quizzes.length;
    final activeQuizzes = _quizzes.where((q) => q.isActive).length;
    final totalAttempts = _allResults.length;
    // Ortalama başarıyı hesaplarken liste boş mu diye kontrol edelim, yoksa uygulama çöker.
    final averageScore = _allResults.isEmpty
        ? 0.0
        : _allResults.map((r) => r.scorePercentage).reduce((a, b) => a + b) /
            _allResults.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel istatistikler başlığı.
            const Text(
              'Genel İstatistikler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // O dörtlü istatistik kartları.
            GridView.count(
              shrinkWrap: true, // İçeriği kadar yer kaplasın.
              physics: const NeverScrollableScrollPhysics(), // Kendi içinde scroll olmasın.
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Toplam Quiz',
                  value: totalQuizzes.toString(),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Aktif Quiz',
                  value: activeQuizzes.toString(),
                  icon: Icons.play_circle,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Toplam Deneme',
                  value: totalAttempts.toString(),
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Ortalama Başarı',
                  value: '${averageScore.toStringAsFixed(1)}%', // Virgülden sonra 1 basamak.
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quiz bazında detaylar.
            const Text(
              'Quiz Detayları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Eğer hiç quiz yoksa bir yazı göster.
            if (_quizzes.isEmpty)
              const Center(
                child: Text(
                  'Henüz quiz oluşturmadınız',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              // Quiz listesini map ile dönüp her biri için bir kart oluşturuyoruz.
              ..._quizzes.map((quiz) {
                // Her bir quiz için deneme sayısını ve ortalama skoru hesaplıyoruz.
                final attempts =
                    _allResults.where((r) => r.quizId == quiz.id).toList();
                final avgScore = attempts.isEmpty
                    ? 0.0
                    : attempts
                            .map((r) => r.scorePercentage)
                            .reduce((a, b) => a + b) /
                        attempts.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: quiz.isActive
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        quiz.isActive ? Icons.play_circle : Icons.pause_circle,
                        color: quiz.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(
                      quiz.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                        '${attempts.length} deneme • Ort: ${avgScore.toStringAsFixed(1)}%'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quiz.isActive
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quiz.isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          color: quiz.isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontSize: 12,
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
}

// İstatistik kartlarının widget'ı.
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