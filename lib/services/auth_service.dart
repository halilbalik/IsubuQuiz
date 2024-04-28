import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

// Bu servis, Firebase Authentication ve Firestore ile ilgili tüm işlemleri yapıyor.
// Kayıt olma, giriş yapma, çıkış yapma, kullanıcı bilgilerini getirme falan hep burada.
class AuthService {
  // Firebase'in kendi servislerini burada tanımlıyoruz.
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş yapmış olan kullanıcıyı direkt buradan alabiliyoruz.
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Kullanıcının giriş/çıkış yapma durumunu anlık olarak dinlemek için bir stream.
  // Mesela uygulama açıldığında kullanıcı hala giriş yapmış mı diye kontrol etmek için süper.
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Email ve şifre ile yeni kullanıcı kaydı.
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    try {
      // Önce Firebase Auth'a kullanıcıyı kaydediyoruz.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Auth'a kaydettikten sonra, kendi User modelimizi oluşturuyoruz.
        final user = User(
          id: credential.user!.uid, // ID'yi Auth'tan alıyoruz.
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          createdAt: DateTime.now(),
        );

        // Son olarak bu kullanıcı bilgilerini Firestore'daki 'users' koleksiyonuna kaydediyoruz.
        // Böylece role gibi ek bilgileri de tutabiliyoruz.
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toFirestore());

        return user;
      }
    } catch (e) {
      // Hata olursa fırlatıyoruz, ekranlarda yakalayıp kullanıcıya göstereceğiz.
      throw Exception('Kayıt olma hatası: $e');
    }
    return null;
  }

  // Email ve şifre ile giriş yapma.
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase Auth ile giriş yapmayı deniyoruz.
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Başarılı olursa, Firestore'dan bu kullanıcının ek bilgilerini (rolü vs.) çekiyoruz.
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
    } catch (e) {
      throw Exception('Giriş yapma hatası: $e');
    }
    return null;
  }

  // Verilen ID'ye sahip kullanıcının bilgilerini Firestore'dan getiren metot.
  Future<User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Gelen veriyi User modeline çevirip döndürüyoruz.
        return User.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      throw Exception('Kullanıcı verisi alma hatası: $e');
    }
    return null;
  }

  // O an giriş yapmış olan kullanıcının bilgilerini getiren metot.
  Future<User?> getCurrentUserData() async {
    if (currentUser != null) {
      return await getUserData(currentUser!.uid);
    }
    return null;
  }

  // Çıkış yapma.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şifre sıfırlama e-postası gönderen metot.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Şifre sıfırlama hatası: $e');
    }
  }

  // Kullanıcı profilini (ad, email) güncelleyen metot.
  Future<void> updateUserProfile({
    required String fullName,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Eğer email değiştiyse, Firebase Auth'taki email'i de güncellememiz lazım.
      // Bu genellikle bir doğrulama maili gönderir.
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Firestore'daki kullanıcı belgesini de güncelliyoruz.
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'email': email,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Profil güncelleme hatası: $e');
    }
  }

  // Şifre değiştirme metodu.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Güvenlik için, kullanıcının önce mevcut şifresini tekrar girmesini istiyoruz.
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Yeniden doğrulama başarılı olursa, yeni şifreyi ayarlıyoruz.
      await user.updatePassword(newPassword);
    } catch (e) {
      // Firebase'den gelen hataları daha anlaşılır hale getiriyoruz.
      if (e.toString().contains('wrong-password')) {
        throw Exception('Mevcut şifre hatalı');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Yeni şifre çok zayıf');
      } else {
        throw Exception('Şifre değiştirme hatası: $e');
      }
    }
  }
}