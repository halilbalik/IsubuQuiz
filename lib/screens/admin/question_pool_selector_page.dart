import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/question.dart';
import '../../models/question_pool.dart';
import '../../services/question_pool_service.dart';

class QuestionPoolSelectorPage extends StatefulWidget {
  final Course course;

  const QuestionPoolSelectorPage({super.key, required this.course});

  @override
  State<QuestionPoolSelectorPage> createState() =>
      _QuestionPoolSelectorPageState();
}

class _QuestionPoolSelectorPageState extends State<QuestionPoolSelectorPage> {
  final Set<String> _selectedQuestionIds = {};
  final Set<String> _expandedTopics = {};
  Map<String, List<PoolQuestion>> _questionsByTopic = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soru Havuzundan Seç'),
            Text(
              widget.course.title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (_selectedQuestionIds.isNotEmpty)
            TextButton(
              onPressed: _addSelectedQuestions,
              child: Text(
                'Ekle (${_selectedQuestionIds.length})',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<PoolQuestion>>(
        stream: QuestionPoolService.getCourseQuestions(widget.course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                ],
              ),
            );
          }

          final allQuestions = snapshot.data ?? [];

          if (allQuestions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bu derste henüz soru bulunmuyor'),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }

          // Soruları konulara göre grupla
          _questionsByTopic = {};
          for (final question in allQuestions) {
            if (!_questionsByTopic.containsKey(question.topic)) {
              _questionsByTopic[question.topic] = [];
            }
            _questionsByTopic[question.topic]!.add(question);
          }

          final topics = _questionsByTopic.keys.toList()..sort();

          return Column(
            children: [
              // Toplu seçim butonları
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Text('Toplu İşlemler:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: _expandAllTopics,
                      icon: Icon(Icons.expand_more, size: 18),
                      label: Text('Tümünü Aç'),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8)),
                    ),
                    TextButton.icon(
                      onPressed: _collapseAllTopics,
                      icon: Icon(Icons.expand_less, size: 18),
                      label: Text('Tümünü Kapat'),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8)),
                    ),
                    Spacer(),
                    if (_selectedQuestionIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _selectedQuestionIds.clear()),
                        icon: Icon(Icons.clear, size: 18, color: Colors.red),
                        label: Text('Temizle',
                            style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8)),
                      ),
                  ],
                ),
              ),
              // Konular listesi
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final questions = _questionsByTopic[topic]!;
                    return _buildTopicSection(topic, questions);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopicSection(String topic, List<PoolQuestion> questions) {
    final isExpanded = _expandedTopics.contains(topic);
    final selectedInTopic =
        questions.where((q) => _selectedQuestionIds.contains(q.id)).length;
    final totalInTopic = questions.length;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Konu başlığı
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(
                isExpanded ? Icons.folder_open : Icons.folder,
                color: Colors.blue[700],
              ),
            ),
            title: Text(
              topic,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Text('$totalInTopic soru'),
                if (selectedInTopic > 0) ...[
                  Text(' • '),
                  Text(
                    '$selectedInTopic seçili',
                    style: TextStyle(
                        color: Colors.blue[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalInTopic > 0)
                  TextButton(
                    onPressed: () => _toggleTopicSelection(topic, questions),
                    child: Text(
                      selectedInTopic == totalInTopic
                          ? 'Hiçbirini Seçme'
                          : 'Tümünü Seç',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => _toggleTopicExpansion(topic),
          ),
          // Sorular
          if (isExpanded)
            ...questions.map((question) => _buildQuestionCard(question)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PoolQuestion question) {
    final isSelected = _selectedQuestionIds.contains(question.id);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
        ),
      ),
      child: CheckboxListTile(
        dense: true,
        value: isSelected,
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedQuestionIds.add(question.id);
            } else {
              _selectedQuestionIds.remove(question.id);
            }
          });
        },
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.text,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                Text('${question.difficulty.emoji}'),
                SizedBox(width: 4),
                Text('${question.source.emoji}'),
              ],
            ),
            SizedBox(height: 8),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isCorrect = index == question.correctAnswerIndex;

              return Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    if (isCorrect)
                      Icon(Icons.check, color: Colors.green, size: 16),
                    if (isCorrect) SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isCorrect ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _toggleTopicExpansion(String topic) {
    setState(() {
      if (_expandedTopics.contains(topic)) {
        _expandedTopics.remove(topic);
      } else {
        _expandedTopics.add(topic);
      }
    });
  }

  void _toggleTopicSelection(String topic, List<PoolQuestion> questions) {
    setState(() {
      final questionIds = questions.map((q) => q.id).toSet();
      final allSelected =
          questionIds.every((id) => _selectedQuestionIds.contains(id));

      if (allSelected) {
        // Tümünü kaldır
        _selectedQuestionIds.removeAll(questionIds);
      } else {
        // Tümünü ekle
        _selectedQuestionIds.addAll(questionIds);
      }
    });
  }

  void _expandAllTopics() {
    setState(() {
      _expandedTopics.addAll(_questionsByTopic.keys);
    });
  }

  void _collapseAllTopics() {
    setState(() {
      _expandedTopics.clear();
    });
  }

  void _addSelectedQuestions() {
    final selectedQuestions = <Question>[];
    final selectedIds = <String>[];

    for (final questions in _questionsByTopic.values) {
      for (final question in questions) {
        if (_selectedQuestionIds.contains(question.id)) {
          selectedQuestions.add(question.toQuestion());
          selectedIds.add(question.id);
        }
      }
    }

    if (selectedQuestions.isNotEmpty) {
      // Question listesi ve ID listesini birlikte döndür
      Navigator.pop(context, {
        'questions': selectedQuestions,
        'questionIds': selectedIds,
      });
    }
  }
}
