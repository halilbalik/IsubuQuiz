import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_test_management.dart';
import 'admin_user_management.dart';
import 'create_course_page.dart';
import 'course_management_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  Future<void> _checkAndPrintUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('Current User ID: ${user.uid}');

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        debugPrint('User exists: ${userDoc.exists}');
        if (userDoc.exists) {
          final userData = userDoc.data();
          debugPrint('User Data: $userData');
          debugPrint('User Role: ${userData?['role']}');
        }
      } else {
        debugPrint('No user signed in');
      }
    } catch (e) {
      debugPrint('Error checking user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: FutureBuilder<bool>(
        future: Future.wait([
          AuthService.hasManagementAccess(),
          Future(() async {
            await AuthService.checkAndUpdateAdminStatus();
            await _checkAndPrintUserData();
            return true;
          }),
        ]).then((results) => results[0]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          debugPrint('Admin check result: ${snapshot.data}');

          if (!snapshot.hasData || !snapshot.data!) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Yetkisiz Erişim'),
                backgroundColor: Colors.white,
                elevation: 0,
                foregroundColor: const Color(0xFF3A6EA5),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Yetkisiz Erişim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bu sayfaya erişim yetkiniz bulunmamaktadır.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6EA5),
                      ),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Admin/Akademisyen paneli içeriği
          return FutureBuilder<String?>(
            future: AuthService.getUserRole(),
            builder: (context, roleSnapshot) {
              final userRole = roleSnapshot.data ?? 'user';
              final isAdmin = userRole == 'admin';
              final panelTitle =
                  isAdmin ? '👑 Admin Paneli' : '🎓 Akademisyen Paneli';

              return Scaffold(
                backgroundColor: const Color(0xFFF5F5F5),
                appBar: AppBar(
                  title: Text(
                    panelTitle,
                    style: const TextStyle(
                      color: Color(0xFF3A6EA5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
                  actions: [
                    IconButton(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Çıkış Yap',
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ders Oluştur
                      _buildMenuCard(
                        context,
                        'Yeni Ders Oluştur',
                        'Yeni ders oluşturun ve öğrenci kayıtlarını yönetin',
                        Icons.add_box,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateCoursePage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        'Ders Yönetimi',
                        'Derslerinizi ve öğrencilerinizi yönetin',
                        Icons.school,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CourseManagementPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        'Test Yönetimi',
                        'Testleri oluşturun, düzenleyin ve yönetin',
                        Icons.quiz,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminTestManagement(),
                          ),
                        ),
                      ),
                      // Kullanıcı Yönetimi sadece admin için
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          'Kullanıcı Yönetimi',
                          'Kullanıcıları görüntüleyin ve yönetin',
                          Icons.people,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminUserManagement(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A6EA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3A6EA5),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A6EA5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF3A6EA5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        );
      },
    );
  }
}
