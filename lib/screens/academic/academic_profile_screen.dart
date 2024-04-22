import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

// Akademisyenin profilini düzenlediği ekran.
class AcademicProfileScreen extends StatefulWidget {
  const AcademicProfileScreen({super.key});

  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>(); // Formu kontrol etmek için.
  final _fullNameController = TextEditingController(); // Ad soyad text alanı için.
  final _emailController = TextEditingController(); // E-posta text alanı için.

  User? _currentUser; // Mevcut kullanıcı bilgileri.
  bool _isLoading = true; // Veriler yükleniyor mu?
  bool _isUpdating = false; // Profil güncelleniyor mu?

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz kullanıcı verilerini yükle.
    _loadUserData();
  }

  @override
  void dispose() {
    // Ekran kapanırken controller'ları temizle, hafızada yer tutmasın.
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Kullanıcı verilerini Firebase'den çeken metot.
  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _fullNameController.text = user.fullName;
          _emailController.text = user.email;
          _isLoading = false; // Yükleme bitti.
        });
      }
    } catch (e) {
      // Hata olursa da yüklemeyi bitir.
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Profili güncelleme metodu.
  Future<void> _updateProfile() async {
    // Form geçerli değilse (örn: boş alan varsa) bir şey yapma.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true; // Güncelleme başladı.
    });

    try {
      // AuthService üzerinden profili güncelle.
      await _authService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        // Başarılı olursa bir mesaj göster.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Güncel verileri tekrar yükle.
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        // Hata olursa da bir mesaj göster.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false; // Güncelleme bitti.
      });
    }
  }

  // Şifre değiştirme ekranına yönlendiren metot.
  Future<void> _changePassword() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  // Çıkış yapma metodu.
  Future<void> _logout() async {
    // Emin misin diye soran bir dialog göster.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Hayır'a basarsa.
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Evet'e basarsa.
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    // Eğer evet dediyse...
    if (confirmed == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          // Giriş ekranına at.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Hata olursa mesaj göster.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Çıkış hatası: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Veriler yükleniyorsa dönen bir yuvarlak göster.
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profil resmi gibi duran avatar.
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orange.shade100,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),

              // Ad soyad.
              Text(
                _currentUser?.fullName ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Rol etiketi.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Akademisyen',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Ad soyad düzenleme alanı.
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-posta düzenleme alanı.
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Güncelle butonu.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Profili Güncelle'),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre değiştir butonu.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock),
                  label: const Text('Şifre Değiştir'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Çıkış yap butonu.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bu da şifre değiştirme ekranı. Ayrı bir widget olarak burada duruyor.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdating = false;
  bool _obscureCurrentPassword = true; // Şifreleri gizlemek için.
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Şifreyi değiştiren metot.
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Ekranı kapat.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Değiştir'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Mevcut şifre alanı.
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  // Şifreyi göster/gizle butonu.
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mevcut şifre gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Yeni şifre alanı.
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Yeni şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Yeni şifre tekrar alanı.
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Şifre değiştir butonu.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Şifre Değiştir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}