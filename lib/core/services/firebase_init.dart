import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase initialization service for Cellaris
/// Handles initialization with proper error reporting
class FirebaseInit {
  static bool _initialized = false;
  static String? _error;
  
  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
  
  /// Get error message if initialization failed
  static String? get error => _error;
  
  /// Initialize Firebase with the provided options
  static Future<bool> initialize({
    required String apiKey,
    required String projectId,
    required String appId,
    required String messagingSenderId,
    String? authDomain,
    String? storageBucket,
    String? measurementId,
  }) async {
    if (_initialized) return true;
    
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          projectId: projectId,
          appId: appId,
          messagingSenderId: messagingSenderId,
          authDomain: authDomain ?? '$projectId.firebaseapp.com',
          storageBucket: storageBucket,
          measurementId: measurementId,
        ),
      );
      
      // Verify Firebase is actually ready
      final apps = Firebase.apps;
      if (apps.isNotEmpty) {
        _initialized = true;
        debugPrint('✓ Firebase initialized successfully');
        debugPrint('  Project ID: $projectId');
        debugPrint('  App ID: $appId');
        return true;
      } else {
        _error = 'Firebase initialized but no apps registered';
        return false;
      }
    } catch (e, stack) {
      _error = e.toString();
      debugPrint('✗ Firebase initialization failed');
      debugPrint('  Error: $e');
      debugPrint('  Stack: $stack');
      return false;
    }
  }
}
