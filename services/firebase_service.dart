import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY']!,
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
          projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
          appId: dotenv.env['FIREBASE_APP_ID']!,
          measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
        ),
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _initialized = true;
      print('🔥 Firebase initialized successfully!');
      print('📊 Project: ${dotenv.env['FIREBASE_PROJECT_ID']}');
    }
  }

  static Future<User?> signInAnonymously() async {
    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      return credential.user;
    } catch (e) {
      print('Anonymous sign-in failed: $e');
      return null;
    }
  }

  static Future<User?> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      user = await signInAnonymously();
    }

    return user;
  }
}
