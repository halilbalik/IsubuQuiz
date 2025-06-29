import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';

class EditCoursePage extends StatefulWidget {
  final Course course;

  const EditCoursePage({super.key, required this.course});

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxStudentsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _codeController = TextEditingController(text: widget.course.code);
    _descriptionController =
        TextEditingController(text: widget.course.description);
    _maxStudentsController =
        TextEditingController(text: widget.course.maxStudents.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ders Düzenle',
          style: TextStyle(
            color: Color(0xFF3A6EA5),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF3A6EA5)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCourse,
            child: Text(
              'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Color(0xFF3A6EA5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık Kartı
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF3A6EA5)),
                          SizedBox(width: 8),
                          Text(
                            'Ders Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A6EA5),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Ders Kodu
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Ders Kodu *',
                          hintText: 'BLG102, MAT101, vb.',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFF3A6EA5), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Ders kodu gerekli';
                          }
                          if (value!.length < 3) {
                            return 'Ders kodu en az 3 karakter olmalı';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      SizedBox(height: 16),

                      // Ders Adı
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Ders Adı *',
                          hintText: 'Veri Yapıları ve Algoritmalar',
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFF3A6EA5), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Ders adı gerekli';
                          }
                          if (value!.length < 5) {
                            return 'Ders adı en az 5 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Ders Açıklaması
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Ders Açıklaması *',
                          hintText:
                              'Bu derste temel veri yapıları ve algoritmaları öğreneceksiniz...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFF3A6EA5), width: 2),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Ders açıklaması gerekli';
                          }
                          if (value!.length < 20) {
                            return 'Açıklama en az 20 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Maksimum Öğrenci Sayısı
                      TextFormField(
                        controller: _maxStudentsController,
                        decoration: InputDecoration(
                          labelText: 'Maksimum Öğrenci Sayısı *',
                          hintText: '30',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFF3A6EA5), width: 2),
                          ),
                          suffixText: 'öğrenci',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Maksimum öğrenci sayısı gerekli';
                          }
                          final maxStudents = int.tryParse(value!);
                          if (maxStudents == null || maxStudents < 1) {
                            return 'Geçerli bir sayı giriniz (en az 1)';
                          }
                          if (maxStudents > 200) {
                            return 'Maksimum 200 öğrenci olabilir';
                          }

                          // Mevcut kayıtlı öğrenci sayısından az olamaz
                          if (maxStudents <
                              widget.course.enrolledStudents.length) {
                            return 'Şu anda ${widget.course.enrolledStudents.length} öğrenci kayıtlı. En az bu sayı olmalı.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Mevcut Durum Kartı
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Mevcut Durum',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow('Kayıtlı Öğrenci',
                          '${widget.course.enrolledStudents.length}'),
                      SizedBox(height: 8),
                      _buildInfoRow(
                          'Akademisyen', widget.course.instructorName),
                      SizedBox(height: 8),
                      _buildInfoRow('Oluşturulma',
                          widget.course.createdAt.toString().split(' ')[0]),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3A6EA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Kaydediliyor...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Değişiklikleri Kaydet'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final code = _codeController.text.trim().toUpperCase();
      final description = _descriptionController.text.trim();
      final maxStudents = int.parse(_maxStudentsController.text.trim());

      // Değişiklik var mı kontrol et
      bool hasChanges = false;
      if (title != widget.course.title) hasChanges = true;
      if (code != widget.course.code) hasChanges = true;
      if (description != widget.course.description) hasChanges = true;
      if (maxStudents != widget.course.maxStudents) hasChanges = true;

      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiçbir değişiklik yapılmadı'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await CourseService.updateCourse(
        widget.course.id,
        title: title,
        code: code,
        description: description,
        maxStudents: maxStudents,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ders başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Değişiklik yapıldığını belirt
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
