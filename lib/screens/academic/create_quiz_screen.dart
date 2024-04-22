import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../services/ai_service.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import 'question_detail_dialog.dart';

// Yeni quiz oluşturma ekranı. Bayağı karışık bir ekran.
class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  // Bütün text alanları için birer controller.
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _topicController = TextEditingController();

  // Servisleri çağırıyoruz.
  final AuthService _authService = AuthService();
  final QuizService _quizService = QuizService();
  final AIService _aiService = AIService();

  final List<Question> _questions = []; // Oluşturulan sorular bu listede tutuluyor. 
  bool _isLoading = false; // Quiz kaydediliyor mu?
  bool _isGeneratingQuestions = false; // AI soru üretiyor mu?
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium; // Varsayılan zorluk.
  int _questionCount = 5; // Varsayılan soru sayısı.

  @override
  void dispose() {
    // Ekran kapanırken controller'ları temizle.
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // Yapay zeka ile soru üretme metodu.
  Future<void> _generateQuestionsWithAI() async {
    // Konu başlığı boşsa uyarı ver.
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen konu başlığı girin')),
      );
      return;
    }

    setState(() {
      _isGeneratingQuestions = true; // Soru üretimi başladı.
    });

    try {
      // AI servisinden soruları istiyoruz.
      final questions = await _aiService.generateQuestions(
        topic: _topicController.text.trim(),
        count: _questionCount,
        difficulty: _selectedDifficulty,
      );

      // Gelen soruları listeye ekliyoruz.
      setState(() {
        _questions.addAll(questions);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${questions.length} soru başarıyla üretildi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soru üretimi hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQuestions = false; // Soru üretimi bitti.
        });
      }
    }
  }

  // Quizi Firebase'e kaydetme metodu.
  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Hiç soru yoksa uyarı ver.
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 1 soru eklemelisiniz')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Kaydetme başladı.
    });

    try {
      final user = await _authService.getCurrentUserData();
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Quiz objesini oluşturuyoruz.
      final quiz = Quiz(
        id: '', // ID'yi Firebase kendi verecek.
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        academicId: user.id,
        questions: _questions,
        createdAt: DateTime.now(),
        timeLimit: _timeLimitController.text.isNotEmpty
            ? int.tryParse(_timeLimitController.text)
            : null,
      );

      // Quiz servisi ile Firebase'e yazdırıyoruz.
      await _quizService.createQuiz(quiz);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz başarıyla oluşturuldu!')),
        );
        Navigator.pop(context); // Bir önceki ekrana dön.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz oluşturma hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Kaydetme bitti.
        });
      }
    }
  }

  // Manuel olarak soru eklemek için dialog açan metot.
  void _addManualQuestion() {
    showDialog(
      context: context,
      builder: (context) => QuestionDetailDialog(
        questionIndex: _questions.length,
        onSave: (question) {
          setState(() {
            _questions.add(question); // Kaydedilen soruyu listeye ekle.
          });
        },
      ),
    );
  }

  // Mevcut bir soruyu düzenlemek için dialog açan metot.
  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => QuestionDetailDialog(
        question: _questions[index],
        questionIndex: index,
        onSave: (question) {
          setState(() {
            _questions[index] = question; // Listede o indexteki soruyu güncelle.
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Quiz Oluştur'),
        actions: [
          // Kaydet butonu.
          TextButton(
            onPressed: _isLoading ? null : _saveQuiz,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quiz bilgileri kartı.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Başlığı',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quiz başlığı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Açıklama gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeLimitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Süre Limiti (dakika) - İsteğe bağlı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI ile soru üretme kartı.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI ile Soru Üret',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Konu Başlığı',
                        hintText: 'Örn: Flutter Widget\'ları, Matematik, Tarih',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Zorluk seçimi dropdown.
                        Expanded(
                          child: DropdownButtonFormField<QuestionDifficulty>(
                            value: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Zorluk',
                              border: OutlineInputBorder(),
                            ),
                            items: QuestionDifficulty.values.map((difficulty) {
                              return DropdownMenuItem(
                                value: difficulty,
                                child: Text(difficulty.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDifficulty = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Soru sayısı seçimi dropdown.
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _questionCount,
                            decoration: const InputDecoration(
                              labelText: 'Soru Sayısı',
                              border: OutlineInputBorder(),
                            ),
                            items: [3, 5, 10, 15, 20].map((count) {
                              return DropdownMenuItem(
                                value: count,
                                child: Text('$count soru'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _questionCount = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Soru üret butonu.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingQuestions
                            ? null
                            : _generateQuestionsWithAI,
                        icon: _isGeneratingQuestions
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isGeneratingQuestions
                              ? 'Sorular üretiliyor...'
                              : 'AI ile Soru Üret',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Soruların listelendiği kart.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sorular',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_questions.length} soru',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Manuel soru ekleme butonu.
                        IconButton(
                          onPressed: _addManualQuestion,
                          icon: const Icon(Icons.add),
                          tooltip: 'Manuel Soru Ekle',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Hiç soru yoksa gösterilecek alan.
                    if (_questions.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Henüz soru eklenmedi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'AI ile soru üretebilir veya manuel olarak ekleyebilirsiniz',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addManualQuestion,
                              icon: const Icon(Icons.add),
                              label: const Text('Manuel Soru Ekle'),
                            ),
                          ],
                        ),
                      )
                    else
                      // Soruları listele.
                      ...List.generate(_questions.length, (index) {
                        final question = _questions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _editQuestion(index), // Tıklayınca düzenle.
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Soru başlığı ve butonlar.
                                  Row(
                                    children: [
                                      // Soru numarası.
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // AI tarafından üretildiyse etiketi.
                                                if (question.isAIGenerated)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .purple.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'AI',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors
                                                            .purple.shade700,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                // Zorluk seviyesi.
                                                Text(
                                                  question
                                                      .difficulty.displayName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Düzenle ve Sil butonları.
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                            onPressed: () =>
                                                _editQuestion(index),
                                            tooltip: 'Düzenle',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _questions.removeAt(index);
                                              });
                                            },
                                            tooltip: 'Sil',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Soru metni.
                                  Text(
                                    question.questionText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Şıkları listele.
                                  ...List.generate(question.options.length,
                                      (optionIndex) {
                                    final isCorrect =
                                        optionIndex == question.correctAnswer;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isCorrect
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              ['A', 'B', 'C', 'D'][optionIndex],
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCorrect
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              question.options[optionIndex],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isCorrect
                                                    ? Colors.green.shade700
                                                    : Colors.black87,
                                                fontWeight: isCorrect
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isCorrect)
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade600,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // Açıklama varsa göster.
                                  if (question.explanation != null &&
                                      question.explanation!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue.shade600,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              question.explanation!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),
                                  // Küçük bir ipucu.
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      'Düzenlemek için tıklayın',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Altta boşluk kalsın diye.
          ],
        ),
      ),
      // Kaydet butonu, ama bu sefer ekranın altında duran cinsten.
      floatingActionButton: _questions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveQuiz,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Kaydediliyor...' : 'Quiz\'i Kaydet'),
            )
          : null,
    );
  }
}