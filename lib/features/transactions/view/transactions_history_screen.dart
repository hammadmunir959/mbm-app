import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/transactions/controller/transaction_controller.dart';
import 'package:intl/intl.dart';

/// Transactions History Screen - Minimalist Design
class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends ConsumerState<TransactionsHistoryScreen> {
  TransactionType? _filterType;
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionLogProvider);
    final filtered = _getFilteredTransactions(allTransactions);
    
    // Stats
    final totalIncome = filtered.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filtered.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                const Text('Transactions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const Spacer(),
                // Summary chips
                _buildStat('Income', totalIncome, Colors.green),
                const SizedBox(width: 16),
                _buildStat('Expense', totalExpense, Colors.red),
                const SizedBox(width: 16),
                _buildStat('Net', totalIncome - totalExpense, totalIncome >= totalExpense ? Colors.teal : Colors.orange),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
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
                    child: DropdownButton<TransactionType?>(
                      value: _filterType,
                      hint: Text('All Types', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(fontSize: 12),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Types')),
                        ...TransactionType.values.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t)))),
                      ],
                      onChanged: (v) => setState(() => _filterType = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Date Range
                InkWell(
                  onTap: _selectDateRange,
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
                          _dateRange == null
                              ? 'All Time'
                              : '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        if (_dateRange != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _dateRange = null),
                            child: Icon(LucideIcons.x, size: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildTransactionRow(filtered[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(
            'Rs. ${_numberFormat.format(value)}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 40, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text('No transactions', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Transactions will appear here as you make sales and purchases.', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(TransactionLog tx) {
    final isIncome = tx.isIncome;
    final typeColor = _getTypeColor(tx.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(tx),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Type indicator
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Date
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM dd').format(tx.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      Text(DateFormat('HH:mm').format(tx.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Type Badge
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _typeLabel(tx.type),
                    style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                // Reference
                SizedBox(
                  width: 100,
                  child: Text(
                    tx.referenceNumber ?? '#${tx.id.substring(0, 8)}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Party
                Expanded(
                  child: Text(
                    tx.partyName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Items count
                SizedBox(
                  width: 60,
                  child: Text('${tx.items.length} items', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                // Amount
                SizedBox(
                  width: 100,
                  child: Text(
                    '${isIncome ? '+' : '-'} Rs. ${_numberFormat.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isIncome ? Colors.green[400] : Colors.red[400],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(tx.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.status.name,
                    style: TextStyle(fontSize: 9, color: _getStatusColor(tx.status), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(TransactionLog tx) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tx.referenceNumber ?? '#${tx.id.substring(0, 8)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getTypeColor(tx.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(_typeLabel(tx.type), style: TextStyle(fontSize: 10, color: _getTypeColor(tx.type), fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(tx.timestamp)),
              _detailRow('Party', tx.partyName),
              _detailRow('Amount', 'Rs. ${_numberFormat.format(tx.amount)}'),
              _detailRow('Payment', tx.paymentMethod ?? 'N/A'),
              _detailRow('Status', tx.status.name.toUpperCase()),
              if (tx.notes != null) _detailRow('Notes', tx.notes!),
              const SizedBox(height: 16),
              if (tx.items.isNotEmpty) ...[
                Text('Items', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 8),
                ...tx.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 12))),
                      Text('${item.quantity} x Rs. ${_numberFormat.format(item.unitPrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                      Text('Rs. ${_numberFormat.format(item.total)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ],
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

  List<TransactionLog> _getFilteredTransactions(List<TransactionLog> all) {
    var filtered = all.toList();

    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_dateRange != null) {
      filtered = filtered.where((t) =>
        t.timestamp.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        t.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
        t.id.toLowerCase().contains(q) ||
        (t.referenceNumber?.toLowerCase().contains(q) ?? false) ||
        t.partyName.toLowerCase().contains(q) ||
        t.items.any((i) => i.productName.toLowerCase().contains(q))
      ).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.primaryColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.sale: return 'Sale';
      case TransactionType.purchase: return 'Purchase';
      case TransactionType.buyback: return 'Buyback';
      case TransactionType.repair: return 'Repair';
      case TransactionType.return_: return 'Return';
      case TransactionType.stockAdjustment: return 'Adjustment';
      case TransactionType.purchaseOrder: return 'PO';
    }
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.sale: return Colors.green;
      case TransactionType.purchase: return Colors.blue;
      case TransactionType.buyback: return Colors.teal;
      case TransactionType.repair: return Colors.orange;
      case TransactionType.return_: return Colors.red;
      case TransactionType.stockAdjustment: return Colors.purple;
      case TransactionType.purchaseOrder: return Colors.indigo;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return Colors.green;
      case TransactionStatus.pending: return Colors.orange;
      case TransactionStatus.cancelled: return Colors.red;
      case TransactionStatus.refunded: return Colors.purple;
    }
  }
}
