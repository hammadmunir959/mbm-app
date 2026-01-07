import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/navigation/app_router.dart';
import 'package:cellaris/firebase_options.dart';
import 'package:cellaris/core/database/isar_service.dart';
import 'package:cellaris/core/repositories/settings_repository.dart';
import 'package:cellaris/core/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Platform-specific Firebase imports
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;
import 'package:firebase_core/firebase_core.dart' as flutter_firebase;

/// Global state provider for Firebase availability
final firebaseAvailableProvider = StateProvider<bool>((ref) => false);

/// Error message provider for Firebase initialization failure
final firebaseErrorProvider = StateProvider<String?>((ref) => null);

/// Check if we're on desktop platform
bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Error Handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('PRODUCTION ERROR: ${details.exception}');
  };

  // Custom Error UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Something went wrong', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(details.exception.toString(), 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  };
  
  // Initialize Firebase based on platform
  bool firebaseInitialized = false;
  String? firebaseError;
  
  final config = DefaultFirebaseOptions.currentPlatform;
  
  try {
    if (_isDesktopPlatform) {
      // Desktop: Use firebase_dart (pure Dart implementation)
      debugPrint('🖥️ Initializing Firebase for Desktop...');
      fb_dart.FirebaseDart.setup();
      
      await fb_dart.Firebase.initializeApp(
        options: fb_dart.FirebaseOptions(
          apiKey: config.apiKey,
          projectId: config.projectId,
          appId: config.appId,
          messagingSenderId: config.messagingSenderId,
          authDomain: config.authDomain ?? '${config.projectId}.firebaseapp.com',
          storageBucket: config.storageBucket,
        ),
      );
      
      firebaseInitialized = true;
      debugPrint('✓ Firebase initialized (firebase_dart for desktop)');
      debugPrint('  Project: ${config.projectId}');
    } else {
      // Web/Mobile: Use FlutterFire
      debugPrint('📱 Initializing Firebase for Web/Mobile...');
      await flutter_firebase.Firebase.initializeApp(
        options: flutter_firebase.FirebaseOptions(
          apiKey: config.apiKey,
          projectId: config.projectId,
          appId: config.appId,
          messagingSenderId: config.messagingSenderId,
          authDomain: config.authDomain,
          storageBucket: config.storageBucket,
          measurementId: config.measurementId,
        ),
      );
      
      firebaseInitialized = true;
      debugPrint('✓ Firebase initialized (FlutterFire)');
    }
  } catch (e, stack) {
    firebaseError = e.toString();
    debugPrint('✗ Firebase initialization failed: $e');
    debugPrint('Stack: $stack');
  }
  
  // Initialize Local Database (Isar)
  final isarService = IsarService();
  await isarService.init();

  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      isarServiceProvider.overrideWithValue(isarService),
      sharedPrefsProvider.overrideWithValue(sharedPrefs),
      firebaseAvailableProvider.overrideWith((ref) => firebaseInitialized),
      firebaseErrorProvider.overrideWith((ref) => firebaseError),
    ],
  );

  // Start sync service if Firebase is available
  if (firebaseInitialized) {
    container.read(syncServiceProvider).start();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CellarisApp(),
    ),
  );
}

class CellarisApp extends ConsumerWidget {
  const CellarisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Cellaris – Mobile Business Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// Global provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
