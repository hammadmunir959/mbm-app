import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_control_document.dart';
import '../../../core/services/access_guard_service.dart';

// ============================================================
// AUTH STATE
// ============================================================
/// Complete authentication state including access control
class AuthState {
  final User? firebaseUser;
  final UserControlDocument? controlDocument;
  final AccessResult? accessResult;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.firebaseUser,
    this.controlDocument,
    this.accessResult,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  // ========================================
  // QUICK ACCESS GETTERS
  // ========================================

  /// Is the user authenticated with Firebase?
  bool get isAuthenticated => firebaseUser != null;

  /// Can the user access the app?
  bool get canAccessApp => accessResult is AccessGranted;

  /// Is the user pending approval?
  bool get isPendingApproval => 
      accessResult is AccessDenied && 
      (accessResult as AccessDenied).reason == AccessDeniedReason.pendingApproval;

  /// Is the user's subscription expired?
  bool get isSubscriptionExpired => 
      accessResult is AccessDenied && 
      (accessResult as AccessDenied).reason == AccessDeniedReason.subscriptionExpired;

  /// Is the user blocked?
  bool get isBlocked => 
      accessResult is AccessDenied && 
      (accessResult as AccessDenied).reason == AccessDeniedReason.accountBlocked;

  /// Is subscription valid?
  bool get isSubscriptionValid => 
      controlDocument?.isSubscriptionValid ?? false;

  /// Days until expiry
  int get daysUntilExpiry => controlDocument?.daysUntilExpiry ?? -999;

  /// User's status
  UserStatus? get userStatus => controlDocument?.status;

  /// Is the user in offline mode?
  bool get isOfflineMode => 
      accessResult is AccessGranted && (accessResult as AccessGranted).isOffline;

  // ========================================
  // COPY WITH
  // ========================================

  AuthState copyWith({
    User? firebaseUser,
    UserControlDocument? controlDocument,
    AccessResult? accessResult,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      controlDocument: controlDocument ?? this.controlDocument,
      accessResult: accessResult ?? this.accessResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  AuthState clearUser() {
    return AuthState(
      firebaseUser: null,
      controlDocument: null,
      accessResult: null,
      isLoading: false,
      error: null,
      isInitialized: true,
    );
  }

  @override
  String toString() => 
      'AuthState(authenticated: $isAuthenticated, canAccess: $canAccessApp, '
      'status: $userStatus, offline: $isOfflineMode)';
}

// ============================================================
// AUTH CONTROLLER
// ============================================================
/// Main authentication controller with integrated access control
class AuthController extends StateNotifier<AuthState> {
  final AccessGuardService _accessGuard;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthController(this._accessGuard) : super(const AuthState()) {
    _initialize();
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize auth state and listen to changes
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        await _checkAccessForUser(user);
      } else {
        state = state.clearUser();
      }
    });

    // Check current user
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      await _checkAccessForUser(currentUser);
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  /// Check access for a specific user
  Future<void> _checkAccessForUser(User user) async {
    state = state.copyWith(
      firebaseUser: user,
      isLoading: true,
    );

    final result = await _accessGuard.checkAccess();
    
    UserControlDocument? controlDoc;
    if (result is AccessGranted) {
      controlDoc = result.user;
    } else if (result is AccessDenied) {
      controlDoc = result.user;
    }

    state = state.copyWith(
      firebaseUser: user,
      controlDocument: controlDoc,
      accessResult: result,
      isLoading: false,
      isInitialized: true,
    );
  }

  // ========================================
  // AUTHENTICATION ACTIONS
  // ========================================

  /// Register a new user
  /// After registration, user status will be PENDING
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? companyName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await credential.user!.updateDisplayName(name);

      // Create control document in Firestore (status = PENDING)
      final controlDoc = await _accessGuard.registerUser(
        uid: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        companyName: companyName,
      );

      // Log the registration activity
      await _accessGuard.logActivity(
        activityType: 'registration',
        description: 'User registered',
      );

      // Check access (will be denied - pending approval)
      final accessResult = await _accessGuard.checkAccess();

      state = state.copyWith(
        firebaseUser: credential.user,
        controlDocument: controlDoc,
        accessResult: accessResult,
        isLoading: false,
        isInitialized: true,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to sign in');
      }

      // Check access (syncs control document from Firebase)
      final accessResult = await _accessGuard.checkAccess();

      UserControlDocument? controlDoc;
      if (accessResult is AccessGranted) {
        controlDoc = accessResult.user;
      } else if (accessResult is AccessDenied) {
        controlDoc = accessResult.user;
      }

      // Log login activity
      await _accessGuard.logActivity(
        activityType: 'login',
        description: 'User logged in',
      );

      state = state.copyWith(
        firebaseUser: credential.user,
        controlDocument: controlDoc,
        accessResult: accessResult,
        isLoading: false,
        isInitialized: true,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout and clear all local data
  Future<void> logout() async {
    // Log logout activity
    await _accessGuard.logActivity(
      activityType: 'logout',
      description: 'User logged out',
    );

    // Clear local cache
    await _accessGuard.clearLocalCache();

    // Sign out from Firebase
    await _firebaseAuth.signOut();

    // Clear state
    state = state.clearUser();
  }

  /// Request password reset email
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleAuthError(e),
      );
      return false;
    }
  }

  // ========================================
  // ACCESS CONTROL ACTIONS
  // ========================================

  /// Refresh access status (sync with Firebase)
  Future<void> refreshAccess() async {
    if (!state.isAuthenticated) return;

    state = state.copyWith(isLoading: true);

    final result = await _accessGuard.forceSync();

    UserControlDocument? controlDoc;
    if (result is AccessGranted) {
      controlDoc = result.user;
    } else if (result is AccessDenied) {
      controlDoc = result.user;
    }

    state = state.copyWith(
      controlDocument: controlDoc,
      accessResult: result,
      isLoading: false,
    );
  }

  /// Check access (using cached data if offline)
  Future<void> checkAccess() async {
    if (!state.isAuthenticated) return;

    final result = await _accessGuard.checkAccess();

    UserControlDocument? controlDoc;
    if (result is AccessGranted) {
      controlDoc = result.user;
    } else if (result is AccessDenied) {
      controlDoc = result.user;
    }

    state = state.copyWith(
      controlDocument: controlDoc,
      accessResult: result,
    );
  }

  // ========================================
  // HELPERS
  // ========================================

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Convert Firebase auth errors to user-friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(accessGuardServiceProvider));
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});

/// Provider for checking if user can access the app
final canAccessAppProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).canAccessApp;
});

/// Provider for current access result
final accessResultProvider = Provider<AccessResult?>((ref) {
  return ref.watch(authControllerProvider).accessResult;
});

/// Provider for current control document
final controlDocumentProvider = Provider<UserControlDocument?>((ref) {
  return ref.watch(authControllerProvider).controlDocument;
});

/// Provider for user status
final userStatusProvider = Provider<UserStatus?>((ref) {
  return ref.watch(authControllerProvider).userStatus;
});

/// Provider for subscription validity
final isSubscriptionValidProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isSubscriptionValid;
});

/// Provider for days until expiry
final daysUntilExpiryProvider = Provider<int>((ref) {
  return ref.watch(authControllerProvider).daysUntilExpiry;
});

/// Provider for offline mode status
final isOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isOfflineMode;
});
