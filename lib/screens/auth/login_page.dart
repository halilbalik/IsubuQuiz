import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../admin/admin_panel_page.dart';
import '../user/test_list_page.dart';
import '../../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  Future<void> _signIn(BuildContext context) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Kullanıcı dokümanı kontrolü ve oluşturma
      await AuthService.checkAndUpdateAdminStatus();

      // Rol bazlı yönlendirme
      final hasManagementAccess = await AuthService.hasManagementAccess();

      if (mounted) {
        if (hasManagementAccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanelPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TestListPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarısız. E-posta veya şifre hatalı.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 32,
                          color: Color(0xFF3A6EA5),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ISUBÜ Quiz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A6EA5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),

                            // Giriş Yap Butonu
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3A6EA5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _signIn(context),
                              child: const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kayıt Ol Butonu
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()),
                        );
                      },
                      child: const Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          color: Color(0xFF3A6EA5),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Logo ve yazı
              _buildLogoAndText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAndText() {
    return Column(
      children: [
        // Sabit logo
        Image.asset(
          'assets/images/isubu_logo.png',
          height: 60,
          width: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            children: [
              TextSpan(
                text: 'ISPARTA ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A6EA5),
                ),
              ),
              TextSpan(text: 'UYGULAMALI BİLİMLER '),
              TextSpan(
                text: 'ÜNİVERSİTESİ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A6EA5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'öğrencileri tarafından yapılmıştır',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: sin(_animationController.value * 2 * pi) * 0.1,
                  child: const Row(
                    children: [
                      Tooltip(
                        message: 'Halil İbrahim Balık',
                        child: Icon(Icons.computer,
                            size: 16, color: Color(0xFF3A6EA5)),
                      ),
                      SizedBox(width: 2),
                      Tooltip(
                        message: 'Eftalya Beril Şahin',
                        child: Icon(Icons.psychology,
                            size: 16, color: Color(0xFFE91E63)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
