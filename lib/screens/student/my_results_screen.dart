import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_result.dart';

// Öğrencinin geçmiş quiz sonuçlarını gördüğü ekran.
class MyResultsScreen extends StatefulWidget {
  const MyResultsScreen({super.key});

  @override
  State<MyResultsScreen> createState() => _MyResultsScreenState();
}

class _MyResultsScreenState extends State<MyResultsScreen> {
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();
  String? _currentUserId; // Mevcut öğrencinin ID'si.

  @override
  void initState() {
    super.initState();
    // Ekran açılınca kullanıcı ID'sini al.
    _getCurrentUser();
  }

  // Mevcut kullanıcıyı getiren metot.
  Future<void> _getCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    setState(() {
      _currentUserId = user?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Sonuçlarım'),
      ),
      // Kullanıcı ID'si gelene kadar bekle.
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          // StreamBuilder ile sonuçları anlık dinle.
          : StreamBuilder<List<QuizResult>>(
              stream: _quizService.getStudentResults(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Yine o meşhur index hatası için önlem.
                if (snapshot.hasError) {
                  final errorMessage = snapshot.error.toString();
                  if (errorMessage.contains('index') ||
                      errorMessage.contains('FAILED_PRECONDITION')) {
                    debugPrint(
                        '\n🚨 FIRESTORE INDEX HATASI - SONUÇLARIM SAYFASI');
                    debugPrint('🔗 INDEX URL (VS CODE\'DA CTRL+CLICK):');

                    final urlMatch = RegExp(
                            r'https://console\.firebase\.google.com[^\s\)]*')
                        .firstMatch(errorMessage);
                    if (urlMatch != null) {
                      debugPrint(urlMatch.group(0)!);
                    } else {
                      debugPrint(
                          'https://console.firebase.google.com/v1/r/project/isubuquiz/firestore/indexes');
                    }
                    debugPrint(
                        '📌 Yukarıdaki URL\'yi VS Code\'da Ctrl+Click ile açın!\n');
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Firebase Index Hatası'),
                        const SizedBox(height: 8),
                        const Text(
                          'VS Code Debug Console\'unda URL\'yi kontrol edin',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Geri Dön'),
                        ),
                      ],
                    ),
                  );
                }

                final results = snapshot.data ?? [];

                // Hiç sonuç yoksa bilgi ver.
                if (results.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz quiz çözmediniz',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'İlk quiz\'inizi çözmeye başlayın!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Sonuçları ListView ile listele.
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final percentage = result.percentage;
                    final isPassed = result.isPassed;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    // Quiz başlığını da getirmek lazım aslında.
                                    // Şimdilik böyle idare etsin.
                                    'Quiz ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Geçti/Kaldı etiketi.
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPassed
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isPassed ? 'Geçti' : 'Kaldı',
                                    style: TextStyle(
                                      color: isPassed
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Doğru, Toplam, Başarı, Süre gibi bilgiler.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ResultInfo(
                                  label: 'Doğru',
                                  value: '${result.score}',
                                  color: Colors.green,
                                ),
                                _ResultInfo(
                                  label: 'Toplam',
                                  value: '${result.totalQuestions}',
                                  color: Colors.blue,
                                ),
                                _ResultInfo(
                                  label: 'Başarı',
                                  value: '${percentage.toStringAsFixed(1)}%',
                                  color: isPassed ? Colors.green : Colors.red,
                                ),
                                _ResultInfo(
                                  label: 'Süre',
                                  value: _formatDuration(result.duration),
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Tamamlanma tarihi.
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tamamlandı: ${_formatDate(result.endTime)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // Tarihi "gg.aa.yyyy ss:dd" formatına çevirir.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Süreyi "X:YY" formatına çevirir.
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Sonuç kartındaki küçük bilgi kutucukları için bir widget.
class _ResultInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}