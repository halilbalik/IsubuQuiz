import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'test_list_page.dart';

class TestResultPage extends StatelessWidget {
  final String testId;
  final String testTitle;
  final Map<String, dynamic> userResult;

  const TestResultPage({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.userResult,
  });

  Widget _buildResultRow(String label, String value,
      {Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: color ?? const Color(0xFF3A6EA5)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF3A6EA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResult(
      Map<String, dynamic> question, int userAnswer, BuildContext context) {
    final correctAnswer = question['correctAnswerIndex'] as int;
    final isCorrect = userAnswer == correctAnswer;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['text'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (question['imageUrl'] != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(question['imageUrl'].split(',')[1]),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...List.generate(
              (question['options'] as List).length,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getOptionColor(index, correctAnswer, userAnswer),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF3A6EA5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A6EA5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question['options'][index],
                        style: TextStyle(
                          color: _getOptionColor(
                                      index, correctAnswer, userAnswer) ==
                                  Colors.white
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (index == correctAnswer)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else if (index == userAnswer && userAnswer != correctAnswer)
                      const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOptionColor(int optionIndex, int correctAnswer, int userAnswer) {
    if (optionIndex == correctAnswer) {
      return Colors.green.shade100;
    } else if (optionIndex == userAnswer && userAnswer != correctAnswer) {
      return Colors.red.shade100;
    }
    return Colors.white;
  }

  String _getSubmissionTypeText(String type) {
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

  Color _getSubmissionTypeColor(String type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Test Sonucu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestListPage(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, color: Color(0xFF3A6EA5)),
            label: const Text(
              'Testlere Dön',
              style: TextStyle(
                color: Color(0xFF3A6EA5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('tests').doc(testId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Test bulunamadı'));
          }

          final testData = snapshot.data!.data() as Map<String, dynamic>;
          final questions =
              List<Map<String, dynamic>>.from(testData['questions']);
          final userAnswers = List<int>.from(userResult['userAnswers']);
          final totalTime = testData['duration'] ?? 0;
          final remainingTime = userResult['remainingTime'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildResultRow(
                        'Toplam Puan',
                        '${userResult['score'].toStringAsFixed(2)}',
                        color: Colors.green,
                        icon: Icons.stars_outlined,
                      ),
                      _buildResultRow(
                        'Doğru Sayısı',
                        '${userResult['correctCount']}/${userResult['totalQuestions']}',
                        color: Colors.blue,
                        icon: Icons.check_circle_outline,
                      ),
                      _buildResultRow(
                        'Toplam Süre',
                        '$totalTime dakika',
                        color: Colors.purple,
                        icon: Icons.timer_outlined,
                      ),
                      _buildResultRow(
                        'Kullanılan Süre',
                        '${userResult['timeSpent']} dakika',
                        color: Colors.blue,
                        icon: Icons.access_time,
                      ),
                      _buildResultRow(
                        'Tamamlanma',
                        _getSubmissionTypeText(userResult['submissionType']),
                        color: _getSubmissionTypeColor(userResult['submissionType']),
                        icon: userResult['submissionType'] == 'timeout'
                            ? Icons.timer_off_outlined
                            : userResult['submissionType'] == 'manual'
                                ? Icons.done_all
                                : Icons.auto_mode,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Soru Detayları',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A6EA5),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                questions.length,
                (index) => _buildQuestionResult(
                  questions[index],
                  userAnswers[index],
                  context,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
