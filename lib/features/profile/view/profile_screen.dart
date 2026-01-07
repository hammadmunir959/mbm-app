import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/widgets/glass_card.dart';
import 'package:cellaris/features/auth/controller/auth_controller.dart';
import 'package:cellaris/core/models/user_model.dart';

/// Check if running on desktop
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Profile Screen - Shows user details and subscription information
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(
        child: Text('Please log in to view your profile.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          FadeInDown(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withAlpha(180),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.user,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(user.status),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Main content grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAccountInfo(user)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSubscriptionInfo(user, ref)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildAccountInfo(user),
                        const SizedBox(height: 24),
                        _buildSubscriptionInfo(user, ref),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Payment History
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildPaymentHistory(user),
          ),
          const SizedBox(height: 24),

          // Account Actions
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _buildAccountActions(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        text = 'Active';
        icon = LucideIcons.checkCircle;
        break;
      case UserStatus.trial:
        color = Colors.blue;
        text = 'Trial';
        icon = LucideIcons.clock;
        break;
      case UserStatus.expired:
        color = Colors.orange;
        text = 'Expired';
        icon = LucideIcons.alertTriangle;
        break;
      case UserStatus.canceled:
        color = Colors.grey;
        text = 'Canceled';
        icon = LucideIcons.xCircle;
        break;
      case UserStatus.pending:
        color = Colors.amber;
        text = 'Pending';
        icon = LucideIcons.clock;
        break;
      case UserStatus.blocked:
        color = Colors.red;
        text = 'Blocked';
        icon = LucideIcons.ban;
        break;
      case UserStatus.pendingVerification:
        color = Colors.amber;
        text = 'Pending Verification';
        icon = LucideIcons.fileCheck;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(AppUser user) {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.userCircle, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(LucideIcons.user, 'Full Name', user.name),
            _buildInfoRow(LucideIcons.mail, 'Email', user.email),
            _buildInfoRow(
              LucideIcons.briefcase,
              'Role',
              _formatRole(user.role),
            ),
            _buildInfoRow(
              LucideIcons.calendar,
              'Member Since',
              DateFormat('MMM dd, yyyy').format(user.createdAt),
            ),
            if (user.lastLoginAt != null)
              _buildInfoRow(
                LucideIcons.logIn,
                'Last Login',
                DateFormat('MMM dd, yyyy HH:mm').format(user.lastLoginAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(AppUser user, WidgetRef ref) {
    final isActive = user.status == UserStatus.active;
    final isTrial = user.status == UserStatus.trial;
    final daysRemaining = user.subscriptionExpiry.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7 && daysRemaining > 0;

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.crown, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Subscription Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isTrial)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FREE TRIAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Subscription status indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive || isTrial
                    ? Colors.green.withAlpha(15)
                    : Colors.orange.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive || isTrial
                      ? Colors.green.withAlpha(50)
                      : Colors.orange.withAlpha(50),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive || isTrial ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive || isTrial ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                      color: isActive || isTrial ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive
                              ? 'Subscription Active'
                              : isTrial
                                  ? 'Free Trial Active'
                                  : 'Subscription Inactive',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive || isTrial ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive || isTrial
                              ? isExpiringSoon
                                  ? 'Expires in $daysRemaining days'
                                  : 'Valid until ${DateFormat('MMM dd, yyyy').format(user.subscriptionExpiry)}'
                              : 'Please renew your subscription',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpiringSoon ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (daysRemaining > 0)
                    Column(
                      children: [
                        Text(
                          '$daysRemaining',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isExpiringSoon ? Colors.orange : AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'days left',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.calendar,
                    label: 'Start Date',
                    value: DateFormat('MMM dd').format(
                      user.subscriptionExpiry.subtract(const Duration(days: 30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: LucideIcons.calendarCheck,
                    label: 'End Date',
                    value: DateFormat('MMM dd').format(user.subscriptionExpiry),
                  ),
                ),
              ],
            ),

            if (isExpiringSoon) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(50)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 18, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your subscription is expiring soon. Please renew to continue using Cellaris.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(AppUser user) {
    // Mock payment history - in a real app, this would come from Firestore
    final payments = [
      _PaymentRecord(
        date: DateTime.now().subtract(const Duration(days: 5)),
        amount: 5000,
        status: 'completed',
        transactionId: 'TXN12345678',
        method: 'EasyPaisa',
      ),
      _PaymentRecord(
        date: DateTime.now().subtract(const Duration(days: 35)),
        amount: 5000,
        status: 'completed',
        transactionId: 'TXN87654321',
        method: 'JazzCash',
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.receipt, size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.fileText, size: 48, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  const Text(
                    'No payment history yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: payment.status == 'completed'
                            ? Colors.green.withAlpha(20)
                            : Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        payment.status == 'completed'
                            ? LucideIcons.checkCircle
                            : LucideIcons.clock,
                        color: payment.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rs. ${payment.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: payment.status == 'completed'
                                      ? Colors.green.withAlpha(20)
                                      : Colors.orange.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  payment.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: payment.status == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${payment.method} • ${payment.transactionId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(payment.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.settings, size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionTile(
                icon: LucideIcons.refreshCw,
                label: 'Sync Account',
                color: Colors.blue,
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).refreshSubscription();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account synced successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              _buildActionTile(
                icon: LucideIcons.settings,
                label: 'Settings',
                color: Colors.grey,
                onTap: () => context.go('/settings'),
              ),
              _buildActionTile(
                icon: LucideIcons.helpCircle,
                label: 'Support',
                color: Colors.amber,
                onTap: () {
                  // TODO: Open support
                },
              ),
              _buildActionTile(
                icon: LucideIcons.logOut,
                label: 'Logout',
                color: Colors.red,
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRole(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.stockManager:
        return 'Stock Manager';
      case UserRole.salesProfessional:
        return 'Sales Professional';
      case UserRole.accountant:
        return 'Accountant';
    }
  }
}

class _PaymentRecord {
  final DateTime date;
  final double amount;
  final String status;
  final String transactionId;
  final String method;

  _PaymentRecord({
    required this.date,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.method,
  });
}
