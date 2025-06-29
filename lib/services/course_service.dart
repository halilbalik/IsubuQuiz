import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import 'auth_service.dart';

class CourseService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'courses';

  // Akademisyen ders oluşturur
  static Future<String> createCourse({
    required String title,
    required String code,
    required String description,
    required int maxStudents,
  }) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Sadece akademisyen ve admin ders oluşturabilir
      final hasAccess = await AuthService.hasManagementAccess();
      if (!hasAccess) throw Exception('Ders oluşturma yetkiniz yok');

      // Akademisyen bilgilerini al
      final userDoc =
          await _firestore.collection('users').doc(currentUser).get();
      final userData = userDoc.data();
      final instructorName = userData?['name'] ?? 'Bilinmeyen Akademisyen';

      final courseData = Course(
        id: '', // Firestore tarafından otomatik atanacak
        title: title,
        code: code,
        description: description,
        instructorId: currentUser,
        instructorName: instructorName,
        maxStudents: maxStudents,
      ).toMap();

      final docRef = await _firestore.collection(_collection).add(courseData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ders oluşturulurken hata: $e');
    }
  }

  // Akademisyenin kendi derslerini getir
  static Stream<List<Course>> getInstructorCourses(String instructorId) {
    return _firestore
        .collection(_collection)
        .where('instructorId', isEqualTo: instructorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Course.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tüm dersleri getir (öğrenciler için)
  static Stream<List<Course>> getAllActiveCourses() {
    return _firestore
        .collection(_collection)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Course.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Öğrenciyi derse kaydet
  static Future<void> enrollStudentToCourse(
      String courseId, String studentId) async {
    try {
      final courseRef = _firestore.collection(_collection).doc(courseId);
      final courseDoc = await courseRef.get();

      if (!courseDoc.exists) throw Exception('Ders bulunamadı');

      final course = Course.fromMap(courseDoc.data()!, courseId);

      if (course.isFull) throw Exception('Ders kontenjanı dolu');
      if (course.isStudentEnrolled(studentId))
        throw Exception('Zaten bu derse kayıtlısınız');

      await courseRef.update({
        'enrolledStudents': FieldValue.arrayUnion([studentId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Derse kayıt hatası: $e');
    }
  }

  // Öğrenciyi dersten çıkar
  static Future<void> unenrollStudentFromCourse(
      String courseId, String studentId) async {
    try {
      await _firestore.collection(_collection).doc(courseId).update({
        'enrolledStudents': FieldValue.arrayRemove([studentId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Dersten çıkarma hatası: $e');
    }
  }

  // Öğrencinin kayıtlı olduğu dersleri getir
  static Stream<List<Course>> getStudentCourses(String studentId) {
    debugPrint('🔍 getStudentCourses çağrıldı - StudentID: $studentId');

    return _firestore
        .collection(_collection)
        .where('enrolledStudents', arrayContains: studentId)
        .orderBy('title')
        .snapshots()
        .handleError((error) {
      debugPrint('❌ FIRESTORE INDEX HATASI:');
      debugPrint('📋 Koleksiyon: courses');
      debugPrint('🔍 Query: enrolledStudents array-contains + orderBy title');
      debugPrint('🛠️ Gerekli Index:');
      debugPrint('   Collection: courses');
      debugPrint('   Fields: enrolledStudents (Array), title (Ascending)');
      debugPrint('💡 Firebase Console\'da bu index\'i oluşturun!');
      debugPrint('⚠️ Hata detayı: $error');

      // Firebase Console URL'ini oluştur ve yazdır
      final errorString = error.toString();
      if (errorString.contains('console.firebase.google.com')) {
        // URL'yi error mesajından çıkar
        final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]*')
            .firstMatch(errorString);
        if (urlMatch != null) {
          final indexUrl = urlMatch.group(0);
          debugPrint('🔗 FIREBASE CONSOLE INDEX URL:');
          debugPrint('🚀 AÇMAK İÇİN TIKLAYIN: $indexUrl');
          debugPrint('📋 VEYA KOPYALAYIN: $indexUrl');
        }
      }

      // Fallback: orderBy olmadan dene
      debugPrint('🔄 Fallback: orderBy olmadan deneniyor...');
      return _firestore
          .collection(_collection)
          .where('enrolledStudents', arrayContains: studentId)
          .snapshots();
    }).map((snapshot) {
      debugPrint(
          '✅ Courses query başarılı - ${snapshot.docs.length} ders bulundu');
      return snapshot.docs.map((doc) {
        return Course.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ders bilgilerini güncelle (sadece akademisyen)
  static Future<void> updateCourse(
    String courseId, {
    String? title,
    String? code,
    String? description,
    int? maxStudents,
  }) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Ders sahibi mi kontrol et
      final courseDoc =
          await _firestore.collection(_collection).doc(courseId).get();
      final course = Course.fromMap(courseDoc.data()!, courseId);

      final isAdmin = await AuthService.isAdmin();
      if (!isAdmin && course.instructorId != currentUser) {
        throw Exception('Bu dersi güncelleme yetkiniz yok');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (title != null) updateData['title'] = title;
      if (code != null) updateData['code'] = code;
      if (description != null) updateData['description'] = description;
      if (maxStudents != null) updateData['maxStudents'] = maxStudents;

      await _firestore.collection(_collection).doc(courseId).update(updateData);
    } catch (e) {
      throw Exception('Ders güncelleme hatası: $e');
    }
  }

  // Tek ders getir
  static Future<Course?> getCourse(String courseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(courseId).get();
      if (!doc.exists) return null;
      return Course.fromMap(doc.data()!, courseId);
    } catch (e) {
      throw Exception('Ders getirme hatası: $e');
    }
  }

  // Admin için tüm dersleri getir
  static Stream<List<Course>> getAllCourses() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Course.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ders silme (sadece akademisyen ve admin)
  static Future<void> deleteCourse(String courseId) async {
    try {
      final currentUser = AuthService.getCurrentUserId();
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Ders sahibi mi kontrol et
      final courseDoc =
          await _firestore.collection(_collection).doc(courseId).get();
      if (!courseDoc.exists) throw Exception('Ders bulunamadı');

      final course = Course.fromMap(courseDoc.data()!, courseId);

      final isAdmin = await AuthService.isAdmin();
      if (!isAdmin && course.instructorId != currentUser) {
        throw Exception('Bu dersi silme yetkiniz yok');
      }

      debugPrint('🗑️ Ders siliniyor: ${course.title} (${course.code})');
      debugPrint('👤 Silen kullanıcı: $currentUser');
      debugPrint(
          '📊 Kayıtlı öğrenci sayısı: ${course.enrolledStudents.length}');

      // Dersi sil
      await _firestore.collection(_collection).doc(courseId).delete();

      debugPrint('✅ Ders başarıyla silindi: $courseId');

      // TODO: Gelecekte derse ait testleri de silmek için:
      // - tests koleksiyonunda courseId'si bu olan testleri bul
      // - test_results koleksyonunda bu testlere ait sonuçları sil
    } catch (e) {
      debugPrint('❌ Ders silme hatası: $e');
      throw Exception('Ders silme hatası: $e');
    }
  }
}
