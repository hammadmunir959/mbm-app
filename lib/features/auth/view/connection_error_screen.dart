import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/widgets/primary_button.dart';
import 'package:cellaris/main.dart';
import 'dart:io';

/// Connection Error Screen
/// Displayed when Firebase fails to initialize.
/// Production-grade: Shows error details and requires restart for retry.
class ConnectionErrorScreen extends ConsumerWidget {
  const ConnectionErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseError = ref.watch(firebaseErrorProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withAlpha(26),
              Colors.black,
              Colors.black,
              Colors.red.withAlpha(13),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withAlpha(51)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withAlpha(51)),
                  ),
                  child: const Icon(
                    LucideIcons.wifiOff,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Title
                const Text(
                  'Connection Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Description
                const Text(
                  'Unable to establish a secure connection to the authentication service. '
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Error Details (expandable)
                if (firebaseError != null) ...[
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(LucideIcons.alertCircle, size: 16, color: Colors.orange.withAlpha(179)),
                        const SizedBox(width: 8),
                        Text(
                          'Technical Details',
                          style: TextStyle(
                            color: Colors.orange.withAlpha(179),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(77),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withAlpha(13)),
                        ),
                        child: SelectableText(
                          firebaseError,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Troubleshooting steps
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withAlpha(38)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.lightbulb, size: 16, color: Colors.blue[300]),
                          const SizedBox(width: 8),
                          Text(
                            'Troubleshooting',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStep('1', 'Check your internet connection'),
                      _buildStep('2', 'Verify firewall isn\'t blocking the app'),
                      _buildStep('3', 'Restart the application'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Restart Button
                PrimaryButton(
                  label: 'Restart Application',
                  width: double.infinity,
                  icon: LucideIcons.refreshCw,
                  onPressed: () {
                    // Exit the app - user needs to restart
                    exit(0);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Support Contact
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open support URL or email
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact support: support@cellaris.app'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: Icon(LucideIcons.headphones, size: 16, color: Colors.grey[400]),
                  label: Text(
                    'Contact Support',
                    style: TextStyle(color: Colors.grey[400]),
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

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(38),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
