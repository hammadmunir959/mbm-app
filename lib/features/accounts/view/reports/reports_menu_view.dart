import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../model/accounts_state.dart';
import 'account_ledger_report.dart';
import 'trial_balance_report.dart';
import 'profit_loss_report.dart';
import 'aging_report.dart';

/// Reports menu - Minimalist Design
class ReportsMenuView extends ConsumerWidget {
  const ReportsMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildReportCard(context, 'Account Ledger', LucideIcons.bookOpen, ReportType.accountLedger),
              _buildReportCard(context, 'Trial Balance', LucideIcons.scale, ReportType.trialBalance),
              _buildReportCard(context, 'Profit & Loss', LucideIcons.trendingUp, ReportType.profitLoss),
              _buildReportCard(context, 'Aging Receivables', LucideIcons.users, ReportType.agingReceivables),
              _buildReportCard(context, 'Aging Payables', LucideIcons.truck, ReportType.agingPayables),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, ReportType type) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openReport(context, type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReport(BuildContext context, ReportType type) {
    switch (type) {
      case ReportType.accountLedger:
        showAccountLedgerReport(context);
        break;
      case ReportType.trialBalance:
        showTrialBalanceReport(context);
        break;
      case ReportType.profitLoss:
        showProfitLossReport(context);
        break;
      case ReportType.agingReceivables:
        showAgingReport(context, AgingType.receivables);
        break;
      case ReportType.agingPayables:
        showAgingReport(context, AgingType.payables);
        break;
    }
  }
}
