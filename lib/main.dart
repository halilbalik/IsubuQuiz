import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_page.dart';
import 'screens/user/test_list_page.dart';
import 'screens/user/course_catalog_page.dart';
import 'screens/user/my_courses_page.dart';
import 'screens/user/course_tests_page.dart';
import 'screens/admin/admin_panel_page.dart';
import 'screens/admin/create_course_page.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web için mouse tracking sorunlarını önlemek
  if (kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Hot reload sırasında oturumu kapat
  await FirebaseAuth.instance.signOut();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISUBÜ Quiz',
      debugShowCheckedModeBanner: false,
      routes: {
        '/course-catalog': (context) => const CourseCatalogPage(),
        '/my-courses': (context) => const MyCoursesPage(),
        '/create-course': (context) => const CreateCoursePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/course-tests') {
          final courseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CourseTestsPage(courseId: courseId),
          );
        }
        return null;
      },
      // Web için mouse tracking sorunlarını önlemek için
      scrollBehavior: kIsWeb
          ? const MaterialScrollBehavior().copyWith(
              scrollbars: false,
              overscroll: false,
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            )
          : null,
      theme: ThemeData(
        primaryColor: const Color(0xFF3A6EA5),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF3A6EA5),
          secondary: const Color(0xFF3A6EA5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF3A6EA5)),
          titleTextStyle: TextStyle(
            color: Color(0xFF3A6EA5),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A6EA5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3A6EA5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3A6EA5), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3A6EA5)),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: AuthService.hasManagementAccess(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3A6EA5)),
                  );
                }

                if (roleSnapshot.data == true) {
                  return const AdminPanelPage();
                }

                return const TestListPage();
              },
            );
          }

          return LoginPage();
        },
      ),
    );
  }
}
