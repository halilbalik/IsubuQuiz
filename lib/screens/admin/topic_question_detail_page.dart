import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/question_pool.dart';
import '../../services/question_pool_service.dart';
import 'add_manual_question_page.dart';
import 'ai_question_generator_page.dart';

class TopicQuestionDetailPage extends StatefulWidget {
  final Course course;
  final String topic;

  const TopicQuestionDetailPage({
    super.key,
    required this.course,
    required this.topic,
  });

  @override
  State<TopicQuestionDetailPage> createState() =>
      _TopicQuestionDetailPageState();
}

class _TopicQuestionDetailPageState extends State<TopicQuestionDetailPage> {
  QuestionDifficulty? _selectedDifficulty;
  QuestionSource? _selectedSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.topic),
            Text(
              widget.course.title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add),
            onSelected: (value) {
              if (value == 'manual') {
                _addManualQuestion();
              } else if (value == 'ai') {
                _generateAIQuestions();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Manuel Soru Ekle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ai',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('AI ile Soru Üret'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<PoolQuestion>>(
              stream: QuestionPoolService.getQuestionsByTopic(
                  widget.course.id, widget.topic),
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
                final filteredQuestions = _applyFilters(allQuestions);

                if (filteredQuestions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredQuestions.length,
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return _buildQuestionCard(question);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtreler', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDifficultyFilter(),
              _buildSourceFilter(),
              if (_hasActiveFilters()) _buildClearFiltersButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return DropdownButton<QuestionDifficulty>(
      value: _selectedDifficulty,
      hint: Text('Zorluk Seç'),
      items: [
        DropdownMenuItem(value: null, child: Text('Tüm Zorluklar')),
        ...QuestionDifficulty.values.map((difficulty) => DropdownMenuItem(
              value: difficulty,
              child: Text('${difficulty.emoji} ${difficulty.displayName}'),
            )),
      ],
      onChanged: (value) => setState(() => _selectedDifficulty = value),
    );
  }

  Widget _buildSourceFilter() {
    return DropdownButton<QuestionSource>(
      value: _selectedSource,
      hint: Text('Kaynak Seç'),
      items: [
        DropdownMenuItem(value: null, child: Text('Tüm Kaynaklar')),
        ...QuestionSource.values.map((source) => DropdownMenuItem(
              value: source,
              child: Text('${source.emoji} ${source.displayName}'),
            )),
      ],
      onChanged: (value) => setState(() => _selectedSource = value),
    );
  }

  Widget _buildClearFiltersButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() {
        _selectedDifficulty = null;
        _selectedSource = null;
      }),
      icon: Icon(Icons.clear),
      label: Text('Temizle'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
    );
  }

  Widget _buildQuestionCard(PoolQuestion question) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text('${question.difficulty.emoji}'),
                    SizedBox(width: 4),
                    Text('${question.source.emoji}'),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteQuestion(question);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isCorrect = index == question.correctAnswerIndex;

              return Container(
                margin: EdgeInsets.only(bottom: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[50] : Colors.grey[50],
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isCorrect)
                      Icon(Icons.check, color: Colors.green, size: 18),
                    if (isCorrect) SizedBox(width: 8),
                    Expanded(child: Text(option)),
                  ],
                ),
              );
            }),
            if (question.tags.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: question.tags
                    .map((tag) => Chip(
                          label: Text(tag, style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.blue[50],
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Kullanım: ${question.usageCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 16),
                Text(
                  'Başarı: %${(question.avgPerformance * 100).toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  '${question.createdAt.day}/${question.createdAt.month}/${question.createdAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bu konuda henüz soru yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            '${widget.topic} konusuna soru ekleyin',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _addManualQuestion,
                icon: Icon(Icons.edit),
                label: Text('Manuel Ekle'),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _generateAIQuestions,
                icon: Icon(Icons.auto_awesome),
                label: Text('AI ile Üret'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PoolQuestion> _applyFilters(List<PoolQuestion> questions) {
    return questions.where((question) {
      if (_selectedDifficulty != null &&
          question.difficulty != _selectedDifficulty) return false;
      if (_selectedSource != null && question.source != _selectedSource)
        return false;
      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _selectedDifficulty != null || _selectedSource != null;
  }

  void _addManualQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddManualQuestionPage(
          course: widget.course,
          defaultTopic: widget.topic,
        ),
      ),
    ).then((_) {
      // Soru eklendikten sonra sayfa yenilensin
      setState(() {});
    });
  }

  void _generateAIQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIQuestionGeneratorPage(
          course: widget.course,
          defaultTopic: widget.topic,
        ),
      ),
    ).then((_) {
      // AI soru eklendikten sonra sayfa yenilensin
      setState(() {});
    });
  }

  void _deleteQuestion(PoolQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Soruyu Sil'),
        content:
            Text('Bu soruyu kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await QuestionPoolService.deleteQuestion(question.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Soru silindi'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
