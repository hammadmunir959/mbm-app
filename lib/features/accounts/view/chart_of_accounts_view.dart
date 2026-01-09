import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/models/account.dart';
import '../../../core/repositories/account_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/accounts_providers.dart';
import 'account_form_dialog.dart';
import 'reports/account_ledger_report.dart';
import 'account_group_form_dialog.dart';

/// Chart of Accounts view - Minimalist Design
class ChartOfAccountsView extends ConsumerStatefulWidget {
  const ChartOfAccountsView({super.key});

  @override
  ConsumerState<ChartOfAccountsView> createState() => _ChartOfAccountsViewState();
}

class _ChartOfAccountsViewState extends ConsumerState<ChartOfAccountsView> {
  String _searchQuery = '';
  int? _selectedGroupId;
  int _selectedLevel = 0;
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider(null));
    final groupsAsync = ref.watch(accountGroupsProvider);

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Sidebar
          _buildSidebar(groupsAsync),
          const SizedBox(width: 16),
          
          // Main Panel
          Expanded(child: _buildMainPanel(accountsAsync)),
        ],
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<List<AccountGroup>> groupsAsync) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Groups', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                InkWell(
                  onTap: () => _showAddGroupDialog(context),
                  child: Icon(LucideIcons.plus, size: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          Expanded(
            child: groupsAsync.when(
              data: (groups) => ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _buildGroupItem(null, 'All Accounts', null),
                  const SizedBox(height: 4),
                  ...groups.map((g) => _buildGroupItem(g.id, g.name, g.type)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error', style: TextStyle(color: Colors.red[400], fontSize: 12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem(int? id, String name, AccountType? type) {
    final isSelected = _selectedGroupId == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedGroupId = id),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildMainPanel(AsyncValue<List<Account>> accountsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        prefixIcon: Icon(LucideIcons.search, size: 16, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Level filters
                ...['All', '1', '2', '3'].asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildLevelChip(e.key, e.value),
                )),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _showAddAccountDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                var filtered = accounts;
                if (_selectedGroupId != null) filtered = filtered.where((a) => a.groupId == _selectedGroupId).toList();
                if (_selectedLevel > 0) filtered = filtered.where((a) => a.level == _selectedLevel).toList();
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((a) =>
                    a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.accountNo.contains(_searchQuery)
                  ).toList();
                }
                filtered.sort((a, b) => a.accountNo.compareTo(b.accountNo));

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.inbox, size: 40, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('No accounts', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildAccountRow(filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red[400]))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(int index, String label) {
    final isSelected = _selectedLevel == index;
    return InkWell(
      onTap: () => setState(() => _selectedLevel = index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRow(Account account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountLedger(account),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    account.accountNo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                SizedBox(width: (account.level - 1) * 16.0),
                Expanded(
                  child: Text(
                    account.title,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Rs. ${_numberFormat.format(account.currentBalance)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: account.currentBalance >= 0 ? Colors.grey[400] : Colors.red[400],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _showEditAccountDialog(context, account),
                  child: Icon(LucideIcons.edit2, size: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _deleteAccount(context, account),
                  child: Icon(LucideIcons.trash2, size: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context) async {
    await showAccountFormDialog(context);
    ref.invalidate(accountsProvider);
  }

  Future<void> _showEditAccountDialog(BuildContext context, Account account) async {
    await showAccountFormDialog(context, editAccount: account);
    ref.invalidate(accountsProvider);
  }

  Future<void> _deleteAccount(BuildContext context, Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete?'),
        content: Text('Delete "${account.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(accountRepositoryProvider).delete(account.accountNo);
      ref.invalidate(accountsProvider);
    }
  }

  void _showAccountLedger(Account account) => showAccountLedgerReport(context, account: account);

  Future<void> _showAddGroupDialog(BuildContext context) async {
    await showAccountGroupFormDialog(context);
    ref.invalidate(accountGroupsProvider);
  }
}
