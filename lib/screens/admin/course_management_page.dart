import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'question_pool_management.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.getCurrentUserId();

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ders Yönetimi')),
        body: const Center(child: Text('Kullanıcı oturumu bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ders Yönetimi',
          style: TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: AuthService.isAdmin(),
        builder: (context, adminSnapshot) {
          final isAdmin = adminSnapshot.data ?? false;

          return StreamBuilder<List<Course>>(
            stream: isAdmin
                ? CourseService.getAllCourses()
                : CourseService.getInstructorCourses(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final courses = snapshot.data ?? [];

              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        isAdmin
                            ? 'Henüz ders bulunmuyor'
                            : 'Henüz ders oluşturmadınız',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create-course'),
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Ders Oluştur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A6EA5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _buildCourseCard(course, isAdmin);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ders Başlığı ve Durum
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A6EA5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.code,
                    style: const TextStyle(
                      color: Color(0xFF3A6EA5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    course.title,
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

            // Açıklama
            Text(
              course.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Akademisyen ve İstatistikler
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  course.instructorName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${course.enrolledStudents.length}/${course.maxStudents}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aksiyon Butonları
            Column(
              children: [
                Row(
                  children: [
                    // Öğrenci Yönetimi Butonu
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToStudentManagement(course),
                        icon: const Icon(Icons.group_add, size: 16),
                        label: const Text('Öğrenci Yönetimi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A6EA5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Soru Havuzu Butonu
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToQuestionPool(course),
                        icon: const Icon(Icons.quiz, size: 16),
                        label: const Text('Soru Havuzu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hızlı Silme Butonu
                        IconButton(
                          onPressed: () => _quickDeleteCourse(course),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.shade600,
                          tooltip: 'Dersi Sil',
                        ),

                        // Ders Ayarları
                        TextButton.icon(
                          onPressed: () => _showCourseSettings(course),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Ayarlar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStudentManagement(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseStudentManagementPage(course: course),
      ),
    );
  }

  void _navigateToQuestionPool(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionPoolManagementPage(course: course),
      ),
    );
  }

  void _showCourseSettings(Course course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CourseSettingsBottomSheet(course: course),
    );
  }

  Future<void> _quickDeleteCourse(Course course) async {
    // Direkt silme dialog'unu aç
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Dersi Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${course.title} (${course.code}) dersini silmek istediğinizden emin misiniz?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Bu işlem:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Dersi tamamen silecek\n'
                    '• ${course.enrolledStudents.length} öğrencinin kaydını iptal edecek\n'
                    '• Bu işlem GERİ ALINAMAZ',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('EVET, SİL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CourseService.deleteCourse(course.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.title} dersi başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AuthService.signOut();
                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Çıkış yapılırken hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Öğrenci Yönetimi Sayfası
class CourseStudentManagementPage extends StatefulWidget {
  final Course course;

  const CourseStudentManagementPage({
    super.key,
    required this.course,
  });

  @override
  State<CourseStudentManagementPage> createState() =>
      _CourseStudentManagementPageState();
}

class _CourseStudentManagementPageState
    extends State<CourseStudentManagementPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.course.code} - Öğrenci Yönetimi',
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
          // Öğrenci Ekleme Formu
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Öğrenci Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A6EA5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Öğrenci email adresi',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addStudentByEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6EA5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kayıtlı Öğrenciler Listesi
          Expanded(
            child: FutureBuilder<Course?>(
              future: CourseService.getCourse(widget.course.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final course = snapshot.data;
                if (course == null) {
                  return const Center(child: Text('Ders bulunamadı'));
                }

                if (course.enrolledStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kayıtlı öğrenci yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yukarıdaki formu kullanarak öğrenci ekleyebilirsiniz',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: course.enrolledStudents.length,
                  itemBuilder: (context, index) {
                    final studentId = course.enrolledStudents[index];
                    return _buildStudentCard(studentId, course);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String studentId, Course course) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(studentId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Yükleniyor...'),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final studentName = userData?['name'] ?? 'Bilinmeyen Kullanıcı';
        final studentEmail = userData?['email'] ?? 'Email yok';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF3A6EA5),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(studentName),
            subtitle: Text(studentEmail),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeStudent(studentId, studentName, course),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addStudentByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email adresi boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Email ile kullanıcı bul
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersQuery.docs.isEmpty) {
        throw Exception('Bu email adresine sahip kullanıcı bulunamadı');
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();

      // Sadece öğrenci rolündeki kullanıcıları ekle
      if (userData['role'] != 'user') {
        throw Exception('Sadece öğrenci rolündeki kullanıcılar eklenebilir');
      }

      // Öğrenciyi derse ekle
      await CourseService.enrollStudentToCourse(widget.course.id, userId);

      _emailController.clear();
      if (!mounted) return;

      setState(() {}); // Listeyi yenile

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${userData['name'] ?? 'Öğrenci'} derse eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeStudent(
      String studentId, String studentName, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Çıkar'),
        content: Text(
            '$studentName adlı öğrenciyi dersten çıkarmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CourseService.unenrollStudentFromCourse(
            widget.course.id, studentId);
        if (!mounted) return;
        setState(() {}); // Listeyi yenile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$studentName dersten çıkarıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// Ders Ayarları Bottom Sheet
class CourseSettingsBottomSheet extends StatelessWidget {
  final Course course;

  const CourseSettingsBottomSheet({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.code} - Ayarlar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A6EA5),
            ),
          ),
          const SizedBox(height: 20),

          const Divider(),

          // Ders Bilgilerini Düzenle
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF3A6EA5)),
            title: const Text('Ders Bilgilerini Düzenle'),
            subtitle: const Text('Başlık, açıklama, kontenjan'),
            onTap: () => _editCourse(context),
          ),

          const Divider(),

          // Tehlikeli İşlemler
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Dersi Sil'),
            subtitle: const Text('Bu işlem geri alınamaz'),
            onTap: () => _deleteCourse(context),
          ),
        ],
      ),
    );
  }

  void _editCourse(BuildContext context) {
    Navigator.pop(context); // Bottom sheet'i kapat
    _showEditCourseDialog(context);
  }

  void _showEditCourseDialog(BuildContext context) {
    final titleController = TextEditingController(text: course.title);
    final codeController = TextEditingController(text: course.code);
    final descriptionController =
        TextEditingController(text: course.description);
    final maxStudentsController =
        TextEditingController(text: course.maxStudents.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF3A6EA5)),
            const SizedBox(width: 8),
            const Text('Ders Düzenle'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ders Kodu
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Ders Kodu *',
                      hintText: 'BLG102',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ders kodu gerekli';
                      if (value!.length < 3) return 'En az 3 karakter';
                      return null;
                    },
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),

                  // Ders Adı
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Ders Adı *',
                      hintText: 'Veri Yapıları',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ders adı gerekli';
                      if (value!.length < 5) return 'En az 5 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Açıklama
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama *',
                      hintText: 'Ders açıklaması...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Açıklama gerekli';
                      if (value!.length < 20) return 'En az 20 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kontenjan
                  TextFormField(
                    controller: maxStudentsController,
                    decoration: InputDecoration(
                      labelText: 'Maksimum Öğrenci *',
                      hintText: '30',
                      prefixIcon: const Icon(Icons.people),
                      border: const OutlineInputBorder(),
                      suffixText: 'öğrenci',
                      helperText:
                          'Şu anda ${course.enrolledStudents.length} öğrenci kayıtlı',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Kontenjan gerekli';
                      final maxStudents = int.tryParse(value!);
                      if (maxStudents == null || maxStudents < 1)
                        return 'Geçerli sayı giriniz';
                      if (maxStudents < course.enrolledStudents.length) {
                        return 'En az ${course.enrolledStudents.length} olmalı';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              codeController.dispose();
              descriptionController.dispose();
              maxStudentsController.dispose();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await CourseService.updateCourse(
                  course.id,
                  title: titleController.text.trim(),
                  code: codeController.text.trim().toUpperCase(),
                  description: descriptionController.text.trim(),
                  maxStudents: int.parse(maxStudentsController.text.trim()),
                );

                titleController.dispose();
                codeController.dispose();
                descriptionController.dispose();
                maxStudentsController.dispose();

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ders başarıyla güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A6EA5),
            ),
            child: const Text('Kaydet'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(BuildContext context) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Dersi Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${course.title} (${course.code}) dersini silmek istediğinizden emin misiniz?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Bu işlem:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Dersi tamamen silecek\n'
                    '• ${course.enrolledStudents.length} öğrencinin kaydını iptal edecek\n'
                    '• Bu işlem GERİ ALINAMAZ',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('EVET, SİL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Ders silme işlemi
        await CourseService.deleteCourse(course.id);

        Navigator.pop(context); // Settings bottom sheet'i kapat
        Navigator.pop(context); // Course management sayfasına dön

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.title} dersi başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
