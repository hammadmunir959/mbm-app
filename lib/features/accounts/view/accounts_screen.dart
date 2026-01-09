import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/models/voucher.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/accounts_providers.dart';
import '../model/accounts_state.dart';
import 'chart_of_accounts_view.dart';
import 'vouchers/voucher_list_view.dart';
import 'vouchers/voucher_form_dialog.dart';
import 'reports/reports_menu_view.dart';

/// Main screen for the Accounts module - Minimalist Design
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> with SingleTickerProviderStateMixin {
  AccountsViewMode _currentMode = AccountsViewMode.chartOfAccounts;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentMode = AccountsViewMode.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cashBalance = ref.watch(cashBalanceProvider(null));
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Minimal Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                // Title
                const Text(
                  'Accounts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                ),
                const SizedBox(width: 32),
                
                // Simple Tab Row
                _buildTab('Chart of Accounts', 0),
                const SizedBox(width: 4),
                _buildTab('Vouchers', 1),
                const SizedBox(width: 4),
                _buildTab('Reports', 2),
                
                const Spacer(),
                
                // Cash Balance - Subtle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.wallet, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cash', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                          cashBalance.when(
                            data: (v) => Text(
                              'Rs. ${numberFormat.format(v)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: v >= 0 ? Colors.white : Colors.red[400],
                              ),
                            ),
                            loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                            error: (_, __) => const Text('--', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Voucher Quick Actions (only on vouchers tab)
          if (_currentMode == AccountsViewMode.vouchers) _buildVoucherActions(),
          
          // Content
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: const [
                ChartOfAccountsView(),
                VoucherListView(),
                ReportsMenuView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabController.index == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentMode = AccountsViewMode.values[index]);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Text('New:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 12),
          _buildVoucherBtn('Cash Receipt', Colors.green[700]!, VoucherType.cashReceipt),
          const SizedBox(width: 8),
          _buildVoucherBtn('Cash Payment', Colors.red[700]!, VoucherType.cashPayment),
          const SizedBox(width: 8),
          _buildVoucherBtn('Bank Receipt', Colors.teal[700]!, VoucherType.bankReceipt),
          const SizedBox(width: 8),
          _buildVoucherBtn('Bank Payment', Colors.orange[700]!, VoucherType.bankPayment),
          const SizedBox(width: 8),
          _buildVoucherBtn('Journal', Colors.grey[600]!, VoucherType.journalVoucher),
        ],
      ),
    );
  }

  Widget _buildVoucherBtn(String label, Color color, VoucherType type) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showVoucherDialog(type),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void _showVoucherDialog(VoucherType type) async {
    ref.read(selectedVoucherTypeProvider.notifier).state = type;
    final result = await showVoucherFormDialog(context, type);
    if (result != null) {
      ref.invalidate(vouchersProvider);
      ref.invalidate(cashBalanceProvider);
    }
  }
}
