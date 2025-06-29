import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/question_pool.dart';
import '../../services/question_pool_service.dart';
import '../../services/gemini_service.dart';

class AIQuestionGeneratorPage extends StatefulWidget {
  final Course course;
  final String? defaultTopic;

  const AIQuestionGeneratorPage({
    super.key,
    required this.course,
    this.defaultTopic,
  });

  @override
  State<AIQuestionGeneratorPage> createState() =>
      _AIQuestionGeneratorPageState();
}

class _AIQuestionGeneratorPageState extends State<AIQuestionGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();

  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;
  int _questionCount = 5;
  bool _isGenerating = false;
  List<String> _suggestedTopics = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultTopic != null) {
      _topicController.text = widget.defaultTopic!;
    }
    _loadTopicSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8),
                Text('AI Soru Üretici'),
              ],
            ),
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
            // AI Bilgi Kartı
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'AI ile Soru Üretimi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'AI, belirttiğiniz konuya uygun akademik sorular üretecek. '
                      'Mevcut sorularınızı analiz ederek tekrar önleyecek.',
                      style: TextStyle(color: Colors.purple[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Konu
            TextFormField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Konu Başlığı',
                hintText: 'Örn: Algoritma Temelleri, Veri Yapıları',
                prefixIcon: Icon(Icons.topic),
                suffixIcon: IconButton(
                  icon: Icon(Icons.lightbulb_outline),
                  onPressed: _showTopicSuggestions,
                  tooltip: 'Konu önerileri',
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Konu başlığı gerekli';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Konu Önerileri
            if (_suggestedTopics.isNotEmpty) ...[
              Text(
                'AI Konu Önerileri:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedTopics
                    .map((topic) => ActionChip(
                          label: Text(topic),
                          backgroundColor: Colors.blue[50],
                          onPressed: () {
                            _topicController.text = topic;
                          },
                        ))
                    .toList(),
              ),
              SizedBox(height: 16),
            ],

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

            // Soru Sayısı
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oluşturulacak Soru Sayısı: $_questionCount'),
                Slider(
                  value: _questionCount.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _questionCount.toString(),
                  onChanged: (value) =>
                      setState(() => _questionCount = value.round()),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Oluştur Butonu
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateQuestions,
              icon: _isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Sorular Üretiliyor...' : 'AI ile Soru Üret',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            if (_isGenerating) ...[
              SizedBox(height: 16),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 12),
                      Text(
                        'AI sorular üretiyor...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bu işlem 30-60 saniye sürebilir.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadTopicSuggestions() async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final suggestions = await GeminiService.suggestTopics(
        courseTitle: widget.course.title,
        courseDescription: widget.course.description,
      );

      if (mounted) {
        setState(() {
          _suggestedTopics = suggestions.take(6).toList(); // İlk 6 öneriyi al
        });
      }
    } catch (e) {
      // Hata olursa genel öneriler göster
      setState(() {
        _suggestedTopics = [
          'Temel Kavramlar',
          'Uygulama Örnekleri',
          'İleri Konular',
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  void _showTopicSuggestions() {
    if (_suggestedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konu önerileri yükleniyor...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Konu Önerileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._suggestedTopics.map((topic) => ListTile(
                  leading: Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(topic),
                  onTap: () {
                    _topicController.text = topic;
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final questionIds = await QuestionPoolService.generateAndAddQuestions(
        courseId: widget.course.id,
        courseTitle: widget.course.title,
        topic: _topicController.text.trim(),
        difficulty: _selectedDifficulty,
        questionCount: _questionCount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${questionIds.length} soru başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
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
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }
}
