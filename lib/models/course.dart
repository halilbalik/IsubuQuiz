import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String code;
  final String description;
  final String instructorId;
  final String instructorName;
  final List<String> enrolledStudents;
  final int maxStudents;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    this.enrolledStudents = const [],
    this.maxStudents = 100,
    DateTime? createdAt,
    this.updatedAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'enrolledStudents': enrolledStudents,
      'maxStudents': maxStudents,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? '',
      enrolledStudents: List<String>.from(map['enrolledStudents'] ?? []),
      maxStudents: map['maxStudents'] ?? 100,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Course copyWith({
    String? title,
    String? code,
    String? description,
    String? instructorId,
    String? instructorName,
    List<String>? enrolledStudents,
    int? maxStudents,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      maxStudents: maxStudents ?? this.maxStudents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Yardımcı metodlar
  bool get isFull => enrolledStudents.length >= maxStudents;
  int get availableSlots => maxStudents - enrolledStudents.length;
  bool isStudentEnrolled(String studentId) =>
      enrolledStudents.contains(studentId);
}
