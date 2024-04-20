import 'package:equatable/equatable.dart';

// Bu sınıf, bir öğrencinin bir quizi çözdükten sonraki sonucunu tutuyor.
// Equatable yine karşılaştırma için var.
class QuizResult extends Equatable {
  const QuizResult({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.totalQuestions,
  });

  final String id; // Sonucun kendi ID'si.
  final String quizId; // Hangi quiz'in sonucu olduğu.
  final String studentId; // Hangi öğrencinin sonucu olduğu.
  final Map<String, int> answers; // Öğrencinin cevapları. Soru ID'si -> Seçilen cevap index'i.
  final DateTime startTime; // Quize ne zaman başladı.
  final DateTime endTime; // Quizi ne zaman bitirdi.
  final int score; // Kaç tane doğru cevap verdi.
  final int totalQuestions; // Toplamda kaç soru vardı.

  // Quizi ne kadar sürede çözdüğünü hesaplayan bir getter.
  Duration get duration => endTime.difference(startTime);
  Duration get completionTime => endTime.difference(startTime); // aynısı, ne olur ne olmaz diye ekledim.

  // Başarı yüzdesini hesaplıyor.
  double get percentage => (score / totalQuestions) * 100;
  double get scorePercentage => (score / totalQuestions) * 100; // bu da aynısı.

  // Doğru ve yanlış cevap sayılarını direkt veren getter'lar.
  int get correctAnswers => score;
  int get wrongAnswers => totalQuestions - score;

  // Geçip geçmediğini kontrol ediyor. %50 ve üzeri geçer sayılıyor.
  bool get isPassed => percentage >= 50;

  // Firebase'den gelen Map'i QuizResult objesine çeviriyor.
  factory QuizResult.fromFirestore(Map<String, dynamic> data, String id) {
    return QuizResult(
      id: id,
      quizId: data['quizId'] ?? '',
      studentId: data['studentId'] ?? '',
      answers: Map<String, int>.from(data['answers'] ?? {}),
      startTime: data['startTime']?.toDate() ?? DateTime.now(),
      endTime: data['endTime']?.toDate() ?? DateTime.now(),
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
    );
  }

  // QuizResult objesini Map'e çeviriyor, Firebase'e yazmak için.
  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'answers': answers,
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'totalQuestions': totalQuestions,
    };
  }

  // Equatable için karşılaştırılacak alanlar.
  @override
  List<Object?> get props => [
        id,
        quizId,
        studentId,
        answers,
        startTime,
        endTime,
        score,
        totalQuestions,
      ];
}