import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/widgets/glass_card.dart';
import 'package:cellaris/core/widgets/primary_button.dart';
import 'package:cellaris/core/models/user_model.dart';
import 'package:cellaris/core/services/firestore_rest_client.dart';
import '../controller/auth_controller.dart';

/// Check if running on desktop
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Subscription Expired Screen
/// Uses Transaction ID instead of screenshots to stay on Firebase FREE tier
class SubscriptionExpiredScreen extends ConsumerStatefulWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  ConsumerState<SubscriptionExpiredScreen> createState() => _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends ConsumerState<SubscriptionExpiredScreen> {
  final _transactionIdController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'EasyPaisa';
  bool _isSubmitting = false;
  bool _submitSuccess = false;
  String? _error;
  
  // Payment accounts loaded from Firestore
  List<Map<String, dynamic>> _paymentAccounts = [];
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentAccounts();
  }

  Future<void> _loadPaymentAccounts() async {
    try {
      Map<String, dynamic>? data;
      if (_isDesktop) {
        final client = FirestoreRestClient(projectId: 'cellaris-959');
        data = await client.getDocument('settings', 'subscription');
      } else {
        final doc = await flutter_firestore.FirebaseFirestore.instance
            .doc('settings/subscription')
            .get();
        data = doc.data();
      }

      if (data != null && data['paymentAccounts'] != null) {
        final accounts = (data['paymentAccounts'] as List)
            .where((a) => a['isActive'] == true)
            .toList();
        if (mounted) {
          setState(() {
            _paymentAccounts = accounts.cast<Map<String, dynamic>>();
            _loadingAccounts = false;
          });
        }
      } else {
        // Use default account
        if (mounted) {
          setState(() {
            _paymentAccounts = [
              {
                'accountHolderName': 'Hammad Munir',
                'accountNumber': '0311-9771180',
                'paymentMethod': 'EasyPaisa',
              }
            ];
            _loadingAccounts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAccounts = false);
      }
    }
  }

  Future<void> _submitTransactionId() async {
    final transactionId = _transactionIdController.text.trim();
    final accountHolder = _accountHolderController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    
    if (transactionId.isEmpty) {
      setState(() => _error = 'Please enter the transaction ID');
      return;
    }

    if (accountHolder.isEmpty) {
      setState(() => _error = 'Please enter your account holder name');
      return;
    }
    
    if (transactionId.length < 6) {
      setState(() => _error = 'Transaction ID seems too short. Please check and try again.');
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Update user document in Firestore with transaction details
      if (_isDesktop) {
        // Use REST API for desktop
        final client = FirestoreRestClient(projectId: 'cellaris-959');
        await client.updateDocument('users', user.id, {
          'status': 'pendingVerification',
          'payment': {
            'transactionId': transactionId,
            'accountHolderName': accountHolder,
            'method': _selectedPaymentMethod,
            'amount': amount,
            'submittedAt': DateTime.now(),
          },
          'updatedAt': DateTime.now(),
        });
      } else {
        // Use FlutterFire for web/mobile
        await flutter_firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'status': 'pendingVerification',
          'payment': {
            'transactionId': transactionId,
            'accountHolderName': accountHolder,
            'method': _selectedPaymentMethod,
            'amount': amount,
            'submittedAt': flutter_firestore.FieldValue.serverTimestamp(),
          },
          'updatedAt': flutter_firestore.FieldValue.serverTimestamp(),
        });
      }
      
      setState(() {
        _submitSuccess = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to submit. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    await ref.read(authControllerProvider.notifier).refreshSubscription();
    
    final authState = ref.read(authControllerProvider);
    if (authState.isSubscriptionValid && mounted) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription not yet verified. Please wait for admin approval.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _accountHolderController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors({
    required bool showTrialExpired,
    required bool showCanceled,
    required bool showPendingApproval,
  }) {
    if (showTrialExpired) {
      return [
        Colors.blue.withAlpha(38),
        Colors.black,
        Colors.black,
        Colors.indigo.withAlpha(13),
      ];
    }
    if (showCanceled) {
      return [
        Colors.grey.withAlpha(38),
        Colors.black,
        Colors.black,
        Colors.blueGrey.withAlpha(13),
      ];
    }
    if (showPendingApproval) {
      return [
        Colors.amber.withAlpha(38),
        Colors.black,
        Colors.black,
        Colors.orange.withAlpha(13),
      ];
    }
    // Default: expired
    return [
      Colors.orange.withAlpha(38),
      Colors.black,
      Colors.black,
      Colors.red.withAlpha(13),
    ];
  }

  String _getTitle({
    required bool showTrialExpired,
    required bool showCanceled,
    required bool showPendingApproval,
  }) {
    if (showTrialExpired) return 'Trial Ended';
    if (showCanceled) return 'Subscription Canceled';
    if (showPendingApproval) return 'Awaiting Approval';
    return 'Subscription Expired';
  }

  String _getSubtitle(String? userName, {
    required bool showTrialExpired,
    required bool showCanceled,
    required bool showPendingApproval,
  }) {
    final name = userName ?? 'User';
    if (showTrialExpired) {
      return 'Hello $name,\nYour 7-day trial has ended. Subscribe now to continue using Cellaris.';
    }
    if (showCanceled) {
      return 'Hello $name,\nYour subscription was canceled. You can reactivate by making a payment.';
    }
    if (showPendingApproval) {
      return 'Hello $name,\nYour account is pending admin approval. You will be notified once approved.';
    }
    return 'Hello $name,\nYour subscription has expired. Please renew to continue using Cellaris.';
  }

  IconData _getIcon({
    required bool showTrialExpired,
    required bool showCanceled,
    required bool showPendingApproval,
  }) {
    if (showTrialExpired) return LucideIcons.timer;
    if (showCanceled) return LucideIcons.xCircle;
    if (showPendingApproval) return LucideIcons.clock;
    return LucideIcons.alertTriangle;
  }

  Color _getIconColor({
    required bool showTrialExpired,
    required bool showCanceled,
    required bool showPendingApproval,
  }) {
    if (showTrialExpired) return Colors.blue;
    if (showCanceled) return Colors.grey;
    if (showPendingApproval) return Colors.amber;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    // Determine user state
    final isTrial = user?.status == UserStatus.trial;
    final isTrialExpired = isTrial && (user?.subscriptionExpiry.isBefore(DateTime.now()) ?? false);
    final isCanceled = user?.status == UserStatus.canceled;
    final isPendingVerification = user?.status == UserStatus.pendingVerification;
    final isPending = user?.status == UserStatus.pending;
    final isExpired = user?.status == UserStatus.expired;
    
    // Determine screen mode
    final showTrialExpired = isTrialExpired;
    final showCanceled = isCanceled;
    final showPendingApproval = isPending || isPendingVerification;
    final showExpired = isExpired || (!showTrialExpired && !showCanceled && !showPendingApproval);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(
              showTrialExpired: showTrialExpired,
              showCanceled: showCanceled,
              showPendingApproval: showPendingApproval,
            ),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeInDown(
              child: SizedBox(
                width: 520,
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon - different for pending vs expired
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: showPendingApproval 
                                ? Colors.amber.withAlpha(25)
                                : Colors.orange.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            showPendingApproval 
                                ? LucideIcons.clock
                                : LucideIcons.alertTriangle,
                            size: 48,
                            color: showPendingApproval ? Colors.amber : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title - different for pending vs expired
                        Text(
                          showPendingApproval 
                              ? 'Awaiting Approval'
                              : 'Subscription Expired',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          showPendingApproval
                              ? 'Hello ${user?.name ?? 'User'},\nYour account is pending admin approval. You will be notified once approved.'
                              : 'Hello ${user?.name ?? 'User'},\nYour subscription has expired. Please renew to continue using Cellaris.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        
                        // For pending users, show simpler UI
                        if (showPendingApproval) ...[
                          // Pending info box
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withAlpha(51)),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(LucideIcons.info, color: Colors.amber, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'What happens next?',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '1. Our admin team will review your registration\n'
                                  '2. Once approved, you will receive access to the app\n'
                                  '3. You can check your status by clicking refresh below',
                                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Refresh Status Button
                          PrimaryButton(
                            label: 'Check Approval Status',
                            onPressed: _refreshStatus,
                            icon: LucideIcons.refreshCw,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 16),
                          
                          // Contact Support
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Open support contact
                            },
                            icon: const Icon(LucideIcons.messageCircle, size: 18),
                            label: const Text('Contact Support'),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          ),
                        ] else ...[
                          // Existing flow for expired subscriptions
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 24),
                        
                        // Payment Details Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(LucideIcons.creditCard, color: AppTheme.primaryColor, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Payment Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildPaymentRow('Bank Name', 'HBL (Habib Bank)'),
                              _buildPaymentRow('Account Title', 'Cellaris Solutions'),
                              _buildPaymentRow('Account Number', '1234-5678-9012-3456'),
                              _buildPaymentRow('IBAN', 'PK00HABB1234567890123456'),
                              const Divider(color: Colors.white10, height: 32),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Monthly Subscription', style: TextStyle(color: Colors.grey)),
                                  Text(
                                    'Rs. 5,000/month',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Success Message or Form
                        if (_submitSuccess) ...[ 
                          FadeIn(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withAlpha(77)),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(LucideIcons.checkCircle, color: Colors.green, size: 24),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Transaction ID submitted successfully!',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Our team will verify your payment within 24 hours. You will receive access once verified.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _refreshStatus,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: const Text('Check Verification Status'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              side: BorderSide(color: AppTheme.primaryColor.withAlpha(128)),
                            ),
                          ),
                        ] else ...[
                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.info, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'After payment, enter your Transaction ID below for verification.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error Message
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Payment Method Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: const Icon(LucideIcons.wallet),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _paymentAccounts.isEmpty
                                ? <DropdownMenuItem<String>>[
                                    const DropdownMenuItem<String>(
                                      value: 'EasyPaisa',
                                      child: Text('EasyPaisa'),
                                    ),
                                  ]
                                : _paymentAccounts.map<DropdownMenuItem<String>>((account) {
                                    final method = (account['paymentMethod'] ?? 'EasyPaisa') as String;
                                    return DropdownMenuItem<String>(
                                      value: method,
                                      child: Text(method),
                                    );
                                  }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPaymentMethod = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Transaction ID Input
                          TextField(
                            controller: _transactionIdController,
                            decoration: InputDecoration(
                              labelText: 'Transaction ID / Receipt Number',
                              hintText: 'e.g., TXN123456789',
                              prefixIcon: const Icon(LucideIcons.hash),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(LucideIcons.copy, size: 18),
                                tooltip: 'Paste from clipboard',
                                onPressed: () async {
                                  final data = await Clipboard.getData('text/plain');
                                  if (data?.text != null) {
                                    _transactionIdController.text = data!.text!;
                                  }
                                },
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),

                          // Amount Input (Optional)
                          TextField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount Paid (Optional)',
                              hintText: 'e.g., 5000',
                              prefixIcon: const Icon(LucideIcons.banknote),
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          PrimaryButton(
                            label: _isSubmitting ? 'Submitting...' : 'Submit for Verification',
                            onPressed: _isSubmitting ? null : _submitTransactionId,
                            isLoading: _isSubmitting,
                            width: double.infinity,
                          ),
                        ],
                        ], // End of else for expired subscriptions
                        const SizedBox(height: 28),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 20),
                        
                        // Logout Button
                        TextButton.icon(
                          onPressed: () async {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (mounted) context.go('/login');
                          },
                          icon: const Icon(LucideIcons.logOut, size: 18),
                          label: const Text('Logout'),
                          style: TextButton.styleFrom(foregroundColor: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
