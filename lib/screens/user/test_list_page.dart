import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'test_detail_page.dart';
import 'course_catalog_page.dart';
import 'my_courses_page.dart';
import '../../models/test.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class TestListPage extends StatefulWidget {
  const TestListPage({super.key});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  String searchQuery = '';
  bool showOnlySolved = false;
  bool showOnlyFavorites = false;
  final Set<String> _favoriteTests = {};
  bool _isLoading = true;
  TestCategory? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  List<String> _userCourseIds = []; // Kullanıcının kayıtlı olduğu ders ID'leri
  StreamSubscription? _coursesSubscription; // Stream subscription'ı sakla

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUserCourses(); // Kullanıcının derslerini yükle
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _coursesSubscription?.cancel(); // Stream subscription'ı temizle
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['favoriteTests'] != null) {
        setState(() {
          _favoriteTests.addAll(
            List<String>.from(doc.data()!['favoriteTests']),
          );
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Stream'i listen ederek dersleri al
      _coursesSubscription =
          CourseService.getStudentCourses(user.uid).listen((courses) {
        setState(() {
          _userCourseIds = courses.map((course) => course.id).toList();
        });
        debugPrint(
            '👤 Kullanıcının dersleri yüklendi: ${_userCourseIds.length} ders');
      }, onError: (error) {
        debugPrint('❌ Kullanıcı dersleri yüklenirken hata: $error');
      });
    } catch (e) {
      debugPrint('❌ Kullanıcı dersleri yüklenirken hata: $e');
    }
  }

  Future<void> _toggleFavorite(String testId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (_favoriteTests.contains(testId)) {
        _favoriteTests.remove(testId);
      } else {
        _favoriteTests.add(testId);
      }
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'favoriteTests': _favoriteTests.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Testler',
          style: TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
        actions: [
          // Ders Kataloğu Butonu
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'Ders Kataloğu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseCatalogPage(),
                ),
              );
            },
          ),
          // Derslerim Butonu
          IconButton(
            icon: const Icon(Icons.book),
            tooltip: 'Derslerim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyCoursesPage(),
                ),
              );
            },
          ),
          // Çıkış Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              // Onay dialogu göster
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content:
                      const Text('Çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await AuthService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Çıkış yapılırken hata oluştu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Test ara...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF3A6EA5)),
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
                ),
                const SizedBox(height: 16),

                // Kategori Chip'leri
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        '🏷️ Kategoriler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Row(
                            children: [
                              const SizedBox(width: 16), // Sol padding
                              // Tüm Kategoriler
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedCategory == null
                                        ? const Color(0xFF3A6EA5)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedCategory == null
                                          ? const Color(0xFF3A6EA5)
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '🌟 Tümü',
                                      style: TextStyle(
                                        color: _selectedCategory == null
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Kategori chip'leri
                              ...TestCategory.values.map((category) {
                                final isSelected =
                                    _selectedCategory == category;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF3A6EA5)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF3A6EA5)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${category.emoji} ${category.displayName}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(width: 16), // Sağ padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Switch(
                      value: showOnlySolved,
                      onChanged: (value) {
                        setState(() {
                          showOnlySolved = value;
                          debugPrint('showOnlySolved: $showOnlySolved');
                        });
                      },
                      activeColor: const Color(0xFF3A6EA5),
                    ),
                    const Text(
                      'Sadece çözülmüş testler',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: showOnlyFavorites,
                      onChanged: (value) =>
                          setState(() => showOnlyFavorites = value),
                      activeColor: const Color(0xFF3A6EA5),
                    ),
                    const Text(
                      'Favoriler',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3A6EA5)),
                  );
                }

                var tests = snapshot.data?.docs ?? [];

                if (searchQuery.isNotEmpty) {
                  tests = tests.where((test) {
                    final data = test.data() as Map<String, dynamic>;
                    final title = data['title'].toString().toLowerCase();
                    return title.contains(searchQuery.toLowerCase());
                  }).toList();
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('test_results')
                      .where('userId', isEqualTo: currentUser?.uid)
                      .snapshots(),
                  builder: (context, resultSnapshot) {
                    if (resultSnapshot.hasError) {
                      return const Center(child: Text('Bir hata oluştu'));
                    }

                    final completedTests = resultSnapshot.data?.docs ?? [];
                    final completedTestIds = completedTests
                        .map((doc) => doc['testId'] as String)
                        .toSet();

                    final filteredTests = tests.where((test) {
                      final testId = test.id;
                      final isCompleted = completedTestIds.contains(testId);
                      final isFavorite = _favoriteTests.contains(testId);
                      final data = test.data() as Map<String, dynamic>;
                      final title = data['title'].toString().toLowerCase();
                      final testCategory =
                          TestCategory.fromString(data['category'] ?? 'quiz');

                      // Ders kontrolü ekle
                      final testCourseId = data['courseId'] as String?;
                      bool canViewTest = true;

                      if (testCourseId != null) {
                        // Test bir derse ait ise, kullanıcı o derse kayıtlı olmalı
                        canViewTest = _userCourseIds.contains(testCourseId);
                      }
                      // testCourseId null ise genel test, herkes görebilir

                      bool matchesFilters = canViewTest; // Başlangıç kontrolü

                      if (showOnlySolved) {
                        matchesFilters = matchesFilters && isCompleted;
                      }

                      if (showOnlyFavorites) {
                        matchesFilters = matchesFilters && isFavorite;
                      }

                      if (searchQuery.isNotEmpty) {
                        matchesFilters = matchesFilters &&
                            title.contains(searchQuery.toLowerCase());
                      }

                      if (_selectedCategory != null) {
                        matchesFilters =
                            matchesFilters && testCategory == _selectedCategory;
                      }

                      return matchesFilters;
                    }).toList();

                    if (filteredTests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              showOnlyFavorites
                                  ? Icons.favorite
                                  : showOnlySolved
                                      ? Icons.assignment_turned_in
                                      : Icons.assignment,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              showOnlyFavorites
                                  ? 'Favori test bulunmuyor'
                                  : showOnlySolved
                                      ? 'Henüz çözülmüş test bulunmuyor'
                                      : 'Henüz test bulunmuyor',
                              style: const TextStyle(
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
                      itemCount: filteredTests.length,
                      itemBuilder: (context, index) {
                        final testId = filteredTests[index].id;
                        final test =
                            filteredTests[index].data() as Map<String, dynamic>;
                        final isCompleted = completedTestIds.contains(testId);
                        final isFavorite = _favoriteTests.contains(testId);

                        return TestCard(
                          testId: testId,
                          data: test,
                          isFavorite: isFavorite,
                          isCompleted: isCompleted,
                          onFavoriteToggle: () => _toggleFavorite(testId),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TestDetailPage(testId: testId),
                              ),
                            );
                          },
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

  Widget _buildTestList(List<QueryDocumentSnapshot> tests, User? currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('test_results')
          .where('userId', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, resultSnapshot) {
        if (resultSnapshot.hasError) {
          return const Center(child: Text('Bir hata oluştu'));
        }

        final completedTests = resultSnapshot.data?.docs ?? [];
        final completedTestIds =
            completedTests.map((doc) => doc['testId'] as String).toSet();

        final filteredTests = tests.where((test) {
          final testId = test.id;
          final isCompleted = completedTestIds.contains(testId);
          final isFavorite = _favoriteTests.contains(testId);
          final data = test.data() as Map<String, dynamic>;
          final title = data['title'].toString().toLowerCase();
          final testCategory =
              TestCategory.fromString(data['category'] ?? 'quiz');

          // Ders kontrolü ekle
          final testCourseId = data['courseId'] as String?;
          bool canViewTest = true;

          if (testCourseId != null) {
            // Test bir derse ait ise, kullanıcı o derse kayıtlı olmalı
            canViewTest = _userCourseIds.contains(testCourseId);
          }
          // testCourseId null ise genel test, herkes görebilir

          bool matchesFilters = canViewTest; // Başlangıç kontrolü

          if (showOnlySolved) {
            matchesFilters = matchesFilters && isCompleted;
          }

          if (showOnlyFavorites) {
            matchesFilters = matchesFilters && isFavorite;
          }

          if (searchQuery.isNotEmpty) {
            matchesFilters =
                matchesFilters && title.contains(searchQuery.toLowerCase());
          }

          if (_selectedCategory != null) {
            matchesFilters =
                matchesFilters && testCategory == _selectedCategory;
          }

          return matchesFilters;
        }).toList();

        if (filteredTests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showOnlyFavorites
                      ? Icons.favorite
                      : showOnlySolved
                          ? Icons.assignment_turned_in
                          : Icons.assignment,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  showOnlyFavorites
                      ? 'Favori test bulunmuyor'
                      : showOnlySolved
                          ? 'Henüz çözülmüş test bulunmuyor'
                          : 'Henüz test bulunmuyor',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: filteredTests.length,
          itemBuilder: (context, index) {
            final testId = filteredTests[index].id;
            final test = filteredTests[index].data() as Map<String, dynamic>;
            final isCompleted = completedTestIds.contains(testId);
            final isFavorite = _favoriteTests.contains(testId);

            return TestCard(
              testId: testId,
              data: test,
              isFavorite: isFavorite,
              isCompleted: isCompleted,
              onFavoriteToggle: () => _toggleFavorite(testId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestDetailPage(testId: testId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class TestCard extends StatelessWidget {
  final String testId;
  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final bool isFavorite;
  final bool isCompleted;
  final VoidCallback? onFavoriteToggle;

  const TestCard({
    super.key,
    required this.testId,
    required this.data,
    this.onTap,
    required this.isFavorite,
    required this.isCompleted,
    this.onFavoriteToggle,
  });

  Future<Map<String, dynamic>> _getTestDataWithCourse() async {
    final testData = Map<String, dynamic>.from(data);

    // Eğer courseId var ama courseCode/courseName yoksa, CourseService'ten çek
    if (testData['courseId'] != null &&
        (testData['courseCode'] == null || testData['courseName'] == null)) {
      try {
        final course = await CourseService.getCourse(testData['courseId']);
        if (course != null) {
          testData['courseCode'] = course.code;
          testData['courseName'] = course.title;
          debugPrint(
              'TestCard: Ders bilgisi eklendi: ${course.code} - ${course.title}');
        }
      } catch (e) {
        debugPrint('TestCard: Ders bilgisi çekilirken hata: $e');
      }
    }

    return testData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTestDataWithCourse(),
      builder: (context, snapshot) {
        final testData = snapshot.data ?? data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isCompleted
                  ? BorderSide(color: Colors.green.shade200, width: 1)
                  : BorderSide.none,
            ),
            elevation: isCompleted ? 1 : 3,
            color: isCompleted ? Colors.green.shade50 : Colors.white,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (testData['imageUrl'] != null &&
                      testData['imageUrl'].toString().isNotEmpty)
                    Container(
                      height: 150, // Sabit yükseklik - tüm kartlar aynı boyut
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: Colors.grey[50], // Arka plan rengi
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        testData['imageUrl'],
                        fit: BoxFit.contain, // Görselin tamamını göster
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Görsel yükleme hatası: $error');
                          return Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
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
                            color: isCompleted
                                ? Colors.green
                                : const Color(0xFF3A6EA5),
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

                              // Önce ders bilgisi
                              if (testData['courseCode'] != null &&
                                  testData['courseName'] != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school,
                                        size: 14,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${testData['courseCode']} - ${testData['courseName']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ] else if (testData['courseId'] == null) ...[
                                // Genel test ise göster
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.public,
                                        size: 14,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Genel Test',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ] else if (snapshot.connectionState ==
                                  ConnectionState.waiting) ...[
                                // Ders bilgisi yüklenirken
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ders bilgisi yükleniyor...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Sonra kategori bilgisi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.shade100
                                      : const Color(0xFF3A6EA5)
                                          .withOpacity(0.1),
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
                                  testData['description']
                                      .toString()
                                      .isNotEmpty) ...[
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
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
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
                                    ],
                                  ),
                                  Row(
                                    children: [
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
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
