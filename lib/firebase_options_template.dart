// Bu dosya da otomatik oluşturuldu ama bu bir şablon.
// Yani kendi Firebase projen için bunu kopyalayıp 'firebase_options.dart' yapman lazım.
// Sonra da içindeki 'YOUR_...' olan yerleri kendi bilgilerinle dolduracaksın.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Firebase için varsayılan ayarların şablonu.
// Kendi projen için bunu kullanacaksın.
class DefaultFirebaseOptions {
  // Hangi platformda çalışıyorsa ona göre ayarları seçiyor.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web için kendi Firebase ayarlarını buraya gireceksin.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SENIN_WEB_API_KEYIN_BURAYA',
    appId: 'SENIN_WEB_APP_IDN_BURAYA',
    messagingSenderId: 'SENIN_MESSAGING_SENDER_IDN_BURAYA',
    projectId: 'SENIN_PROJE_IDN_BURAYA',
    authDomain: 'SENIN_PROJE_IDN.firebaseapp.com',
    storageBucket: 'SENIN_PROJE_IDN.firebasestorage.app',
    measurementId: 'SENIN_WEB_MEASUREMENT_IDN_BURAYA',
  );

  // Android için kendi Firebase ayarlarını buraya gireceksin.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SENIN_ANDROID_API_KEYIN_BURAYA',
    appId: 'SENIN_ANDROID_APP_IDN_BURAYA',
    messagingSenderId: 'SENIN_MESSAGING_SENDER_IDN_BURAYA',
    projectId: 'SENIN_PROJE_IDN_BURAYA',
    storageBucket: 'SENIN_PROJE_IDN.firebasestorage.app',
  );

  // iOS için kendi Firebase ayarlarını buraya gireceksin.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SENIN_IOS_API_KEYIN_BURAYA',
    appId: 'SENIN_IOS_APP_IDN_BURAYA',
    messagingSenderId: 'SENIN_MESSAGING_SENDER_IDN_BURAYA',
    projectId: 'SENIN_PROJE_IDN_BURAYA',
    storageBucket: 'SENIN_PROJE_IDN.firebasestorage.app',
    iosBundleId: 'com.isubu.quiz.isubuQuiz', // Bunu kendi paket adınla değiştir.
  );

  // macOS için kendi Firebase ayarlarını buraya gireceksin.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'SENIN_IOS_API_KEYIN_BURAYA', // Genelde iOS ile aynıdır.
    appId: 'SENIN_IOS_APP_IDN_BURAYA',
    messagingSenderId: 'SENIN_MESSAGING_SENDER_IDN_BURAYA',
    projectId: 'SENIN_PROJE_IDN_BURAYA',
    storageBucket: 'SENIN_PROJE_IDN.firebasestorage.app',
    iosBundleId: 'com.isubu.quiz.isubuQuiz',
  );

  // Windows için kendi Firebase ayarlarını buraya gireceksin.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'SENIN_WINDOWS_API_KEYIN_BURAYA',
    appId: 'SENIN_WINDOWS_APP_IDN_BURAYA',
    messagingSenderId: 'SENIN_MESSAGING_SENDER_IDN_BURAYA',
    projectId: 'SENIN_PROJE_IDN_BURAYA',
    authDomain: 'SENIN_PROJE_IDN.firebaseapp.com',
    storageBucket: 'SENIN_PROJE_IDN.firebasestorage.app',
    measurementId: 'SENIN_WINDOWS_MEASUREMENT_IDN_BURAYA',
  );
}