import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/test.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import 'test_detail_page.dart';

class CourseTestsPage extends StatefulWidget {
  final String courseId;

  const CourseTestsPage({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseTestsPage> createState() => _CourseTestsPageState();
}

class _CourseTestsPageState extends State<CourseTestsPage> {
  Course? _course;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourseInfo();
  }

  Future<void> _loadCourseInfo() async {
    try {
      final course = await CourseService.getCourse(widget.courseId);
      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ders bilgisi yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Testler'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3A6EA5)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _course != null ? '${_course!.code} - Testler' : 'Testler',
          style: const TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
      ),
      body: Column(
        children: [
          // Ders Bilgi Kartı
          if (_course != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A6EA5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _course!.code,
                          style: const TextStyle(
                            color: Color(0xFF3A6EA5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _course!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A6EA5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course!.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akademisyen: ${_course!.instructorName}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Test ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3A6EA5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3A6EA5),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          const SizedBox(height: 16),

          // Test Listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tests')
                  .where('courseId', isEqualTo: widget.courseId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3A6EA5)),
                  );
                }

                var tests = snapshot.data?.docs ?? [];

                // Arama filtresi
                if (_searchQuery.isNotEmpty) {
                  tests = tests.where((test) {
                    final data = test.data() as Map<String, dynamic>;
                    final title = data['title'].toString().toLowerCase();
                    return title.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (tests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Bu derse ait test bulunmuyor'
                              : 'Arama sonucu bulunamadı',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Farklı anahtar kelimeler deneyin',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('test_results')
                      .where('userId',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, resultSnapshot) {
                    final completedTests = resultSnapshot.data?.docs ?? [];
                    final completedTestIds = completedTests
                        .map((doc) => doc['testId'] as String)
                        .toSet();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tests.length,
                      itemBuilder: (context, index) {
                        final testId = tests[index].id;
                        final test =
                            tests[index].data() as Map<String, dynamic>;
                        final isCompleted = completedTestIds.contains(testId);

                        return _buildTestCard(
                          context,
                          testId,
                          test,
                          isCompleted,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    String testId,
    Map<String, dynamic> testData,
    bool isCompleted,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? BorderSide(color: Colors.green.shade200, width: 1)
            : BorderSide.none,
      ),
      elevation: isCompleted ? 1 : 3,
      color: isCompleted ? Colors.green.shade50 : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestDetailPage(testId: testId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF3A6EA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.assignment,
                      color:
                          isCompleted ? Colors.green : const Color(0xFF3A6EA5),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testData['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade700
                                : const Color(0xFF3A6EA5),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Kategori bilgisi
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.shade100
                                : const Color(0xFF3A6EA5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                TestCategory.fromString(
                                        testData['category'] ?? 'quiz')
                                    .emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                TestCategory.fromString(
                                        testData['category'] ?? 'quiz')
                                    .displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isCompleted
                                      ? Colors.green.shade700
                                      : const Color(0xFF3A6EA5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (testData['description'] != null &&
                            testData['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            testData['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted
                                  ? Colors.green.shade600
                                  : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.question_answer,
                              size: 16,
                              color: isCompleted
                                  ? Colors.green.shade400
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(testData['questions'] as List?)?.length ?? 0} Soru',
                              style: TextStyle(
                                fontSize: 14,
                                color: isCompleted
                                    ? Colors.green.shade600
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: isCompleted
                                  ? Colors.green.shade400
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${testData['duration'] ?? 0} dk',
                              style: TextStyle(
                                fontSize: 14,
                                color: isCompleted
                                    ? Colors.green.shade600
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        if (isCompleted) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Tamamlandı',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
