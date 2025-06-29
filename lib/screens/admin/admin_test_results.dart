import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminTestResults extends StatelessWidget {
  final String userId;
  final String userEmail;

  const AdminTestResults({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih bilgisi yok';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            userEmail + ' - Test Sonuçları',
            style: const TextStyle(
              color: Color(0xFF3A6EA5),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('test_results')
              .where('userId', isEqualTo: userId)
              .orderBy('completedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Sorgu hatası: ${snapshot.error}');
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
                      'Henüz test sonucu bulunmuyor',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final resultData =
                    results[index].data() as Map<String, dynamic>;
                final score = resultData['score'] as num?;
                final completedAt =
                    (resultData['completedAt'] as Timestamp?)?.toDate();
                final testId = resultData['testId'] as String?;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('tests')
                      .doc(testId)
                      .get(),
                  builder: (context, testSnapshot) {
                    final testData =
                        testSnapshot.data?.data() as Map<String, dynamic>?;
                    final testTitle =
                        testData?['title'] as String? ?? 'Silinmiş Test';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3A6EA5),
                          child: Text(
                            score?.toStringAsFixed(0) ?? '0',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          testTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A6EA5),
                          ),
                        ),
                        subtitle: Text(
                          'Tamamlanma: ${_formatDate(completedAt)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
