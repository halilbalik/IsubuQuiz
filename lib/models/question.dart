import 'package:equatable/equatable.dart';

// Bu Question sınıfı, bir sorunun bütün bilgilerini tutuyor.
// Equatable'dan extend ettik ki iki soruyu karşılaştırmak kolay olsun.
class Question extends Equatable {
  const Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = QuestionDifficulty.medium, // Varsayılan zorluk orta.
    this.isAIGenerated = false, // Varsayılan olarak AI üretmedi.
  });

  final String id; // Sorunun unique ID'si.
  final String questionText; // Soru metni, yani "Bu nedir?" kısmı.
  final List<String> options; // Cevap şıkları, A, B, C, D.
  final int correctAnswer; // Doğru cevabın index'i (0, 1, 2, 3).
  final String? explanation; // Doğru cevabın açıklaması, neden doğru olduğu.
  final QuestionDifficulty difficulty; // Sorunun zorluğu (kolay, orta, zor).
  final bool isAIGenerated; // Soru yapay zeka tarafından mı üretildi?

  // Doğru cevabın harfini (A, B, C, D) döndüren bir getter.
  String get correctAnswerLetter {
    const letters = ['A', 'B', 'C', 'D'];
    return letters[correctAnswer];
  }

  // Bu factory metodu, Firebase'den gelen Map'i Question objesine çeviriyor.
  // Veritabanından veri okurken bunu kullanıyoruz.
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      explanation: map['explanation'],
      difficulty: QuestionDifficulty.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      isAIGenerated: map['isAIGenerated'] ?? false,
    );
  }

  // Bu metot da Question objesini Map'e çeviriyor.
  // Firebase'e veri yazarken bunu kullanıyoruz.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'isAIGenerated': isAIGenerated,
    };
  }

  // Bu copyWith metodu, bir sorunun kopyasını oluştururken bazı alanları değiştirmemizi sağlıyor.
  // Mesela sadece zorluğunu değiştirmek istediğimizde falan kullanışlı.
  Question copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    QuestionDifficulty? difficulty,
    bool? isAIGenerated,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
    );
  }

  // Equatable için gerekli olan props listesi.
  // İki Question objesinin aynı olup olmadığını bu listedeki alanlara bakarak anlıyor.
  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswer,
        explanation,
        difficulty,
        isAIGenerated,
      ];
}

// Bu enum, sorunun zorluk seviyelerini tutuyor.
// Enum kullanmak, string yazmaktan daha güvenli.
enum QuestionDifficulty {
  easy('Kolay'),
  medium('Orta'),
  hard('Zor');

  const QuestionDifficulty(this.displayName);
  final String displayName; // Ekranda görünecek adı.
}