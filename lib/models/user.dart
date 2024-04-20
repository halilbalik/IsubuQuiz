import 'package:equatable/equatable.dart';

// Kullanıcı rollerini tutan enum. Ya akademisyen ya da öğrenci olabilir.
enum UserRole { academic, student }

// Kullanıcı bilgilerini tutan sınıf.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.createdAt,
  });

  final String id; // Firebase'den gelen UID.
  final String email; // E-posta adresi.
  final String firstName; // Adı.
  final String lastName; // Soyadı.
  final UserRole role; // Rolü (akademisyen mi, öğrenci mi).
  final DateTime? createdAt; // Hesabın oluşturulma tarihi.

  // Ad ve soyadını birleştiren bir getter.
  String get fullName => '$firstName $lastName';
  // Kullanıcının akademisyen olup olmadığını kontrol eden bir getter.
  bool get isAcademic => role == UserRole.academic;
  // Kullanıcının öğrenci olup olmadığını kontrol eden bir getter.
  bool get isStudent => role == UserRole.student;

  // Firebase'den gelen Map'i User objesine çeviriyor.
  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      // Rolü string olarak alıp enum'a çeviriyoruz.
      role: data['role'] == 'academic' ? UserRole.academic : UserRole.student,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  // User objesini Map'e çeviriyor, Firebase'e yazmak için.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      // Rolü enum'dan string'e çeviriyoruz.
      'role': role == UserRole.academic ? 'academic' : 'student',
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  // Equatable için karşılaştırılacak alanlar.
  @override
  List<Object?> get props => [id, email, firstName, lastName, role, createdAt];
}