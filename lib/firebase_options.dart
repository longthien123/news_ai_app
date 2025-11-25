// File: lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  // ---------------- WEB CONFIG ----------------
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCP_m0trMrFVPjmv73PT7BfSZmrwg-45RI",
    authDomain: "news-app-cc165.firebaseapp.com",
    projectId: "news-app-cc165",
    storageBucket: "news-app-cc165.firebasestorage.app",
    messagingSenderId: "1035736649102",
    appId: "1:1035736649102:web:749fae26ef154f685168df",
    measurementId: "G-W21YFXETSF",
  );

  // -------------- ANDROID CONFIG --------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDEpLrtBzM7H83DkBKPUzTyET43Am9Ctgc",
    appId: "1:1035736649102:android:c9c1163aaa4092585168df",
    messagingSenderId: "1035736649102",
    projectId: "news-app-cc165",
    storageBucket: "news-app-cc165.firebasestorage.app",
  );
}
