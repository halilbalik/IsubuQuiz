import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/question_pool.dart';
import '../../services/question_pool_service.dart';

class AddManualQuestionPage extends StatefulWidget {
  final Course course;
  final String? defaultTopic;

  const AddManualQuestionPage({
    super.key,
    required this.course,
    this.defaultTopic,
  });

  @override
  State<AddManualQuestionPage> createState() => _AddManualQuestionPageState();
}

class _AddManualQuestionPageState extends State<AddManualQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _tagsController = TextEditingController();

  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;
  int _correctAnswerIndex = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manuel Soru Ekle'),
            Text(
              widget.course.title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Konu
            TextFormField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Konu Başlığı',
                hintText: 'Örn: Algoritma Temelleri',
                prefixIcon: Icon(Icons.topic),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Konu başlığı gerekli';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Zorluk Seviyesi
            DropdownButtonFormField<QuestionDifficulty>(
              value: _selectedDifficulty,
              decoration: InputDecoration(
                labelText: 'Zorluk Seviyesi',
                prefixIcon: Icon(Icons.speed),
              ),
              items: QuestionDifficulty.values.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text('${difficulty.emoji} ${difficulty.displayName}'),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedDifficulty = value!),
            ),
            SizedBox(height: 16),

            // Soru Metni
            TextFormField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Soru Metni',
                hintText: 'Sorunuzu buraya yazın...',
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Soru metni gerekli';
                }
                return null;
              },
            ),
            SizedBox(height: 24),

            // Seçenekler
            Text(
              'Cevap Seçenekleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            _buildOptionField('A', _option1Controller, 0),
            _buildOptionField('B', _option2Controller, 1),
            _buildOptionField('C', _option3Controller, 2),
            _buildOptionField('D', _option4Controller, 3),

            SizedBox(height: 16),

            // Etiketler
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Etiketler (isteğe bağlı)',
                hintText: 'algoritma, döngü, veri yapısı (virgülle ayırın)',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            SizedBox(height: 32),

            // Kaydet Butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _saveQuestion,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Soruyu Kaydet', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionField(
      String letter, TextEditingController controller, int index) {
    final isCorrect = _correctAnswerIndex == index;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: _correctAnswerIndex,
            onChanged: (value) => setState(() => _correctAnswerIndex = value!),
          ),
          Text(
            letter,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : null,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Seçenek $letter',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: isCorrect ? Colors.green[50] : null,
                filled: isCorrect,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Seçenek $letter gerekli';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await QuestionPoolService.addQuestion(
        courseId: widget.course.id,
        topic: _topicController.text.trim(),
        text: _questionController.text.trim(),
        options: [
          _option1Controller.text.trim(),
          _option2Controller.text.trim(),
          _option3Controller.text.trim(),
          _option4Controller.text.trim(),
        ],
        correctAnswerIndex: _correctAnswerIndex,
        difficulty: _selectedDifficulty,
        tags: tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Soru başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
