import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_page.dart';

class AdminUserManagement extends StatelessWidget {
  const AdminUserManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF3A6EA5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .orderBy('email')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Kullanıcı listesi hatası: ${snapshot.error}');
            return const Center(
              child: Text('Bir hata oluştu'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz kullanıcı bulunmuyor',
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
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final userRole = user['role'] as String? ?? 'user';
              final isAdmin = userRole == 'admin';
              final isTeacher = userRole == 'teacher';
              final email = user['email'] as String? ?? 'E-posta yok';
              final createdAt = user['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailPage(
                          userId: userId,
                          userEmail: email,
                          isAdmin: isAdmin,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? Colors.amber.shade100
                        : isTeacher
                            ? Colors.green.shade100
                            : const Color(0xFF3A6EA5).withOpacity(0.1),
                    child: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : isTeacher
                              ? Icons.school
                              : Icons.person,
                      color: isAdmin
                          ? Colors.amber.shade800
                          : isTeacher
                              ? Colors.green.shade700
                              : const Color(0xFF3A6EA5),
                    ),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        isAdmin
                            ? '👑 Admin'
                            : isTeacher
                                ? '🎓 Akademisyen'
                                : '👤 Öğrenci',
                        style: TextStyle(
                          color: isAdmin
                              ? Colors.amber[700]
                              : isTeacher
                                  ? Colors.green[700]
                                  : Colors.grey[600],
                          fontWeight: (isAdmin || isTeacher)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Kayıt: ${_formatDate(createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      _changeUserRole(context, userId, value, userRole);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: userRole == 'admin'
                                  ? Colors.amber[700]
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Yap',
                              style: TextStyle(
                                color: userRole == 'admin'
                                    ? Colors.amber[700]
                                    : Colors.black,
                                fontWeight: userRole == 'admin'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (userRole == 'admin') ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check,
                                  color: Colors.amber[700], size: 16),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'teacher',
                        child: Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: userRole == 'teacher'
                                  ? Colors.green[700]
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Akademisyen Yap',
                              style: TextStyle(
                                color: userRole == 'teacher'
                                    ? Colors.green[700]
                                    : Colors.black,
                                fontWeight: userRole == 'teacher'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (userRole == 'teacher') ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check,
                                  color: Colors.green[700], size: 16),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'user',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: userRole == 'user'
                                  ? const Color(0xFF3A6EA5)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Öğrenci Yap',
                              style: TextStyle(
                                color: userRole == 'user'
                                    ? const Color(0xFF3A6EA5)
                                    : Colors.black,
                                fontWeight: userRole == 'user'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (userRole == 'user') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check,
                                  color: Color(0xFF3A6EA5), size: 16),
                            ],
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: isAdmin
                          ? Colors.amber[700]
                          : isTeacher
                              ? Colors.green[700]
                              : const Color(0xFF3A6EA5),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _changeUserRole(BuildContext context, String userId,
      String newRole, String currentRole) async {
    if (newRole == currentRole) return; // Aynı role tekrar atanmasını engelle

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        String roleText = '';
        Color backgroundColor = Colors.green;

        switch (newRole) {
          case 'admin':
            roleText = '👑 Admin yetkisi verildi';
            backgroundColor = Colors.amber;
            break;
          case 'teacher':
            roleText = '🎓 Akademisyen yetkisi verildi';
            backgroundColor = Colors.green;
            break;
          case 'user':
            roleText = '👤 Öğrenci rolüne değiştirildi';
            backgroundColor = const Color(0xFF3A6EA5);
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(roleText),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Rol değiştirme hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Rol değiştirme işlemi başarısız oldu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(
      BuildContext context, String userId, bool isCurrentlyAdmin) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': isCurrentlyAdmin ? 'user' : 'admin',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyAdmin
                  ? 'Admin yetkisi kaldırıldı'
                  : 'Admin yetkisi verildi',
            ),
            backgroundColor: isCurrentlyAdmin ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Yetki değiştirme hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
