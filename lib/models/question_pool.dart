import 'package:cloud_firestore/cloud_firestore.dart';
import 'question.dart';

enum QuestionDifficulty {
  easy('Kolay', '🟢'),
  medium('Orta', '🟡'),
  hard('Zor', '🔴');

  const QuestionDifficulty(this.displayName, this.emoji);
  final String displayName;
  final String emoji;

  static QuestionDifficulty fromString(String value) {
    return QuestionDifficulty.values.firstWhere(
      (difficulty) => difficulty.name == value,
      orElse: () => QuestionDifficulty.medium,
    );
  }
}

enum QuestionSource {
  manual('Manuel Eklendi', '👤'),
  ai('AI Tarafından Oluşturuldu', '🤖');

  const QuestionSource(this.displayName, this.emoji);
  final String displayName;
  final String emoji;

  static QuestionSource fromString(String value) {
    return QuestionSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => QuestionSource.manual,
    );
  }
}

class PoolQuestion extends Question {
  final String id;
  final String courseId;
  final String topic; // Konu başlığı
  final QuestionDifficulty difficulty;
  final QuestionSource source;
  final String createdBy;
  final DateTime createdAt;
  final List<String> tags; // Etiketler
  final int usageCount; // Kaç testte kullanıldı
  final double avgPerformance; // Ortalama doğru cevaplama oranı

  PoolQuestion({
    required this.id,
    required this.courseId,
    required this.topic,
    required String text,
    required List<String> options,
    required int correctAnswerIndex,
    String? imageUrl,
    this.difficulty = QuestionDifficulty.medium,
    this.source = QuestionSource.manual,
    required this.createdBy,
    DateTime? createdAt,
    this.tags = const [],
    this.usageCount = 0,
    this.avgPerformance = 0.0,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        super(
          text: text,
          options: options,
          correctAnswerIndex: correctAnswerIndex,
          imageUrl: imageUrl,
        );

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'topic': topic,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'imageUrl': imageUrl,
      'difficulty': difficulty.name,
      'source': source.name,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'tags': tags,
      'usageCount': usageCount,
      'avgPerformance': avgPerformance,
    };
  }

  factory PoolQuestion.fromMap(Map<String, dynamic> map, String id) {
    return PoolQuestion(
      id: id,
      courseId: map['courseId'] ?? '',
      topic: map['topic'] ?? '',
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      imageUrl: map['imageUrl'],
      difficulty: QuestionDifficulty.fromString(map['difficulty'] ?? 'medium'),
      source: QuestionSource.fromString(map['source'] ?? 'manual'),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      usageCount: map['usageCount'] ?? 0,
      avgPerformance: (map['avgPerformance'] ?? 0.0).toDouble(),
    );
  }

  // Question'a dönüştür (test oluştururken kullanmak için)
  Question toQuestion() {
    return Question(
      text: text,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      imageUrl: imageUrl,
    );
  }

  PoolQuestion copyWith({
    String? topic,
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
    String? imageUrl,
    QuestionDifficulty? difficulty,
    List<String>? tags,
    int? usageCount,
    double? avgPerformance,
  }) {
    return PoolQuestion(
      id: id,
      courseId: courseId,
      topic: topic ?? this.topic,
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      imageUrl: imageUrl ?? this.imageUrl,
      difficulty: difficulty ?? this.difficulty,
      source: source,
      createdBy: createdBy,
      createdAt: createdAt,
      tags: tags ?? this.tags,
      usageCount: usageCount ?? this.usageCount,
      avgPerformance: avgPerformance ?? this.avgPerformance,
    );
  }
}
