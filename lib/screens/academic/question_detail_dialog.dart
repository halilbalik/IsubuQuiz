import 'package:flutter/material.dart';
import '../../models/question.dart';

// Bu widget, yeni bir soru eklemek veya mevcut bir soruyu düzenlemek için
// bir dialog (pencere) olarak açılıyor.
class QuestionDetailDialog extends StatefulWidget {
  final Question? question; // Eğer null değilse, bir soruyu düzenliyoruz demektir.
  final Function(Question) onSave; // Soru kaydedildiğinde çağrılacak fonksiyon.
  final int questionIndex; // Kaçıncı soruyu düzenlediğimizi göstermek için.

  const QuestionDetailDialog({
    super.key,
    this.question,
    required this.onSave,
    required this.questionIndex,
  });

  @override
  State<QuestionDetailDialog> createState() => _QuestionDetailDialogState();
}

class _QuestionDetailDialogState extends State<QuestionDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  // Bütün text alanları için controller'lar.
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _explanationController = TextEditingController();

  int _correctAnswer = 0; // Hangi şıkkın doğru olduğunu tutuyor (0:A, 1:B, ...).
  QuestionDifficulty _difficulty = QuestionDifficulty.medium; // Varsayılan zorluk.

  @override
  void initState() {
    super.initState();
    // Eğer bir soruyu düzenliyorsak, mevcut bilgileri controller'lara doldur.
    if (widget.question != null) {
      final q = widget.question!;
      _questionController.text = q.questionText;
      _optionAController.text = q.options.isNotEmpty ? q.options[0] : '';
      _optionBController.text = q.options.length > 1 ? q.options[1] : '';
      _optionCController.text = q.options.length > 2 ? q.options[2] : '';
      _optionDController.text = q.options.length > 3 ? q.options[3] : '';
      _explanationController.text = q.explanation ?? '';
      _correctAnswer = q.correctAnswer;
      _difficulty = q.difficulty;
    }
  }

  @override
  void dispose() {
    // Ekran kapanırken controller'ları temizle.
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  // Soruyu kaydetme metodu.
  void _saveQuestion() {
    // Form geçerli değilse (boş alan varsa falan) devam etme.
    if (!_formKey.currentState!.validate()) return;

    // Controller'lardaki bilgilerle yeni bir Question objesi oluştur.
    final question = Question(
      id: widget.question?.id ??
          'manual_${DateTime.now().millisecondsSinceEpoch}', // Yeni soruysa ID uydur.
      questionText: _questionController.text.trim(),
      options: [
        _optionAController.text.trim(),
        _optionBController.text.trim(),
        _optionCController.text.trim(),
        _optionDController.text.trim(),
      ],
      correctAnswer: _correctAnswer,
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
      difficulty: _difficulty,
      isAIGenerated: widget.question?.isAIGenerated ?? false,
    );

    // onSave callback'ini çağırarak soruyu CreateQuizScreen'e geri gönder.
    widget.onSave(question);
    Navigator.pop(context); // Dialog'u kapat.
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9, // Ekranın %90'ı kadar.
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlık ve kapatma butonu.
            Row(
              children: [
                Text(
                  widget.question != null
                      ? 'Soru Düzenle #${widget.questionIndex + 1}'
                      : 'Yeni Soru Ekle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Asıl form alanı.
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Soru metni alanı.
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Soru Metni',
                        border: OutlineInputBorder(),
                        hintText: 'Sorunuzu buraya yazın...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Soru metni gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Şıklar başlığı.
                    const Text(
                      'Cevap Şıkları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // A Şıkkı. Radio butonu ve text alanı bir arada.
                    Row(
                      children: [
                        Radio<int>(
                          value: 0,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        const Text('A) '),
                        Expanded(
                          child: TextFormField(
                            controller: _optionAController,
                            decoration: const InputDecoration(
                              hintText: 'A şıkkını yazın...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'A şıkkı gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // B Şıkkı.
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        const Text('B) '),
                        Expanded(
                          child: TextFormField(
                            controller: _optionBController,
                            decoration: const InputDecoration(
                              hintText: 'B şıkkını yazın...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'B şıkkı gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // C Şıkkı.
                    Row(
                      children: [
                        Radio<int>(
                          value: 2,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        const Text('C) '),
                        Expanded(
                          child: TextFormField(
                            controller: _optionCController,
                            decoration: const InputDecoration(
                              hintText: 'C şıkkını yazın...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'C şıkkı gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // D Şıkkı.
                    Row(
                      children: [
                        Radio<int>(
                          value: 3,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        const Text('D) '),
                        Expanded(
                          child: TextFormField(
                            controller: _optionDController,
                            decoration: const InputDecoration(
                              hintText: 'D şıkkını yazın...',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'D şıkkı gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Zorluk seviyesi dropdown.
                    DropdownButtonFormField<QuestionDifficulty>(
                      value: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Zorluk Seviyesi',
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
                          _difficulty = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Açıklama alanı (isteğe bağlı).
                    TextFormField(
                      controller: _explanationController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (İsteğe bağlı)',
                        hintText: 'Doğru cevap açıklaması...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seçilen doğru cevabı gösteren bir kutu.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Doğru Cevap: ${[
                              'A',
                              'B',
      'C',
                              'D'
                            ][_correctAnswer]} Şıkkı',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İptal ve Kaydet butonları.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveQuestion,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}