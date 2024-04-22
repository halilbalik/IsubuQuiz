import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz.dart';
import 'create_quiz_screen.dart';

// Akademisyenin oluşturduğu quizleri listelediği ekran.
class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();
  String? _currentUserId; // Mevcut akademisyenin ID'si. 

  @override
  void initState() {
    super.initState();
    // Ekran açılınca kullanıcı ID'sini al.
    _getCurrentUser();
  }

  // Mevcut kullanıcının ID'sini alan metot.
  Future<void> _getCurrentUser() async {
    final user = await _authService.getCurrentUserData();
    setState(() {
      _currentUserId = user?.id;
    });
  }

  // Bir quizin aktif/pasif durumunu değiştiren metot.
  Future<void> _toggleQuizStatus(Quiz quiz) async {
    try {
      // Quiz'in kopyasını oluşturup sadece isActive durumunu tersine çeviriyoruz.
      final updatedQuiz = quiz.copyWith(isActive: !quiz.isActive);
      await _quizService.updateQuiz(updatedQuiz);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quiz.isActive
                ? 'Quiz pasif hale getirildi'
                : 'Quiz aktif hale getirildi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  // Bir quizi silen metot.
  Future<void> _deleteQuiz(Quiz quiz) async {
    // Silmeden önce emin misin diye soruyoruz.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz\'i Sil'),
        content: Text(
            '${quiz.title} adlı quiz\'i silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    // Eğer evet dediyse siliyoruz.
    if (confirmed == true) {
      try {
        await _quizService.deleteQuiz(quiz.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz başarıyla silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz\'lerim'),
        actions: [
          // Yeni quiz ekleme butonu.
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateQuizScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // Kullanıcı ID'si yüklenene kadar bekleme göstergesi.
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          // StreamBuilder ile quizleri anlık olarak dinliyoruz.
          : StreamBuilder<List<Quiz>>(
              stream: _quizService.getAcademicQuizzes(_currentUserId!),
              builder: (context, snapshot) {
                // Veri geliyorsa bekleme göstergesi.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Hata varsa, özellikle Firebase index hatasıysa, konsola link basıyoruz.
                // Bu çok can sıkıcı bir hata, o yüzden böyle bir çözüm buldum.
                if (snapshot.hasError) {
                  final errorMessage = snapshot.error.toString();
                  if (errorMessage.contains('index') ||
                      errorMessage.contains('FAILED_PRECONDITION')) {
                    debugPrint(
                        '\n🚨 FIRESTORE INDEX HATASI - QUIZ\'LERIM SAYFASI');
                    debugPrint('🔗 INDEX URL (VS CODE\'DA CTRL+CLICK):');

                    final urlMatch = RegExp(
                            r'https://console\.firebase\.google\.com[^\s\)]*')
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
                          onPressed: () => setState(() {}), // Sayfayı yenilemeyi dene.
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final quizzes = snapshot.data ?? [];

                // Hiç quiz yoksa boş ekran göster.
                if (quizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz quiz oluşturmadınız',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateQuizScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('İlk Quiz\'inizi Oluşturun'),
                        ),
                      ],
                    ),
                  );
                }

                // Quizleri ListView ile listele.
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
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
                                // Soru sayısı, süre gibi bilgiler.
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
                                    const Spacer(),
                                    // Aktif/Pasif etiketi.
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Üç nokta menüsü.
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'toggle':
                                    _toggleQuizStatus(quiz);
                                    break;
                                  case 'results':
                                    // Bu özellik daha eklenmemiş.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Sonuçlar yakında gelecek!'),
                                      ),
                                    );
                                    break;
                                  case 'delete':
                                    _deleteQuiz(quiz);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        quiz.isActive
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(quiz.isActive
                                          ? 'Pasif Yap'
                                          : 'Aktif Yap'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'results',
                                  child: Row(
                                    children: [
                                      Icon(Icons.analytics, size: 20),
                                      SizedBox(width: 8),
                                      Text('Sonuçları Gör'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Sil',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Oluşturulma tarihi.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Oluşturulma: ${_formatDate(quiz.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      // Yeni quiz ekleme butonu (altta duran).
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => const CreateQuizScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Tarihi formatlayan basit bir metot.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}