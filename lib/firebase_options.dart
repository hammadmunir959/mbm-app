import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the Cellaris project.
/// 
/// IMPORTANT: You need to update the values below with your actual
/// Firebase configuration from the Firebase Console:
/// 1. Go to Project Settings > General > Your apps
/// 2. Add a Web app if you haven't already
/// 3. Copy the config values here
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuration values from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC60ye5zSyGrT0Mj0CpuGU8cfHDX_EOOM0',
    appId: '1:427119716778:web:07bcf0105203b20b0623d3',
    messagingSenderId: '427119716778',
    projectId: 'cellaris-959',
    storageBucket: 'cellaris-959.firebasestorage.app',
    authDomain: 'cellaris-959.firebaseapp.com',
    measurementId: 'G-ER4KJGMT39',
  );

  // Desktop platforms use web configuration
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyC60ye5zSyGrT0Mj0CpuGU8cfHDX_EOOM0',
    appId: '1:427119716778:web:07bcf0105203b20b0623d3',
    messagingSenderId: '427119716778',
    projectId: 'cellaris-959',
    storageBucket: 'cellaris-959.firebasestorage.app',
    authDomain: 'cellaris-959.firebaseapp.com',
    measurementId: 'G-ER4KJGMT39',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC60ye5zSyGrT0Mj0CpuGU8cfHDX_EOOM0',
    appId: '1:427119716778:web:07bcf0105203b20b0623d3',
    messagingSenderId: '427119716778',
    projectId: 'cellaris-959',
    storageBucket: 'cellaris-959.firebasestorage.app',
    authDomain: 'cellaris-959.firebaseapp.com',
    measurementId: 'G-ER4KJGMT39',
  );
}
