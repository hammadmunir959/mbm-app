import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/user_control_document.dart';
import '../repositories/local_control_state_repository.dart';
import '../database/local_control_state.dart';
import 'firestore_rest_client.dart';

// Platform-specific imports
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;
import 'package:firebase_auth/firebase_auth.dart' as flutter_auth;
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;

/// Check if running on desktop platform
bool get _isDesktopGuard {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

// ============================================================
// ACCESS RESULT - What the guard returns
// ============================================================
/// Represents the result of an access check
sealed class AccessResult {
  const AccessResult();
}

/// Access granted - user can use the app
class AccessGranted extends AccessResult {
  final UserControlDocument user;
  final bool isOffline;
  
  const AccessGranted({required this.user, this.isOffline = false});
}

/// Access denied - user cannot use the app  
class AccessDenied extends AccessResult {
  final AccessDeniedReason reason;
  final String? message;
  final UserControlDocument? user;
  
  const AccessDenied({
    required this.reason, 
    this.message,
    this.user,
  });
}

/// Reasons why access might be denied
enum AccessDeniedReason {
  notAuthenticated,
  pendingApproval,
  subscriptionExpired,
  /// Trial period has ended
  trialExpired,
  /// Subscription was canceled
  subscriptionCanceled,
  accountBlocked,
  noControlDocument,
  networkError,
  /// Offline days limit has been exceeded - must sync online
  offlineLimitExceeded,
  /// Device time appears to be tampered (rolled back)
  timeTamperingDetected,
}

// ============================================================
// ACCESS GUARD SERVICE
// ============================================================
/// Central service for access control with offline-first architecture
/// 
/// This service:
/// 1. Checks Firebase for the user's control document
/// 2. Caches it locally (encrypted) for offline access
/// 3. Validates access based on status and subscription dates
/// 4. Tracks offline days and enforces limits
/// 5. Detects device time tampering
class AccessGuardService {
  // Platform-specific Firebase instances
  flutter_auth.FirebaseAuth? _flutterAuth;
  flutter_firestore.FirebaseFirestore? _flutterFirestore;
  fb_dart.FirebaseAuth? _desktopAuth;
  FirestoreRestClient? _firestoreClient;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();
  final LocalControlStateRepository? _localControlRepo;

  // Encryption configuration
  static const String _encryptionKey = 'CELLARIS_ACCESS_KEY_32BYTES_OK!'; // 32 chars for AES-256
  static const String _ivString = '16CharactersIV!!'; // 16 chars for IV
  static const String _storageKey = 'user_control_document';
  static const String _checksumSalt = 'CELLARIS_CHECKSUM_2026';

  AccessGuardService({LocalControlStateRepository? localControlRepo})
      : _localControlRepo = localControlRepo {
    if (_isDesktopGuard) {
      _desktopAuth = fb_dart.FirebaseAuth.instance;
      _firestoreClient = FirestoreRestClient(projectId: 'cellaris-959');
      
      // Listen to auth state changes to update REST client token
      _desktopAuth?.idTokenChanges().listen((user) async {
        if (user != null) {
          try {
            final token = await user.getIdToken();
            _firestoreClient?.setAuthToken(token);
            debugPrint('AccessGuard: Updated REST client auth token');
          } catch (e) {
            debugPrint('AccessGuard: Failed to get auth token: $e');
          }
        } else {
          _firestoreClient?.setAuthToken(null);
        }
      });
    } else {
      _flutterAuth = flutter_auth.FirebaseAuth.instance;
      _flutterFirestore = flutter_firestore.FirebaseFirestore.instance;
    }
  }

  /// Get current user ID
  String? get _currentUserId {
    if (_isDesktopGuard) {
      return _desktopAuth?.currentUser?.uid;
    } else {
      return _flutterAuth?.currentUser?.uid;
    }
  }

  encrypt.Encrypter get _encrypter {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  encrypt.IV get _iv => encrypt.IV.fromUtf8(_ivString);

  // ========================================
  // MAIN ACCESS CHECK
  // ========================================

  /// Check if the current user can access the app
  /// This is the main entry point for access control
  Future<AccessResult> checkAccess() async {
    // Step 1: Check if user is authenticated with Firebase
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const AccessDenied(
        reason: AccessDeniedReason.notAuthenticated,
        message: 'Please sign in to continue.',
      );
    }

    // Step 2: Check network connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    // Handle both single result and list result (depending on version)
    final bool isOnline;
    if (connectivityResult is List) {
      final resultList = connectivityResult as List<ConnectivityResult>;
      isOnline = resultList.isNotEmpty && 
          !resultList.every((r) => r == ConnectivityResult.none);
    } else {
      isOnline = (connectivityResult as ConnectivityResult) != ConnectivityResult.none;
    }

    // Step 3: If online, sync from Firebase
    if (isOnline) {
      try {
        final controlDoc = await _fetchControlDocumentFromFirebase(currentUserId);
        if (controlDoc != null) {
          // Save to local cache
          await _saveToLocalCache(controlDoc);
          // Update local control state (reset offline counter)
          await _updateLocalControlStateOnSync(controlDoc);
          return _evaluateAccess(controlDoc, isOffline: false);
        } else {
          return const AccessDenied(
            reason: AccessDeniedReason.noControlDocument,
            message: 'Your account is not set up. Please contact support.',
          );
        }
      } catch (e) {
        debugPrint('AccessGuard: Failed to fetch from Firebase: $e');
        // Fall back to cached data
      }
    }

    // Step 4: Use cached data (offline or Firebase fetch failed)
    final cachedDoc = await _getFromLocalCache();
    if (cachedDoc != null && cachedDoc.id == currentUserId) {
      // Check offline restrictions before granting access
      final offlineCheck = await _checkOfflineRestrictions();
      if (offlineCheck != null) {
        return offlineCheck;
      }
      
      // Increment offline days if this is a new day
      await _incrementOfflineDaysIfNeeded();
      
      return _evaluateAccess(cachedDoc, isOffline: true);
    }

    // Step 5: No cached data and offline
    return AccessDenied(
      reason: AccessDeniedReason.networkError,
      message: isOnline 
          ? 'Failed to verify your account. Please try again.'
          : 'You are offline and no cached data is available.',
    );
  }

  /// Check offline restrictions (time tampering, offline limit)
  Future<AccessDenied?> _checkOfflineRestrictions() async {
    if (_localControlRepo == null) return null;

    // Check time tampering
    if (await _localControlRepo!.isTimeTampered()) {
      return const AccessDenied(
        reason: AccessDeniedReason.timeTamperingDetected,
        message: 'Device time appears to be incorrect. Please connect to the internet to continue.',
      );
    }

    // Check offline days limit
    if (await _localControlRepo!.isOfflineLimitExceeded()) {
      final status = await _localControlRepo!.getOfflineStatus();
      return AccessDenied(
        reason: AccessDeniedReason.offlineLimitExceeded,
        message: 'Offline usage limit exceeded (${status?.offlineDaysUsed ?? 0}/${status?.maxOfflineDays ?? 7} days). Please connect to the internet to sync.',
      );
    }

    return null;
  }

  /// Increment offline days counter if needed
  Future<void> _incrementOfflineDaysIfNeeded() async {
    await _localControlRepo?.incrementOfflineDays();
  }

  /// Update local control state after successful sync
  Future<void> _updateLocalControlStateOnSync(UserControlDocument doc) async {
    if (_localControlRepo == null) return;

    final hasState = await _localControlRepo!.hasControlState();
    if (hasState) {
      await _localControlRepo!.updateAfterSync(
        status: doc.status.name,
        subscriptionEndDate: doc.subscriptionEndDate ?? DateTime.now(),
        serverTime: DateTime.now(), // Server timestamp approximation
        maxOfflineDays: doc.maxOfflineDays,
      );
    } else {
      await _localControlRepo!.initControlState(
        userId: doc.id,
        status: doc.status.name,
        subscriptionEndDate: doc.subscriptionEndDate ?? DateTime.now(),
        serverTime: DateTime.now(),
        maxOfflineDays: doc.maxOfflineDays,
      );
    }
  }

  /// Evaluate access based on control document
  AccessResult _evaluateAccess(UserControlDocument doc, {required bool isOffline}) {
    // Check pending approval
    if (doc.isPending) {
      return AccessDenied(
        reason: AccessDeniedReason.pendingApproval,
        message: 'Your account is pending approval. Please wait for admin verification.',
        user: doc,
      );
    }

    // Check blocked status
    if (doc.isBlocked) {
      return AccessDenied(
        reason: AccessDeniedReason.accountBlocked,
        message: doc.blockedReason ?? 'Your account has been blocked. Please contact support.',
        user: doc,
      );
    }

    // Check canceled status
    if (doc.isCanceled) {
      return AccessDenied(
        reason: AccessDeniedReason.subscriptionCanceled,
        message: 'Your subscription was canceled. Please renew to continue.',
        user: doc,
      );
    }

    // Check trial status
    if (doc.isTrial) {
      if (doc.isTrialExpired) {
        return AccessDenied(
          reason: AccessDeniedReason.trialExpired,
          message: 'Your 7-day trial has ended. Please subscribe to continue.',
          user: doc,
        );
      }
      // Trial is still valid
      return AccessGranted(user: doc, isOffline: isOffline);
    }

    // Check subscription validity
    if (doc.isSubscriptionExpired) {
      return AccessDenied(
        reason: AccessDeniedReason.subscriptionExpired,
        message: 'Your subscription has expired. Please renew to continue.',
        user: doc,
      );
    }

    // Access granted!
    return AccessGranted(user: doc, isOffline: isOffline);
  }

  // ========================================
  // FIREBASE OPERATIONS
  // ========================================

  /// Fetch control document from Firebase
  Future<UserControlDocument?> _fetchControlDocumentFromFirebase(String uid) async {
    try {
      if (_isDesktopGuard) {
        // Desktop: Use REST API
        final data = await _firestoreClient!.getDocument('users', uid);
        if (data == null) return null;
        
        final controlDoc = UserControlDocument.fromMap(uid, data);
        
        // Update last login timestamp
        await _firestoreClient!.updateDocument('users', uid, {
          'lastLoginAt': DateTime.now(),
        });

        return controlDoc;
      } else {
        // Web/Mobile: Use FlutterFire
        final doc = await _flutterFirestore!.collection('users').doc(uid).get();
        if (!doc.exists) return null;
        
        final controlDoc = UserControlDocument.fromFirestore(doc);
        
        // Update last login timestamp
        await _flutterFirestore!.collection('users').doc(uid).update({
          'lastLoginAt': flutter_firestore.FieldValue.serverTimestamp(),
        });

        return controlDoc;
      }
    } catch (e) {
      debugPrint('AccessGuard: Error fetching control document: $e');
      rethrow;
    }
  }

  /// Register a new user (creates control document with PENDING status)
  Future<UserControlDocument> registerUser({
    required String uid,
    required String email,
    required String name,
    String? phone,
    String? companyName,
  }) async {
    final controlDoc = UserControlDocument(
      id: uid,
      email: email,
      name: name,
      phone: phone,
      companyName: companyName,
      status: UserStatus.pending,
      isApproved: false,
      createdAt: DateTime.now(),
    );

    if (_isDesktopGuard) {
      await _firestoreClient!.setDocument('users', uid, controlDoc.toFirestore());
    } else {
      await _flutterFirestore!.collection('users').doc(uid).set(controlDoc.toFirestore());
    }
    
    await _saveToLocalCache(controlDoc);

    return controlDoc;
  }

  /// Log user activity
  Future<void> logActivity({
    required String activityType,
    String? description,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      if (_isDesktopGuard) {
        // Desktop: Generate generic ID (timestamp based) since REST client has no add()
        final docId = 'log_${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 4)}';
        await _firestoreClient!.setDocument('activityLogs', docId, {
          'userId': uid,
          'activityType': activityType,
          'description': description,
          'createdAt': DateTime.now(),
        });
      } else {
        await _flutterFirestore!.collection('activityLogs').add({
          'userId': uid,
          'activityType': activityType,
          'description': description,
          'createdAt': flutter_firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AccessGuard: Failed to log activity: $e');
    }
  }

  // ========================================
  // LOCAL CACHE OPERATIONS (Encrypted)
  // ========================================

  /// Save control document to encrypted local cache
  Future<void> _saveToLocalCache(UserControlDocument doc) async {
    try {
      final json = doc.toJson();
      json['_checksum'] = _generateChecksum(json);
      
      final jsonString = jsonEncode(json);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
      
      await _storage.write(key: _storageKey, value: encrypted.base64);
    } catch (e) {
      debugPrint('AccessGuard: Error saving to cache: $e');
    }
  }

  /// Get control document from encrypted local cache
  Future<UserControlDocument?> _getFromLocalCache() async {
    try {
      final encryptedData = await _storage.read(key: _storageKey);
      if (encryptedData == null) return null;

      final decrypted = _encrypter.decrypt64(encryptedData, iv: _iv);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      
      // Verify checksum
      final storedChecksum = json['_checksum'] as String?;
      json.remove('_checksum');
      
      if (storedChecksum != _generateChecksum(json)) {
        debugPrint('AccessGuard: Checksum mismatch - cache may be tampered');
        await clearLocalCache();
        return null;
      }

      return UserControlDocument.fromJson(json);
    } catch (e) {
      debugPrint('AccessGuard: Error reading from cache: $e');
      return null;
    }
  }

  /// Generate checksum for tamper detection
  String _generateChecksum(Map<String, dynamic> data) {
    final sortedJson = jsonEncode(Map.fromEntries(
      data.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    ));
    final bytes = utf8.encode('$sortedJson$_checksumSalt');
    return base64Encode(bytes).substring(0, 32);
  }

  /// Clear local cache (on logout)
  Future<void> clearLocalCache() async {
    await _storage.delete(key: _storageKey);
    // Also clear local control state
    await _localControlRepo?.clearControlState();
  }

  /// Check if local cache exists
  Future<bool> hasLocalCache() async {
    return await _storage.read(key: _storageKey) != null;
  }

  /// Get cached control document (without access check)
  Future<UserControlDocument?> getCachedControlDocument() async {
    return await _getFromLocalCache();
  }

  // ========================================
  // SYNC OPERATIONS
  // ========================================

  /// Force sync with Firebase (when coming online or manually triggered)
  Future<AccessResult> forceSync() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return const AccessDenied(
        reason: AccessDeniedReason.notAuthenticated,
        message: 'Please sign in to sync.',
      );
    }

    try {
      final controlDoc = await _fetchControlDocumentFromFirebase(currentUserId);
      if (controlDoc != null) {
        await _saveToLocalCache(controlDoc);
        // Reset offline counter after successful sync
        await _updateLocalControlStateOnSync(controlDoc);
        return _evaluateAccess(controlDoc, isOffline: false);
      } else {
        return const AccessDenied(
          reason: AccessDeniedReason.noControlDocument,
          message: 'Your account is not set up.',
        );
      }
    } catch (e) {
      return AccessDenied(
        reason: AccessDeniedReason.networkError,
        message: 'Failed to sync: ${e.toString()}',
      );
    }
  }

  /// Get current offline status
  Future<OfflineStatus?> getOfflineStatus() async {
    return await _localControlRepo?.getOfflineStatus();
  }

  /// Check if force sync is required
  Future<bool> requiresForceSync() async {
    if (_localControlRepo == null) return false;
    return await _localControlRepo!.isOfflineLimitExceeded() ||
           await _localControlRepo!.isTimeTampered();
  }

  /// Listen to control document changes in real-time
  Stream<UserControlDocument?> watchControlDocument() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return Stream.value(null);

    if (_isDesktopGuard) {
      // Desktop: No streaming via REST, fetch once and return as stream
      return Stream.fromFuture(_fetchControlDocumentFromFirebase(currentUserId))
          .map((doc) {
        if (doc != null) _saveToLocalCache(doc);
        return doc;
      });
    } else {
      // Web/Mobile: Real streaming
      return _flutterFirestore!
          .collection('users')
          .doc(currentUserId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final controlDoc = UserControlDocument.fromFirestore(doc);
        // Update local cache
        _saveToLocalCache(controlDoc);
        return controlDoc;
      });
    }
  }
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

/// Provider for AccessGuardService (with repository dependency)
final accessGuardServiceProvider = Provider<AccessGuardService>((ref) {
  try {
    final localControlRepo = ref.watch(localControlStateRepositoryProvider);
    return AccessGuardService(localControlRepo: localControlRepo);
  } catch (e) {
    // Fallback without repository if not initialized
    return AccessGuardService();
  }
});

/// Provider for access check result
final accessCheckProvider = FutureProvider<AccessResult>((ref) async {
  return ref.watch(accessGuardServiceProvider).checkAccess();
});

/// Provider for cached control document
final cachedControlDocProvider = FutureProvider<UserControlDocument?>((ref) async {
  return ref.watch(accessGuardServiceProvider).getCachedControlDocument();
});

/// Provider for real-time control document stream
final controlDocStreamProvider = StreamProvider<UserControlDocument?>((ref) {
  return ref.watch(accessGuardServiceProvider).watchControlDocument();
});

/// Provider to force sync
final forceSyncProvider = FutureProvider.family<AccessResult, void>((ref, _) async {
  return ref.watch(accessGuardServiceProvider).forceSync();
});

/// Provider to check if force sync is required
final requiresForceSyncProvider = FutureProvider<bool>((ref) async {
  return ref.watch(accessGuardServiceProvider).requiresForceSync();
});

/// Provider for current offline status
final accessGuardOfflineStatusProvider = FutureProvider<OfflineStatus?>((ref) async {
  return ref.watch(accessGuardServiceProvider).getOfflineStatus();
});
