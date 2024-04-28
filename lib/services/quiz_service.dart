import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/question.dart';

// Bu servis de quizlerle ilgili Firestore işlemlerini yapıyor.
// Quiz oluşturma, silme, getirme, sonuçları kaydetme falan hep burada.
class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni bir quiz oluşturup Firestore'a ekler.
  Future<String> createQuiz(Quiz quiz) async {
    try {
      final docRef =
          await _firestore.collection('quizzes').add(quiz.toFirestore());
      return docRef.id; // Oluşturulan dökümanın ID'sini döndürür.
    } catch (e) {
      throw Exception('Quiz oluşturma hatası: $e');
    }
  }

  // Mevcut bir quizi günceller.
  Future<void> updateQuiz(Quiz quiz) async {
    try {
      await _firestore
          .collection('quizzes')
          .doc(quiz.id)
          .update(quiz.toFirestore());
    } catch (e) {
      throw Exception('Quiz güncelleme hatası: $e');
    }
  }

  // Bir quizi ID'sine göre siler.
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (e) {
      throw Exception('Quiz silme hatası: $e');
    }
  }

  // Belirli bir akademisyenin oluşturduğu tüm quizleri getirir.
  // Stream kullanıyoruz ki yeni quiz eklenince liste anında güncellensin.
  Stream<List<Quiz>> getAcademicQuizzes(String academicId) {
    return _firestore
        .collection('quizzes')
        .where('academicId', isEqualTo: academicId) // Sadece bu akademisyenin olanlar.
        .orderBy('createdAt', descending: true) // En son eklenen en üstte.
        .snapshots() // Anlık dinleme için.
        .map((snapshot) => snapshot.docs
            .map((doc) => Quiz.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Öğrencilerin çözebileceği aktif olan tüm quizleri getirir.
  Stream<List<Quiz>> getActiveQuizzes() {
    return _firestore
        .collection('quizzes')
        .where('isActive', isEqualTo: true) // Sadece aktif olanlar.
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quiz.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ID'si verilen tek bir quizi getirir.
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        return Quiz.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      throw Exception('Quiz getirme hatası: $e');
    }
    return null;
  }

  // Bir quize yeni bir soru ekler. Bu pek kullanılmıyor galiba ama dursun.
  Future<void> addQuestionToQuiz(String quizId, Question question) async {
    try {
      final quiz = await getQuiz(quizId);
      if (quiz != null) {
        final updatedQuestions = List<Question>.from(quiz.questions)
          ..add(question);

        final updatedQuiz = quiz.copyWith(questions: updatedQuestions);
        await updateQuiz(updatedQuiz);
      }
    } catch (e) {
      throw Exception('Soru ekleme hatası: $e');
    }
  }

  // Bir quiz sonucunu 'quiz_results' koleksiyonuna kaydeder.
  Future<String> saveQuizResult(QuizResult result) async {
    try {
      final docRef =
          await _firestore.collection('quiz_results').add(result.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Quiz sonucu kaydetme hatası: $e');
    }
  }

  // Yukarıdakinin aynısı, sadece adı farklı. Daha mantıklı bir isimlendirme.
  Future<String> submitQuizResult(QuizResult result) async {
    return await saveQuizResult(result);
  }

  // Belirli bir quiz'e ait tüm sonuçları getirir (akademisyen için).
  Future<List<QuizResult>> getQuizResults(String quizId) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('quizId', isEqualTo: quizId)
          .get();

      return snapshot.docs
          .map((doc) => QuizResult.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Quiz sonuçları alma hatası: $e');
    }
  }

  // Belirli bir öğrencinin tüm quiz sonuçlarını getirir.
  Stream<List<QuizResult>> getStudentResults(String studentId) {
    return _firestore
        .collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .orderBy('endTime', descending: true) // En son çözdüğü en üstte.
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuizResult.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Bir öğrencinin bir quizi daha önce çözüp çözmediğini kontrol eder.
  // Bu da pek kullanılmıyor sanırım, ama ileride lazım olabilir.
  Future<bool> hasStudentTakenQuiz(String studentId, String quizId) async {
    try {
      final results = await _firestore
          .collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .where('quizId', isEqualTo: quizId)
          .get();

      return results.docs.isNotEmpty; // Sonuç varsa true döner.
    } catch (e) {
      throw Exception('Quiz kontrolü hatası: $e');
    }
  }
}