class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String? imageUrl;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.imageUrl,
  });

  String get answer => options[correctAnswerIndex];

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'imageUrl': imageUrl,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] as String,
      options: List<String>.from(map['options']),
      correctAnswerIndex: map['correctAnswerIndex'] as int,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
