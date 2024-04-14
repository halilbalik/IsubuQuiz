import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';

// Uygulamanın başlangıç noktası, yani her şeyin başladığı yer.
void main() async {
  // Flutter'ın düzgün çalışması için bu satır şart. Ne işe yaradığını tam bilmiyorum ama lazım.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatıyoruz. Ayarları firebase_options.dart'tan alıyor.
  // await yazdık çünkü bu işlem bitmeden uygulama başlamasın.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Uygulamayı çalıştırıyoruz. MyApp widget'ını ekrana basıyor.
  runApp(const MyApp());
}

// Bu ana widget, uygulamanın kendisi.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Bu build metodu, widget'ın nasıl görüneceğini belirliyor.
  // Yani arayüzü burada çiziyoruz.
  @override
  Widget build(BuildContext context) {
    // MaterialApp, uygulamanın temelini oluşturuyor.
    // İçine title, theme, home gibi şeyler alıyor.
    return MaterialApp(
      title: 'IsubuQuiz', // Uygulamanın adı.
      theme: ThemeData(
        // Uygulamanın renk paleti falan. Mavi temalı yaptık.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Yeni Material Design'ı kullanıyor.
      ),
      // Uygulama açıldığında ilk görünecek ekran.
      home: const LoginScreen(),
    );
  }
}