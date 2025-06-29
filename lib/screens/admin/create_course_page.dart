import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/course_service.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxStudentsController = TextEditingController(text: '100');
  bool _isLoading = false;

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await CourseService.createCourse(
        title: _titleController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        maxStudents: int.parse(_maxStudentsController.text),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders başarıyla oluşturuldu'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeni Ders Oluştur',
          style: TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A6EA5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ders Başlığı
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Ders Adı',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                      hintText: 'Örn: Biçimsel Diller ve Otomata Teorisi',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ders adı boş olamaz';
                      if (value!.length < 3)
                        return 'Ders adı en az 3 karakter olmalı';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ders Kodu
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Ders Kodu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.code),
                      hintText: 'Örn: BLM301',
                      helperText: 'Otomatik olarak büyük harfe çevrilir',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ders kodu boş olamaz';
                      if (value!.length < 3)
                        return 'Ders kodu en az 3 karakter olmalı';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ders Açıklaması
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Ders Açıklaması',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Dersin içeriği ve hedefleri hakkında bilgi',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Açıklama boş olamaz';
                      if (value!.length < 10)
                        return 'Açıklama en az 10 karakter olmalı';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Maksimum Öğrenci Sayısı
                  TextFormField(
                    controller: _maxStudentsController,
                    decoration: const InputDecoration(
                      labelText: 'Maksimum Öğrenci Sayısı',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                      hintText: 'Örn: 100',
                      helperText: 'Bu derse kaç öğrenci kayıt olabilir?',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Sayı boş olamaz';
                      final number = int.tryParse(value!);
                      if (number == null || number <= 0)
                        return 'Geçerli bir sayı giriniz';
                      if (number < 5) return 'En az 5 öğrenci olmalı';
                      if (number > 500) return 'En fazla 500 öğrenci olabilir';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bilgi Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Ders Oluşturma Bilgileri',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Ders oluşturduktan sonra bu derse özel testler oluşturabilirsiniz\n'
                          '• Öğrenciler derse kayıt olabilir ve testleri görebilir\n'
                          '• Sadece sizin oluşturduğunuz testlerin sonuçlarını görebilirsiniz',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createCourse,
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
              const Icon(Icons.add),
              const SizedBox(width: 8),
              const Text(
                'Dersi Oluştur',
                style: TextStyle(
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
    _codeController.dispose();
    _descriptionController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }
}
