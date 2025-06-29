import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'test_result_detail_page.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;
  final String userEmail;
  final bool isAdmin;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userEmail),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF3A6EA5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('test_results')
            .where('userId', isEqualTo: userId)
            .orderBy('testId')
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Test sonuçları hatası: ${snapshot.error}');
            return Center(child: Text('Bir hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data?.docs ?? [];

          // Aktif testleri kontrol et
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tests').snapshots(),
            builder: (context, testsSnapshot) {
              if (testsSnapshot.hasError) {
                return const Center(child: Text('Bir hata oluştu'));
              }

              if (testsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Test verilerini bir Map'te tut
              final testData = {
                for (var doc in testsSnapshot.data?.docs ?? [])
                  doc.id: doc.data() as Map<String, dynamic>
              };

              // Sadece aktif testlerin sonuçlarını filtrele
              final activeResults = results.where((doc) {
                final resultData = doc.data() as Map<String, dynamic>;
                final testId = resultData['testId'] as String;
                return testData.containsKey(testId);
              }).toList();

              if (results.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz test çözülmemiş',
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
              final totalTests = activeResults.length;
              final averageScore = totalTests > 0
                  ? activeResults
                          .map((doc) => (doc.data()
                              as Map<String, dynamic>)['score'] as num)
                          .reduce((a, b) => a + b) /
                      totalTests
                  : 0.0;

              return Column(
                children: [
                  // İstatistik Kartları
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Toplam Test',
                            totalTests.toString(),
                            Icons.assignment,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Ortalama Puan',
                            averageScore.toStringAsFixed(1),
                            Icons.star,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Test Sonuçları Listesi
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeResults.length,
                      itemBuilder: (context, index) {
                        final resultData =
                            activeResults[index].data() as Map<String, dynamic>;
                        final testId = resultData['testId'] as String;
                        final testTitle =
                            testData[testId]?['title'] as String? ??
                                'İsimsiz Test';
                        final score = resultData['score'] ?? 0.0;
                        final submissionType =
                            resultData['submissionType'] as String?;
                        final timeSpent = resultData['timeSpent'] ?? 0;
                        final totalTime = testData[testId]?['duration'] ?? 0;
                        final remainingTime = resultData['remainingTime'] ?? 0;
                        final correctCount = resultData['correctCount'] ?? 0;
                        final totalQuestions =
                            resultData['totalQuestions'] ?? 0;
                        final completedAt =
                            resultData['completedAt'] as Timestamp?;

                        String getSubmissionTypeText(String? type) {
                          switch (type) {
                            case 'timeout':
                              return 'Süre Doldu';
                            case 'manual':
                              return 'Manuel Tamamlandı';
                            case 'auto':
                              return 'Otomatik Gönderildi';
                            default:
                              return 'Belirsiz';
                          }
                        }

                        Color getSubmissionTypeColor(String? type) {
                          switch (type) {
                            case 'timeout':
                              return Colors.orange;
                            case 'manual':
                              return Colors.green;
                            case 'auto':
                              return Colors.blue;
                            default:
                              return Colors.grey;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: score >= 70
                                  ? Colors.green.shade200
                                  : score >= 50
                                      ? Colors.orange.shade200
                                      : Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: _buildTestIcon(score),
                            title: Text(
                              testTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Doğru: $correctCount/$totalQuestions',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kullanılan: $timeSpent dk / Toplam: $totalTime dk',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      submissionType == 'timeout'
                                          ? Icons.timer_off_outlined
                                          : submissionType == 'manual'
                                              ? Icons.done_all
                                              : Icons.auto_mode,
                                      size: 16,
                                      color: getSubmissionTypeColor(
                                          submissionType),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      getSubmissionTypeText(submissionType),
                                      style: TextStyle(
                                        color: getSubmissionTypeColor(
                                            submissionType),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (completedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(completedAt),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: score >= 70
                                        ? Colors.green.shade100
                                        : score >= 50
                                            ? Colors.orange.shade100
                                            : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Puan: ${score.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: score >= 70
                                          ? Colors.green.shade700
                                          : score >= 50
                                              ? Colors.orange.shade700
                                              : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF3A6EA5),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestResultDetailPage(
                                    testId: testId,
                                    userId: userId,
                                    resultData: resultData,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3A6EA5),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A6EA5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestIcon(double score) {
    if (score >= 85) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.emoji_events,
          color: Colors.green,
          size: 24,
        ),
      );
    } else if (score >= 70) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.star,
          color: Colors.blue,
          size: 24,
        ),
      );
    } else if (score >= 50) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.trending_up,
          color: Colors.orange,
          size: 24,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_rounded,
          color: Colors.red,
          size: 24,
        ),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }
}
