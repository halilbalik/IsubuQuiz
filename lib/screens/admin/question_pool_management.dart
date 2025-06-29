import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/question_pool.dart';
import '../../services/question_pool_service.dart';
import '../../services/gemini_service.dart';
import 'add_manual_question_page.dart';
import 'ai_question_generator_page.dart';
import 'topic_question_detail_page.dart';

class QuestionPoolManagementPage extends StatefulWidget {
  final Course course;

  const QuestionPoolManagementPage({super.key, required this.course});

  @override
  State<QuestionPoolManagementPage> createState() =>
      _QuestionPoolManagementPageState();
}

class _QuestionPoolManagementPageState extends State<QuestionPoolManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTopic;
  QuestionDifficulty? _selectedDifficulty;
  QuestionSource? _selectedSource;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soru Havuzu'),
            Text(
              '${widget.course.code} - ${widget.course.title}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.quiz), text: 'Soru Havuzu'),
            Tab(icon: Icon(Icons.analytics), text: 'İstatistikler'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionPoolTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildQuestionPoolTab() {
    return FutureBuilder<List<String>>(
      future: QuestionPoolService.getCourseTopics(widget.course.id),
      builder: (context, topicsSnapshot) {
        if (topicsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (topicsSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Hata: ${topicsSnapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Yeniden Dene'),
                ),
              ],
            ),
          );
        }

        final topics = topicsSnapshot.data ?? [];

        if (topics.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return _buildTopicCard(topic);
          },
        );
      },
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
              _buildTopicFilter(),
              _buildDifficultyFilter(),
              _buildSourceFilter(),
              if (_hasActiveFilters()) _buildClearFiltersButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicFilter() {
    return FutureBuilder<List<String>>(
      future: QuestionPoolService.getCourseTopics(widget.course.id),
      builder: (context, snapshot) {
        final topics = snapshot.data ?? [];
        if (topics.isEmpty) return SizedBox.shrink();

        return DropdownButton<String>(
          value: _selectedTopic,
          hint: Text('Konu Seç'),
          items: [
            DropdownMenuItem(value: null, child: Text('Tüm Konular')),
            ...topics.map((topic) => DropdownMenuItem(
                  value: topic,
                  child: Text(topic),
                )),
          ],
          onChanged: (value) => setState(() => _selectedTopic = value),
        );
      },
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
        _selectedTopic = null;
        _selectedDifficulty = null;
        _selectedSource = null;
      }),
      icon: Icon(Icons.clear),
      label: Text('Filtreleri Temizle'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.topic,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        question.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            'Henüz soru eklenmemiş',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'İlk sorunuzu eklemek için + butonunu kullanın',
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

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: QuestionPoolService.getCourseQuestionStats(widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('İstatistik yüklenemedi: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data ?? {};
        return _buildStatisticsContent(stats);
      },
    );
  }

  Widget _buildStatisticsContent(Map<String, dynamic> stats) {
    final totalQuestions = stats['totalQuestions'] ?? 0;
    final manualQuestions = stats['manualQuestions'] ?? 0;
    final aiQuestions = stats['aiQuestions'] ?? 0;
    final topicCounts = stats['topicCounts'] as Map<String, int>? ?? {};
    final difficultyCounts =
        stats['difficultyCounts'] as Map<String, int>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Toplam Soru', totalQuestions.toString(), Icons.quiz,
              Colors.blue),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Manuel', manualQuestions.toString(),
                    Icons.edit, Colors.green),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('AI Üretimi', aiQuestions.toString(),
                    Icons.auto_awesome, Colors.purple),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text('Konu Dağılımı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...topicCounts.entries.map((entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Chip(
                    label: Text(entry.value.toString()),
                    backgroundColor: Colors.blue[50],
                  ),
                ),
              )),
          SizedBox(height: 24),
          Text('Zorluk Dağılımı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...difficultyCounts.entries.map((entry) {
            final difficulty = QuestionDifficulty.fromString(entry.key);
            return Card(
              child: ListTile(
                leading: Text(difficulty.emoji, style: TextStyle(fontSize: 24)),
                title: Text(difficulty.displayName),
                trailing: Chip(
                  label: Text(entry.value.toString()),
                  backgroundColor: Colors.orange[50],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PoolQuestion> _applyFilters(List<PoolQuestion> questions) {
    return questions.where((question) {
      if (_selectedTopic != null && question.topic != _selectedTopic)
        return false;
      if (_selectedDifficulty != null &&
          question.difficulty != _selectedDifficulty) return false;
      if (_selectedSource != null && question.source != _selectedSource)
        return false;
      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _selectedTopic != null ||
        _selectedDifficulty != null ||
        _selectedSource != null;
  }

  void _addManualQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddManualQuestionPage(course: widget.course),
      ),
    );
  }

  void _generateAIQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIQuestionGeneratorPage(course: widget.course),
      ),
    );
  }

  Widget _buildTopicCard(String topic) {
    return FutureBuilder<List<PoolQuestion>>(
      future: QuestionPoolService.getQuestionsByTopic(widget.course.id, topic)
          .first,
      builder: (context, snapshot) {
        final questions = snapshot.data ?? [];
        final questionCount = questions.length;
        final aiCount =
            questions.where((q) => q.source == QuestionSource.ai).length;
        final manualCount =
            questions.where((q) => q.source == QuestionSource.manual).length;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.folder, color: Colors.blue[700]),
            ),
            title: Text(
              topic,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('$questionCount soru'),
                SizedBox(height: 2),
                Row(
                  children: [
                    if (manualCount > 0) Text('👤 $manualCount'),
                    if (manualCount > 0 && aiCount > 0) Text(' • '),
                    if (aiCount > 0) Text('🤖 $aiCount'),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$questionCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, color: Colors.blue[700]),
              ],
            ),
            onTap: () => _openTopicDetail(topic),
          ),
        );
      },
    );
  }

  void _openTopicDetail(String topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicQuestionDetailPage(
          course: widget.course,
          topic: topic,
        ),
      ),
    );
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
          SnackBar(content: Text('Soru silindi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soru silinirken hata oluştu: $e')),
        );
      }
    }
  }
}
