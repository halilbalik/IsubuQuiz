import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'create_quiz_screen.dart';
import 'quiz_list_screen.dart';
import 'academic_statistics_screen.dart';
import 'academic_profile_screen.dart';

// Akademisyenin giriş yaptıktan sonra gördüğü ana ekran.
class AcademicHomeScreen extends StatefulWidget {
  const AcademicHomeScreen({super.key});

  @override
  State<AcademicHomeScreen> createState() => _AcademicHomeScreenState();
}

class _AcademicHomeScreenState extends State<AcademicHomeScreen> {
  // AuthService'i burada oluşturuyoruz ki kullanabilelim.
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akademisyen Paneli'),
        elevation: 0, // Gölgeyi kaldırdık, daha modern duruyor.
        actions: [
          // Çıkış yapma butonu.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Önce Firebase'den çıkış yapıyoruz.
              await _authService.signOut();
              // Sonra da giriş ekranına geri atıyoruz.
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false, // Geri dönemesin diye.
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcıyı karşılayan o süslü kart.
            FutureBuilder(
              future: _authService.getCurrentUserData(), // Mevcut kullanıcı verisini çekiyoruz.
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Gradient ile renk geçişi yaptık, havalı oldu.
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldiniz,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.fullName ?? 'Akademisyen', // Kullanıcı adı varsa onu, yoksa 'Akademisyen' yaz.
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Hızlı aksiyonlar başlığı.
            const Text(
              'Hızlı Aksiyonlar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dört tane butonun olduğu GridView.
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // Yan yana 2 tane kart.
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Her bir kart için _ActionCard widget'ını kullanıyoruz.
                  _ActionCard(
                    title: 'Yeni Quiz Oluştur',
                    subtitle: 'AI destekli soru üretimi',
                    icon: Icons.add_circle,
                    color: Colors.green,
                    onTap: () {
                      // Tıklayınca quiz oluşturma ekranına gidiyor.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateQuizScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    title: 'Quiz\'lerim',
                    subtitle: 'Oluşturduğum quiz\'ler',
                    icon: Icons.quiz,
                    color: Colors.blue,
                    onTap: () {
                      // Tıklayınca quiz listesi ekranına gidiyor.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizListScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    title: 'İstatistikler',
                    subtitle: 'Öğrenci performansları',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: () {
                      // Tıklayınca istatistik ekranına gidiyor.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AcademicStatisticsScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    title: 'Profil',
                    subtitle: 'Hesap ayarları',
                    icon: Icons.person,
                    color: Colors.orange,
                    onTap: () {
                      // Tıklayınca profil ekranına gidiyor.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AcademicProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ana ekrandaki o dört tane kartın widget'ı.
// Tekrar tekrar aynı kodu yazmamak için böyle ayrı bir widget yaptık.
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Kartın gölgesi.
      child: InkWell(
        onTap: onTap, // Tıklama olayı.
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}