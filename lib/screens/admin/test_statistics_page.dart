import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/test.dart';
import 'user_detail_page.dart';

class TestStatisticsPage extends StatelessWidget {
  final Test test;

  const TestStatisticsPage({
    super.key,
    required this.test,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          '${test.title} - İstatistikler',
          style: const TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('test_results')
            .where('testId', isEqualTo: test.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data?.docs ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Bu test henüz çözülmemiş',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // İstatistikleri hesapla
          final scores = results
              .map(
                  (doc) => (doc.data() as Map<String, dynamic>)['score'] as num)
              .toList();

          final double average = scores.isNotEmpty
              ? scores.reduce((a, b) => a + b) / scores.length
              : 0;
          final double highest = scores.isNotEmpty
              ? scores.reduce((a, b) => a > b ? a : b).toDouble()
              : 0;
          final double lowest = scores.isNotEmpty
              ? scores.reduce((a, b) => a < b ? a : b).toDouble()
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel İstatistikler
                _buildStatisticsCards(
                  participantCount: results.length,
                  average: average,
                  highest: highest,
                  lowest: lowest,
                ),
                const SizedBox(height: 24),

                // Puan Dağılımı Grafiği
                _buildScoreDistributionChart(scores),
                const SizedBox(height: 24),

                // Soru Başarı Oranları Grafiği
                _buildQuestionSuccessChart(results),
                const SizedBox(height: 24),

                // Soru Bazlı Analiz
                _buildQuestionAnalysis(results),
                const SizedBox(height: 24),

                // Detaylı Sonuçlar Listesi
                _buildDetailedResultsList(results),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards({
    required int participantCount,
    required double average,
    required double highest,
    required double lowest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genel İstatistikler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A6EA5),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Katılımcı',
                value: participantCount.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Ortalama',
                value: average.toStringAsFixed(1),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'En Yüksek',
                value: highest.toStringAsFixed(1),
                icon: Icons.emoji_events,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'En Düşük',
                value: lowest.toStringAsFixed(1),
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart(List<num> scores) {
    // Puan aralıklarını hesapla (0-20, 21-40, 41-60, 61-80, 81-100)
    final Map<String, int> distribution = {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };

    for (final score in scores) {
      if (score <= 20) {
        distribution['0-20'] = distribution['0-20']! + 1;
      } else if (score <= 40) {
        distribution['21-40'] = distribution['21-40']! + 1;
      } else if (score <= 60) {
        distribution['41-60'] = distribution['41-60']! + 1;
      } else if (score <= 80) {
        distribution['61-80'] = distribution['61-80']! + 1;
      } else {
        distribution['81-100'] = distribution['81-100']! + 1;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puan Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A6EA5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: distribution.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() +
                      1,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final key = distribution.keys.elementAt(group.x);
                        return BarTooltipItem(
                          '$key\n${rod.toY.round()} kişi',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < distribution.keys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                distribution.keys.elementAt(index),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: distribution.entries.map((entry) {
                    final index = distribution.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: const Color(0xFF3A6EA5),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSuccessChart(List<QueryDocumentSnapshot> results) {
    if (results.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Soru Başarı Oranları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A6EA5),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Henüz test sonucu bulunmuyor',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Soru başarı oranlarını hesapla
    final questionSuccessRates = <double>[];
    final totalQuestions = test.questions.length;

    for (int i = 0; i < totalQuestions; i++) {
      int correctCount = 0;
      int totalCount = 0;

      for (final result in results) {
        final data = result.data() as Map<String, dynamic>;
        final userAnswers = List<int>.from(data['userAnswers'] ?? []);

        if (i < userAnswers.length) {
          totalCount++;
          if (userAnswers[i] == test.questions[i].correctAnswerIndex) {
            correctCount++;
          }
        }
      }

      final successRate =
          totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;
      questionSuccessRates.add(successRate);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soru Başarı Oranları (%)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A6EA5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her sorunun tüm öğrenciler tarafından doğru cevaplanma oranı',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Soru ${group.x + 1}\n${rod.toY.toStringAsFixed(1)}% başarı',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final questionIndex = value.toInt();
                          if (questionIndex >= 0 &&
                              questionIndex < totalQuestions) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'S${questionIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: questionSuccessRates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final successRate = entry.value;

                    // Başarı oranına göre renk belirle
                    Color barColor;
                    if (successRate >= 80) {
                      barColor = Colors.green;
                    } else if (successRate >= 60) {
                      barColor = Colors.orange;
                    } else if (successRate >= 40) {
                      barColor = Colors.amber;
                    } else {
                      barColor = Colors.red;
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: successRate,
                          color: barColor,
                          width: totalQuestions > 10 ? 12 : 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              barColor,
                              barColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Renk açıklaması
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Çok Kolay (80%+)', Colors.green),
                _buildLegendItem('Kolay (60-79%)', Colors.orange),
                _buildLegendItem('Orta (40-59%)', Colors.amber),
                _buildLegendItem('Zor (40%>)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedResultsList(List<QueryDocumentSnapshot> results) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detaylı Sonuçlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A6EA5),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length > 10 ? 10 : results.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final resultData =
                    results[index].data() as Map<String, dynamic>;
                final score = (resultData['score'] as num).toDouble();
                final completedAt =
                    (resultData['completedAt'] as Timestamp?)?.toDate();
                final userId = resultData['userId'] as String?;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    final userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    final userEmail =
                        userData?['email'] as String? ?? 'Bilinmeyen Kullanıcı';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                userId: userId,
                                userEmail: userEmail,
                                isAdmin: userData?['isAdmin'] ?? false,
                              ),
                            ),
                          );
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: _getScoreColor(score).withOpacity(0.1),
                        child: Text(
                          score.toStringAsFixed(0),
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        userEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: completedAt != null
                          ? Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(completedAt),
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(1)} puan',
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (results.length > 10) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Ve ${results.length - 10} sonuç daha...',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalysis(List<QueryDocumentSnapshot> results) {
    if (results.isEmpty) return const SizedBox.shrink();

    // Soru analizi için veri hazırlama
    final questionStats = <int, Map<String, int>>{};
    final totalQuestions = test.questions.length;

    // Her test sonucu için soru bazlı analiz
    for (final result in results) {
      final data = result.data() as Map<String, dynamic>;
      final userAnswers = List<int>.from(data['userAnswers'] ?? []);

      for (int i = 0; i < userAnswers.length && i < totalQuestions; i++) {
        if (!questionStats.containsKey(i)) {
          questionStats[i] = {'correct': 0, 'wrong': 0, 'total': 0};
        }

        final isCorrect =
            userAnswers[i] == test.questions[i].correctAnswerIndex;
        questionStats[i]!['total'] = questionStats[i]!['total']! + 1;

        if (isCorrect) {
          questionStats[i]!['correct'] = questionStats[i]!['correct']! + 1;
        } else {
          questionStats[i]!['wrong'] = questionStats[i]!['wrong']! + 1;
        }
      }
    }

    // En çok doğru ve yanlış yapılan soruları bul
    int mostCorrectQuestion = 0;
    int mostWrongQuestion = 0;
    double highestCorrectRate = 0;
    double highestWrongRate = 0;

    for (final entry in questionStats.entries) {
      final questionIndex = entry.key;
      final stats = entry.value;
      final total = stats['total']!;

      if (total > 0) {
        final correctRate = stats['correct']! / total;
        final wrongRate = stats['wrong']! / total;

        if (correctRate > highestCorrectRate) {
          highestCorrectRate = correctRate;
          mostCorrectQuestion = questionIndex;
        }

        if (wrongRate > highestWrongRate) {
          highestWrongRate = wrongRate;
          mostWrongQuestion = questionIndex;
        }
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soru Bazlı Analiz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A6EA5),
              ),
            ),
            const SizedBox(height: 16),

            // Özet Kartları
            Row(
              children: [
                Expanded(
                  child: _buildQuestionSummaryCard(
                    'En Kolay Soru',
                    'Soru ${mostCorrectQuestion + 1}',
                    '${(highestCorrectRate * 100).toStringAsFixed(1)}% doğru',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuestionSummaryCard(
                    'En Zor Soru',
                    'Soru ${mostWrongQuestion + 1}',
                    '${(highestWrongRate * 100).toStringAsFixed(1)}% yanlış',
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detaylı Soru Listesi
            const Text(
              'Soru Detayları',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A6EA5),
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questionStats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final stats = questionStats[index];
                if (stats == null) return const SizedBox.shrink();

                final total = stats['total']!;
                final correct = stats['correct']!;
                final wrong = stats['wrong']!;
                final correctRate = total > 0 ? (correct / total) : 0.0;

                return _buildQuestionStatCard(
                  questionIndex: index,
                  questionText: test.questions[index].text,
                  correct: correct,
                  wrong: wrong,
                  total: total,
                  correctRate: correctRate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSummaryCard(
    String title,
    String subtitle,
    String detail,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStatCard({
    required int questionIndex,
    required String questionText,
    required int correct,
    required int wrong,
    required int total,
    required double correctRate,
  }) {
    Color getRateColor(double rate) {
      if (rate >= 0.8) return Colors.green;
      if (rate >= 0.6) return Colors.orange;
      if (rate >= 0.4) return Colors.amber;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A6EA5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Soru ${questionIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getRateColor(correctRate).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: getRateColor(correctRate).withOpacity(0.3)),
                ),
                child: Text(
                  '${(correctRate * 100).toStringAsFixed(1)}% başarı',
                  style: TextStyle(
                    color: getRateColor(correctRate),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Doğru: $correct',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Yanlış: $wrong',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
              Text(
                'Toplam: $total',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }
}
