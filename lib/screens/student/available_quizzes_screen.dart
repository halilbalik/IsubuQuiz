import 'package:flutter/material.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz.dart';
import '../quiz/quiz_taking_screen.dart';

// Öğrencinin çözebileceği aktif quizlerin listelendiği ekran.
class AvailableQuizzesScreen extends StatelessWidget {
  const AvailableQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final QuizService quizService = QuizService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktif Quiz\'ler'),
      ),
      // StreamBuilder ile aktif quizleri anlık olarak dinliyoruz.
      // Yani bir akademisyen yeni bir quiz eklediğinde burada anında görünür.
      body: StreamBuilder<List<Quiz>>(
        stream: quizService.getActiveQuizzes(),
        builder: (context, snapshot) {
          // Veri gelene kadar bekleme animasyonu göster.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Eğer bir hata olursa, özellikle de o meşhur Firebase index hatası,
          // geliştiriciye yardımcı olmak için konsola bir link basıyoruz.
          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            if (errorMessage.contains('index') ||
                errorMessage.contains('FAILED_PRECONDITION')) {
              debugPrint('\n🚨 FIRESTORE INDEX HATASI - QUIZ ÇÖZ SAYFASI');
              debugPrint('🔗 INDEX URL (VS CODE\'DA CTRL+CLICK):');

              final urlMatch =
                  RegExp(r'https://console\.firebase\.google\.com[^\s\)]*')
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

          final quizzes = snapshot.data ?? [];

          // Eğer hiç aktif quiz yoksa, kullanıcıya bilgi ver.
          if (quizzes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Şu anda aktif quiz bulunmuyor',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Yeni quiz\'ler için sonra tekrar kontrol edin',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Quizleri bir liste halinde göster.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    quiz.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(quiz.description),
                      const SizedBox(height: 8),
                      // Soru sayısı ve süre gibi ek bilgiler.
                      Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${quiz.questionCount} soru',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quiz.timeLimit != null
                                ? '${quiz.timeLimit} dk'
                                : 'Süresiz',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Quize başlama butonu.
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizTakingScreen(quiz: quiz),
                        ),
                      );
                    },
                    child: const Text('Başla'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}