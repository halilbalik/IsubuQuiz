import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<bool> isAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('Checking admin status for user: ${user?.uid}');

      if (user == null) {
        debugPrint('No user signed in');
        return false;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      debugPrint('Firestore document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        debugPrint('User document does not exist');
        return false;
      }

      final userData = userDoc.data();
      debugPrint('User data: $userData');

      if (userData == null) {
        debugPrint('User data is null');
        return false;
      }

      final userRole = userData['role'] as String?;
      debugPrint('User role: $userRole');
      debugPrint('Is admin check: ${userRole == 'admin'}');

      return userRole == 'admin';
    } catch (e, stackTrace) {
      debugPrint('Error in isAdmin check: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Akademisyen kontrolü
  static Future<bool> isTeacher() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('Checking teacher status for user: ${user?.uid}');

      if (user == null) {
        debugPrint('No user signed in');
        return false;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('User document does not exist');
        return false;
      }

      final userData = userDoc.data();
      if (userData == null) {
        debugPrint('User data is null');
        return false;
      }

      final userRole = userData['role'] as String?;
      debugPrint('User role: $userRole');
      debugPrint('Is teacher check: ${userRole == 'teacher'}');

      return userRole == 'teacher';
    } catch (e, stackTrace) {
      debugPrint('Error in isTeacher check: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Admin veya Akademisyen kontrolü (yönetici yetkisi)
  static Future<bool> hasManagementAccess() async {
    final isAdminUser = await isAdmin();
    final isTeacherUser = await isTeacher();
    return isAdminUser || isTeacherUser;
  }

  // Kullanıcının rolünü getir
  static Future<String?> getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      return userData?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Mevcut kullanıcının ID'sini getir
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Çıkış yap
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ Kullanıcı başarıyla çıkış yaptı');
    } catch (e) {
      debugPrint('❌ Çıkış yapma hatası: $e');
      throw Exception('Çıkış yapılırken hata oluştu: $e');
    }
  }

  // Kullanıcının admin olup olmadığını Firestore'dan kontrol et
  static Future<void> checkAndUpdateAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Kullanıcı dokümanı yoksa oluştur
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'user', // Varsayılan rol
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'name': user.displayName ?? 'User',
          'stats': {
            'averageScore': 0,
            'highestScore': 0,
            'totalTests': 0,
          },
          // Akademisyen için ek alanlar
          'department': null, // Bölüm
          'title': null, // Ünvan (Dr., Prof., Öğr. Gör., vs.)
          'specialization': null, // Uzmanlık alanı
        });
      }
    } catch (e) {
      debugPrint('Error checking/updating admin status: $e');
    }
  }
}
