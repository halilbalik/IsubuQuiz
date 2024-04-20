import 'package:equatable/equatable.dart';
import 'question.dart';

// Bu da Quiz sınıfı. Bir quizin başlığı, açıklaması, soruları falan hep burada.
class Quiz extends Equatable {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.academicId,
    required this.createdAt,
    this.questions = const [], // Başlangıçta boş soru listesi.
    this.isActive = true, // Yeni quizler direkt aktif olsun.
    this.timeLimit, // Süre limiti olmayabilir, o yüzden null olabilir.
  });

  final String id; // Quiz'in ID'si.
  final String title; // Quiz'in başlığı.
  final String description; // Quiz hakkında kısa bilgi.
  final String academicId; // Quiz'i hangi akademisyenin oluşturduğu.
  final List<Question> questions; // Quiz'in içindeki sorular.
  final bool isActive; // Quiz şu an aktif mi, çözülebilir mi?
  final DateTime createdAt; // Quiz ne zaman oluşturuldu.
  final int? timeLimit; // Quiz için süre limiti (dakika cinsinden).

  // Soru sayısını kolayca almak için bir getter.
  int get questionCount => questions.length;

  // Firebase'den gelen Map'i Quiz objesine çeviriyor.
  factory Quiz.fromFirestore(Map<String, dynamic> data, String id) {
    return Quiz(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      academicId: data['academicId'] ?? '',
      isActive: data['isActive'] ?? true,
      timeLimit: data['timeLimit'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      // Sorular listesi biraz karışık, çünkü iç içe Map'ler var.
      // Önce listeyi alıp, sonra her bir elemanı Question.fromMap ile çeviriyoruz.
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromMap(q))
              .toList() ??
          [],
    );
  }

  // Quiz objesini Map'e çeviriyor, Firebase'e yazmak için.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'academicId': academicId,
      'isActive': isActive,
      'timeLimit': timeLimit,
      'createdAt': createdAt,
      // Soruları da Map'e çevirip listeye ekliyoruz.
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  // Bir quizin kopyasını oluştururken bazı alanları değiştirmek için.
  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? academicId,
    List<Question>? questions,
    bool? isActive,
    DateTime? createdAt,
    int? timeLimit,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      academicId: academicId ?? this.academicId,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }

  // Equatable için karşılaştırılacak alanlar.
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        academicId,
        questions,
        isActive,
        createdAt,
        timeLimit,
      ];
}