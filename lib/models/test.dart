import 'package:cloud_firestore/cloud_firestore.dart';
import 'question.dart';

enum TestCategory {
  mandatory('Zorunlu Test', '🔴'),
  midtermPrep('Vize Hazırlık', '📚'),
  finalPrep('Final Hazırlık', '📖'),
  quiz('Quiz', '❓'),
  practice('Pratik Test', '💡'),
  orientation('Oryantasyon', '🎯');

  const TestCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;

  static TestCategory fromString(String value) {
    return TestCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => TestCategory.quiz,
    );
  }
}

class Test {
  final String id;
  final String title;
  final String? description;
  final int duration;
  final String? imageUrl;
  final List<Question> questions;
  final List<String>? questionIds;
  final int participantCount;
  final double averageScore;
  final DateTime createdAt;
  final String? createdBy;
  final TestCategory category;
  final String? courseId;
  final String? courseTitle;
  final String? courseCode;

  Test({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    this.imageUrl,
    required this.questions,
    this.questionIds,
    this.participantCount = 0,
    this.averageScore = 0.0,
    DateTime? createdAt,
    this.createdBy,
    this.category = TestCategory.quiz,
    this.courseId,
    this.courseTitle,
    this.courseCode,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duration': duration,
      'imageUrl': imageUrl,
      'questions': questions.map((q) => q.toMap()).toList(),
      'questionIds': questionIds,
      'participantCount': participantCount,
      'averageScore': averageScore,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'category': category.name,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseCode': courseCode,
    };
  }

  factory Test.fromMap(Map<String, dynamic> map, String id) {
    return Test(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      duration: map['duration'] ?? 30,
      imageUrl: map['imageUrl'],
      questions: List<Question>.from(
        (map['questions'] ?? []).map((q) => Question.fromMap(q)),
      ),
      questionIds: map['questionIds'] != null
          ? List<String>.from(map['questionIds'])
          : null,
      participantCount: map['participantCount'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'],
      category: TestCategory.fromString(map['category'] ?? 'quiz'),
      courseId: map['courseId'],
      courseTitle: map['courseTitle'],
      courseCode: map['courseCode'],
    );
  }
}
