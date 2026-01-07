import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/access_guard_service.dart';
import 'access_denied_screens.dart';

// ============================================================
// ACCESS GUARD WIDGET
// ============================================================
/// A wrapper widget that checks access before showing the child widget.
/// 
/// Use this at the root of your app (after authentication) to gate
/// access to the main application content.
/// 
/// ```dart
/// AccessGuard(
///   child: MainApp(),
///   loadingWidget: SplashScreen(),
/// )
/// ```
class AccessGuard extends ConsumerWidget {
  /// The widget to show when access is granted
  final Widget child;
  
  /// Optional loading widget while checking access
  final Widget? loadingWidget;
  
  /// Called when access result changes
  final void Function(AccessResult result)? onAccessResult;

  const AccessGuard({
    super.key,
    required this.child,
    this.loadingWidget,
    this.onAccessResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(accessCheckProvider);

    return accessAsync.when(
      data: (result) {
        // Notify callback if provided
        onAccessResult?.call(result);
        
        // Handle the result
        switch (result) {
          case AccessGranted():
            return child;
          case AccessDenied():
            return AccessDeniedScreen(accessDenied: result);
        }
      },
      loading: () => loadingWidget ?? const _DefaultLoadingScreen(),
      error: (error, stack) => ErrorScreen(
        message: 'Failed to verify access: ${error.toString()}',
        onRetry: () => ref.invalidate(accessCheckProvider),
      ),
    );
  }
}

// ============================================================
// ACCESS GUARD BUILDER
// ============================================================
/// A more flexible version of AccessGuard that gives you control
/// over how to render each state.
class AccessGuardBuilder extends ConsumerWidget {
  /// Builder for when access is granted
  final Widget Function(BuildContext context, AccessGranted result) builder;
  
  /// Builder for when access is denied (optional - defaults to AccessDeniedScreen)
  final Widget Function(BuildContext context, AccessDenied result)? deniedBuilder;
  
  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;
  
  /// Builder for error state
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const AccessGuardBuilder({
    super.key,
    required this.builder,
    this.deniedBuilder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(accessCheckProvider);

    return accessAsync.when(
      data: (result) {
        switch (result) {
          case AccessGranted():
            return builder(context, result);
          case AccessDenied():
            if (deniedBuilder != null) {
              return deniedBuilder!(context, result);
            }
            return AccessDeniedScreen(accessDenied: result);
        }
      },
      loading: () {
        if (loadingBuilder != null) {
          return loadingBuilder!(context);
        }
        return const _DefaultLoadingScreen();
      },
      error: (error, stack) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error);
        }
        return ErrorScreen(
          message: 'Failed to verify access: ${error.toString()}',
          onRetry: () => ref.invalidate(accessCheckProvider),
        );
      },
    );
  }
}

// ============================================================
// ACCESS CHECK MIXIN
// ============================================================
/// A mixin that can be added to StatefulWidget states to check access
/// on init and resume
mixin AccessCheckMixin<T extends StatefulWidget> on State<T> {
  late final WidgetRef _ref;
  bool _isAccessGranted = false;

  /// Override this to get a WidgetRef (call this in build method)
  void initAccessCheck(WidgetRef ref) {
    _ref = ref;
  }

  /// Check access and return true if granted
  Future<bool> checkAndUpdateAccess() async {
    final guard = _ref.read(accessGuardServiceProvider);
    final result = await guard.checkAccess();
    
    _isAccessGranted = result is AccessGranted;
    return _isAccessGranted;
  }

  /// Force sync access status with Firebase
  Future<void> syncAccessStatus() async {
    await _ref.read(accessGuardServiceProvider).forceSync();
    _ref.invalidate(accessCheckProvider);
  }

  bool get isAccessGranted => _isAccessGranted;
}

// ============================================================
// ACCESS STATUS INDICATOR
// ============================================================
/// A small widget that shows the current access status
/// Useful for showing in the app bar or status area
class AccessStatusIndicator extends ConsumerWidget {
  const AccessStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(accessCheckProvider);

    return accessAsync.when(
      data: (result) {
        switch (result) {
          case AccessGranted(isOffline: true):
            return _buildIndicator(
              icon: Icons.cloud_off,
              color: Colors.orange,
              tooltip: 'Offline Mode',
            );
          case AccessGranted(isOffline: false):
            return _buildIndicator(
              icon: Icons.cloud_done,
              color: Colors.green,
              tooltip: 'Connected',
            );
          case AccessDenied():
            return _buildIndicator(
              icon: Icons.warning,
              color: Colors.red,
              tooltip: 'Access Issue',
            );
        }
      },
      loading: () => _buildIndicator(
        icon: Icons.sync,
        color: Colors.blue,
        tooltip: 'Checking...',
      ),
      error: (_, __) => _buildIndicator(
        icon: Icons.error,
        color: Colors.red,
        tooltip: 'Error',
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ============================================================
// SUBSCRIPTION STATUS CARD
// ============================================================
/// A card widget that shows subscription details
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(accessCheckProvider);

    return accessAsync.when(
      data: (result) {
        if (result is AccessGranted) {
          final user = result.user;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        user.isSubscriptionValid 
                            ? Icons.check_circle 
                            : Icons.warning,
                        color: user.isSubscriptionValid 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Subscription Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildRow('Plan', user.subscriptionPlan?.name ?? 'N/A'),
                  if (user.subscriptionEndDate != null)
                    _buildRow(
                      'Expires', 
                      '${user.daysUntilExpiry} days left',
                    ),
                  if (result.isOffline)
                    Chip(
                      avatar: const Icon(Icons.cloud_off, size: 16),
                      label: const Text('Offline'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================
// DEFAULT LOADING SCREEN
// ============================================================
class _DefaultLoadingScreen extends StatelessWidget {
  const _DefaultLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Verifying access...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
