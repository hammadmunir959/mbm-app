import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/voucher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controller/accounts_providers.dart';
import '../../model/accounts_state.dart';

/// Voucher list view - Minimalist Design
class VoucherListView extends ConsumerStatefulWidget {
  const VoucherListView({super.key});

  @override
  ConsumerState<VoucherListView> createState() => _VoucherListViewState();
}

class _VoucherListViewState extends ConsumerState<VoucherListView> {
  VoucherType? _filterType;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = VoucherFilter(
      type: _filterType,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    final vouchersAsync = ref.watch(vouchersProvider(filter));

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            // Filter Bar
            _buildFilterBar(),
            
            // Voucher List
            Expanded(
              child: vouchersAsync.when(
                data: (vouchers) {
                  var filtered = vouchers;
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((v) =>
                      v.voucherNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (v.partyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                    ).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.receipt, size: 40, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text('No vouchers', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildVoucherRow(filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Colors.red[400]))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          // Search
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

          // Type Filter
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<VoucherType?>(
                value: _filterType,
                hint: Text('All Types', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(fontSize: 12),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...VoucherType.values.map((t) => DropdownMenuItem(value: t, child: Text(_typeName(t)))),
                ],
                onChanged: (v) => setState(() => _filterType = v),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Date Range
          InkWell(
            onTap: () => _selectDateRange(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd').format(_fromDate)} - ${DateFormat('MMM dd').format(_toDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherRow(Voucher voucher) {
    final isPayment = voucher.type.name.contains('Payment');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVoucherDetails(voucher),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Type indicator
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPayment ? Colors.red[700] : Colors.green[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Voucher No
                SizedBox(
                  width: 100,
                  child: Text(
                    voucher.voucherNo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[400]),
                  ),
                ),
                // Type
                SizedBox(
                  width: 100,
                  child: Text(
                    _typeName(voucher.type),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                // Party/Description
                Expanded(
                  child: Text(
                    voucher.partyName ?? voucher.narration ?? '-',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Amount
                SizedBox(
                  width: 100,
                  child: Text(
                    'Rs. ${_numberFormat.format(voucher.totalAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPayment ? Colors.red[400] : Colors.green[400],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16),
                // Date
                Text(
                  DateFormat('MMM dd').format(voucher.date),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeName(VoucherType type) {
    switch (type) {
      case VoucherType.cashPayment: return 'Cash Pay';
      case VoucherType.cashReceipt: return 'Cash Rcpt';
      case VoucherType.bankPayment: return 'Bank Pay';
      case VoucherType.bankReceipt: return 'Bank Rcpt';
      case VoucherType.partyPayment: return 'Party Pay';
      case VoucherType.partyReceipt: return 'Party Rcpt';
      case VoucherType.journalVoucher: return 'Journal';
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  void _showVoucherDetails(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(voucher.voucherNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Type', _typeName(voucher.type)),
              _detailRow('Date', DateFormat('MMM dd, yyyy').format(voucher.date)),
              _detailRow('Amount', 'Rs. ${_numberFormat.format(voucher.totalAmount)}'),
              if (voucher.partyName != null) _detailRow('Party', voucher.partyName!),
              if (voucher.narration != null) _detailRow('Narration', voucher.narration!),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Text('Entries', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 8),
              ...voucher.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(e.accountName, style: const TextStyle(fontSize: 12))),
                    SizedBox(width: 60, child: Text(e.debit > 0 ? 'Dr ${_numberFormat.format(e.debit)}' : '', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                    SizedBox(width: 60, child: Text(e.credit > 0 ? 'Cr ${_numberFormat.format(e.credit)}' : '', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
