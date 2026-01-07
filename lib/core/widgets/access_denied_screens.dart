import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/access_guard_service.dart';
import '../models/user_control_document.dart';

// ============================================================
// ACCESS DENIED SCREEN WRAPPER
// ============================================================
/// Main screen that shows the appropriate locked state based on the reason
class AccessDeniedScreen extends ConsumerWidget {
  final AccessDenied accessDenied;

  const AccessDeniedScreen({
    super.key,
    required this.accessDenied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (accessDenied.reason) {
      case AccessDeniedReason.pendingApproval:
        return PendingApprovalScreen(
          user: accessDenied.user,
        );
      case AccessDeniedReason.subscriptionExpired:
        return SubscriptionExpiredScreen(
          user: accessDenied.user,
        );
      case AccessDeniedReason.accountBlocked:
        return AccountBlockedScreen(
          user: accessDenied.user,
          blockedReason: accessDenied.message,
        );
      case AccessDeniedReason.notAuthenticated:
        return const NotAuthenticatedScreen();
      case AccessDeniedReason.noControlDocument:
      case AccessDeniedReason.networkError:
        return ErrorScreen(
          message: accessDenied.message ?? 'An error occurred.',
          onRetry: () => ref.invalidate(accessCheckProvider),
        );
      case AccessDeniedReason.offlineLimitExceeded:
        return ErrorScreen(
          message: accessDenied.message ?? 'Offline usage limit exceeded. Please connect to the internet to sync.',
          onRetry: () => ref.invalidate(accessCheckProvider),
        );
      case AccessDeniedReason.timeTamperingDetected:
        return ErrorScreen(
          message: accessDenied.message ?? 'Device time appears to be incorrect. Please correct your device time and connect to the internet.',
          onRetry: () => ref.invalidate(accessCheckProvider),
        );
      case AccessDeniedReason.trialExpired:
        return SubscriptionExpiredScreen(
          user: accessDenied.user,
        );
      case AccessDeniedReason.subscriptionCanceled:
        return SubscriptionExpiredScreen(
          user: accessDenied.user,
        );
    }
  }
}

// ============================================================
// PENDING APPROVAL SCREEN
// ============================================================
class PendingApprovalScreen extends ConsumerWidget {
  final UserControlDocument? user;

  const PendingApprovalScreen({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Clock Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Awaiting Approval',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'Your account registration is being reviewed by our team.\nYou will be notified once your account is approved.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // User Info Card
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(LucideIcons.user, 'Name', user!.name),
                          const SizedBox(height: 12),
                          _buildInfoRow(LucideIcons.mail, 'Email', user!.email),
                          if (user!.companyName != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(LucideIcons.building, 'Company', user!.companyName!),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  
                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(accessCheckProvider),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Check Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Support
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement contact support
                    },
                    icon: const Icon(LucideIcons.messageCircle, size: 18),
                    label: const Text('Contact Support'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white60),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SUBSCRIPTION EXPIRED SCREEN
// ============================================================
class SubscriptionExpiredScreen extends ConsumerWidget {
  final UserControlDocument? user;

  const SubscriptionExpiredScreen({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF2d132c),
              const Color(0xFF4a1942),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Expired Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.calendarX,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Subscription Expired',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'Your subscription has ended.\nPlease renew to continue using Cellaris.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Expiry Info
                  if (user?.subscriptionEndDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Expired on ${_formatDate(user!.subscriptionEndDate!)}',
                            style: GoogleFonts.inter(
                              color: Colors.red.shade200,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  
                  // Renew Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to renewal/payment screen
                    },
                    icon: const Icon(LucideIcons.creditCard),
                    label: const Text('Renew Subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(accessCheckProvider),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Check Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Support
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement contact support
                    },
                    icon: const Icon(LucideIcons.messageCircle, size: 18),
                    label: const Text('Contact Support'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// ACCOUNT BLOCKED SCREEN
// ============================================================
class AccountBlockedScreen extends ConsumerWidget {
  final UserControlDocument? user;
  final String? blockedReason;

  const AccountBlockedScreen({
    super.key,
    this.user,
    this.blockedReason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF0d1117),
              const Color(0xFF161b22),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blocked Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.ban,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    'Account Blocked',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'Your account has been blocked by an administrator.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Blocked Reason
                  if (blockedReason != null && blockedReason!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 16, color: Colors.red.shade300),
                              const SizedBox(width: 8),
                              Text(
                                'Reason:',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade300,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            blockedReason!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  
                  // Contact Support Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement contact support
                    },
                    icon: const Icon(LucideIcons.messageCircle),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(accessCheckProvider),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Check Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOT AUTHENTICATED SCREEN
// ============================================================
class NotAuthenticatedScreen extends StatelessWidget {
  const NotAuthenticatedScreen({super.key});

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.logIn,
                size: 80,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Please Sign In',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You need to sign in to access Cellaris.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR SCREEN
// ============================================================
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
  });

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 80,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops!',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
