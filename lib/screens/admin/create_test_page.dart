import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../models/test.dart';
import '../../models/question.dart';
import '../../models/course.dart';
import '../../models/question_pool.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/question_pool_service.dart';
import 'question_pool_selector_page.dart';

class CreateTestPage extends StatefulWidget {
  final Test? testToEdit;

  const CreateTestPage({
    super.key,
    this.testToEdit,
  });

  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String? _imageUrl;
  List<Question> _questions = [];
  List<String> _questionIds = [];
  bool _isLoading = false;
  TestCategory _selectedCategory = TestCategory.quiz;
  Course? _selectedCourse;
  List<Course> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();

    if (widget.testToEdit != null) {
      _titleController.text = widget.testToEdit!.title;
      _descriptionController.text = widget.testToEdit!.description ?? '';
      _durationController.text = widget.testToEdit!.duration.toString();
      _imageUrl = widget.testToEdit!.imageUrl;
      _questions = List.from(widget.testToEdit!.questions);
      _questionIds = List.from(widget.testToEdit!.questionIds ?? []);
      _selectedCategory = widget.testToEdit!.category;
      // Not: Ders seçimi _loadAvailableCourses içinde yapılacak
    }
  }

  Future<void> _loadAvailableCourses() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;

      final isAdmin = await AuthService.isAdmin();
      Stream<List<Course>> coursesStream;

      if (isAdmin) {
        coursesStream = CourseService.getAllCourses();
      } else {
        coursesStream = CourseService.getInstructorCourses(currentUserId);
      }

      coursesStream.listen((courses) {
        if (mounted) {
          setState(() {
            _availableCourses = courses;
            // Eğer edit modunda ve courseId varsa, ders seçimini yap
            if (widget.testToEdit != null &&
                widget.testToEdit!.courseId != null) {
              _loadSelectedCourse(widget.testToEdit!.courseId!);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Dersler yüklenirken hata: $e');
    }
  }

  Future<void> _loadSelectedCourse(String courseId) async {
    try {
      // Önce mevcut listede ara
      final courseIndex = _availableCourses.indexWhere((c) => c.id == courseId);

      if (courseIndex != -1) {
        setState(() {
          _selectedCourse = _availableCourses[courseIndex];
        });
        debugPrint('✅ Ders seçildi: ${_selectedCourse!.title}');
      } else {
        // Eğer listede yoksa, Firestore'dan direkt yükle
        final course = await CourseService.getCourse(courseId);
        if (course != null && mounted) {
          setState(() {
            _selectedCourse = course;
          });
          debugPrint('✅ Ders Firestore\'dan yüklendi: ${course.title}');
        } else {
          debugPrint('❌ Ders bulunamadı: $courseId');
        }
      }
    } catch (e) {
      debugPrint('❌ Seçili ders yüklenirken hata: $e');
    }
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir soru eklemelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final testData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'duration': int.parse(_durationController.text),
        'imageUrl': _imageUrl,
        'questions': _questions.map((q) => q.toMap()).toList(),
        'questionIds': _questionIds.isNotEmpty ? _questionIds : null,
        'createdAt': widget.testToEdit?.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
        'createdBy': user.uid,
        'category': _selectedCategory.name,
        'courseId': _selectedCourse?.id,
        'courseTitle': _selectedCourse?.title,
        'courseCode': _selectedCourse?.code,
      };

      if (widget.testToEdit != null) {
        await FirebaseFirestore.instance
            .collection('tests')
            .doc(widget.testToEdit!.id)
            .update(testData);
      } else {
        await FirebaseFirestore.instance.collection('tests').add(testData);

        // Yeni test oluşturulduğunda soru havuzundan seçilen soruların kullanım sayısını artır
        if (_questionIds.isNotEmpty) {
          await QuestionPoolService.updateMultipleQuestionUsage(_questionIds);
          debugPrint(
              '✅ ${_questionIds.length} sorunun kullanım sayısı artırıldı (testte kullanım)');
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.testToEdit != null
              ? 'Test başarıyla güncellendi'
              : 'Test başarıyla oluşturuldu'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Test kaydetme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addQuestion() async {
    final result = await showDialog<Question>(
      context: context,
      builder: (context) => const QuestionDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  Future<void> _addFromQuestionPool() async {
    if (_selectedCourse == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionPoolSelectorPage(course: _selectedCourse!),
      ),
    );

    if (result != null && mounted) {
      final questions = result['questions'] as List<Question>;
      final questionIds = result['questionIds'] as List<String>;

      if (questions.isNotEmpty) {
        setState(() {
          _questions.addAll(questions);
          _questionIds.addAll(questionIds);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${questions.length} soru teste eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _pickTestImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _imageUrl = base64String;
      });
    } catch (e) {
      debugPrint('Test görseli seçme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görsel seçilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Soru ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A6EA5),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: const Color(0xFF3A6EA5),
                  onPressed: () => _editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Soru: ${question.text}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            if (question.imageUrl != null)
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 150,
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(question.imageUrl!.split(',')[1]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      question.correctAnswerIndex == optionIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: question.correctAnswerIndex == optionIndex
                          ? Colors.green
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + optionIndex)}. $option',
                        style: TextStyle(
                          fontSize: 15,
                          color: question.correctAnswerIndex == optionIndex
                              ? Colors.green
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuestion(int index) async {
    final question = _questions[index];
    final result = await showDialog<Question>(
      context: context,
      builder: (context) => QuestionDialog(initialQuestion: question),
    );

    if (result != null && mounted) {
      setState(() {
        _questions[index] = result;
      });
    }
  }

  void _deleteQuestion(int index) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _questions.removeAt(index);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.testToEdit != null ? 'Testi Düzenle' : 'Yeni Test',
          style: const TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
        // Debug bilgisi
        actions:
            widget.testToEdit != null && widget.testToEdit!.courseId != null
                ? [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'Course ID: ${widget.testToEdit!.courseId}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ]
                : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Test Başlığı
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Test Başlığı',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Başlık boş olamaz' : null,
                  ),
                  const SizedBox(height: 16),

                  // Test Açıklaması
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Test Açıklaması (Opsiyonel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Test Süresi
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Test Süresi (Dakika)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                      hintText: 'Örn: 45',
                      helperText:
                          'Öğrenciler testi bu süre içinde tamamlamalıdır',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Süre boş olamaz';
                      }
                      final duration = int.tryParse(value!);
                      if (duration == null || duration <= 0) {
                        return 'Geçerli bir süre giriniz';
                      }
                      if (duration > 180) {
                        return 'Süre 180 dakikadan fazla olamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Test Kategorisi
                  DropdownButtonFormField<TestCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Test Kategorisi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      helperText: 'Test türünü seçin',
                    ),
                    items: TestCategory.values.map((category) {
                      return DropdownMenuItem<TestCategory>(
                        value: category,
                        child: Row(
                          children: [
                            Text(
                              category.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(category.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (TestCategory? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Kategori seçiniz' : null,
                  ),
                  const SizedBox(height: 16),

                  // Ders Seçimi
                  DropdownButtonFormField<Course>(
                    value: _selectedCourse,
                    decoration: const InputDecoration(
                      labelText: 'Ders Seçin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                      helperText:
                          'Test hangi ders için oluşturuluyor? (Opsiyonel)',
                    ),
                    items: [
                      const DropdownMenuItem<Course>(
                        value: null,
                        child: Text('Genel Test (Derse Bağlı Değil)'),
                      ),
                      ..._availableCourses.map((course) {
                        return DropdownMenuItem<Course>(
                          value: course,
                          child: Text('${course.code} - ${course.title}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (Course? newValue) {
                      setState(() {
                        _selectedCourse = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Test Görseli
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Görseli (Opsiyonel)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickTestImage,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Görsel Seç'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3A6EA5),
                                    side: const BorderSide(
                                      color: Color(0xFF3A6EA5),
                                    ),
                                  ),
                                ),
                                if (_imageUrl != null) ...[
                                  const SizedBox(height: 8),
                                  Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 300,
                                          maxHeight: 150,
                                        ),
                                        child: Image.memory(
                                          base64Decode(
                                              _imageUrl!.split(',')[1]),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _imageUrl = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sorular Başlığı
                  const Text(
                    'Sorular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A6EA5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ..._questions.asMap().entries.map(
                        (entry) => _buildQuestionCard(entry.value, entry.key),
                      ),
                  const SizedBox(height: 16),
                  // Soru Ekleme Butonları
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Manuel Soru Ekle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3A6EA5),
                            side: const BorderSide(color: Color(0xFF3A6EA5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedCourse != null
                              ? _addFromQuestionPool
                              : null,
                          icon: const Icon(Icons.quiz),
                          label: const Text('Soru Havuzundan Seç'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCourse == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Soru havuzundan soru seçmek için önce bir ders seçin',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A6EA5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save),
              const SizedBox(width: 8),
              Text(
                widget.testToEdit != null ? 'Testi Güncelle' : 'Testi Kaydet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}

class QuestionDialog extends StatefulWidget {
  final Question? initialQuestion;
  static const int maxImageSizeBytes = 500 * 1024; // 500KB

  const QuestionDialog({
    super.key,
    this.initialQuestion,
  });

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _selectedOptionIndex = 0;
  String? _imageUrl;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > QuestionDialog.maxImageSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya boyutu 500KB\'dan küçük olmalıdır'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _imageUrl = base64String;
      });
    } catch (e) {
      debugPrint('Görsel seçme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görsel seçilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      _questionController.text = widget.initialQuestion!.text;
      for (var i = 0; i < widget.initialQuestion!.options.length; i++) {
        _optionControllers[i].text = widget.initialQuestion!.options[i];
      }
      _selectedOptionIndex = widget.initialQuestion!.correctAnswerIndex;
      _imageUrl = widget.initialQuestion!.imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.initialQuestion == null ? 'Yeni Soru' : 'Soruyu Düzenle',
        style: const TextStyle(
          color: Color(0xFF3A6EA5),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Soru',
                border: OutlineInputBorder(),
                hintText: 'Soru metnini buraya yazın',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Soru boş olamaz' : null,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _selectedOptionIndex,
                      onChanged: (value) {
                        setState(() {
                          _selectedOptionIndex = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText:
                              'Seçenek ${String.fromCharCode(65 + index)}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Seçenek boş olamaz'
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Görsel Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A6EA5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (_imageUrl != null) ...[
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            maxHeight: 150,
                          ),
                          child: Image.memory(
                            base64Decode(_imageUrl!.split(',')[1]),
                            fit: BoxFit.contain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _imageUrl = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final question = Question(
                text: _questionController.text,
                options: _optionControllers
                    .map((controller) => controller.text)
                    .toList(),
                correctAnswerIndex: _selectedOptionIndex,
                imageUrl: _imageUrl,
              );
              Navigator.pop(context, question);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A6EA5),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
