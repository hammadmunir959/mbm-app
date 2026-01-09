import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/models/invoice.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/core/repositories/invoice_repository.dart';
import 'package:cellaris/features/pos/controller/returns_controller.dart';

/// Returns Screen - Feature-Rich Sleek Design
class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  int _tab = 0; // 0 = New Return, 1 = History
  final _searchController = TextEditingController();
  final _historySearchController = TextEditingController();
  Invoice? _selectedInvoice;
  final Map<String, int> _returnQtys = {};
  double _deductionPercent = 0;
  String _reason = '';
  bool _isProcessing = false;
  String _historySearch = '';
  final _f = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returnState = ref.watch(returnsProvider);
    final processedReturns = ref.read(returnsProvider.notifier).processedReturns;

    // Stats
    final totalReturns = processedReturns.length;
    final totalRefunded = processedReturns.fold(0.0, (sum, r) => sum + r.refundAmount);
    final totalItems = processedReturns.fold(0, (sum, r) => sum + r.quantity);

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
                const Text('Returns', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const SizedBox(width: 32),
                _buildTab('New Return', 0, LucideIcons.undo2),
                const SizedBox(width: 8),
                _buildTab('History', 1, LucideIcons.history),
                const Spacer(),
                if (returnState.isProcessing)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStat('Total Returns', '$totalReturns', Colors.orange),
                const SizedBox(width: 12),
                _buildStat('Items Returned', '$totalItems', Colors.blue),
                const SizedBox(width: 12),
                _buildStat('Total Refunded', 'Rs. ${_f.format(totalRefunded)}', Colors.green),
                if (_tab == 1) ...[
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    height: 36,
                    child: TextField(
                      controller: _historySearchController,
                      onChanged: (v) => setState(() => _historySearch = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search history...',
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                        prefixIcon: Icon(LucideIcons.search, size: 14, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: _tab == 0 ? _buildNewReturnView() : _buildHistoryView(processedReturns),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final selected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: selected ? AppTheme.primaryColor : Colors.grey[500]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppTheme.primaryColor : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // New Return View
  // ==========================================
  Widget _buildNewReturnView() {
    return Row(
      children: [
        // Left: Invoice Search & Details
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Find Invoice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter Invoice No (e.g., SI-000001)',
                                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                                prefixIcon: Icon(LucideIcons.search, size: 14, color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              onSubmitted: (_) => _searchInvoice(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _searchInvoice,
                            icon: const Icon(LucideIcons.search, size: 14),
                            label: const Text('Search', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Invoice details or empty state
                Expanded(
                  child: _selectedInvoice == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.fileSearch, size: 48, color: Colors.grey[700]),
                              const SizedBox(height: 12),
                              Text('Search for a sale invoice', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              Text('Enter the invoice number to process a return', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : _buildInvoiceDetails(),
                ),
              ],
            ),
          ),
        ),

        // Right: Return Form
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: _selectedInvoice == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.clipboardX, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('No invoice selected', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : _buildReturnForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetails() {
    final inv = _selectedInvoice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: Row(
            children: [
              Container(width: 3, height: 30, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.billNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                  Text(inv.partyName ?? 'Walk-in Customer', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${_f.format(inv.summary.netValue)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
                  Text(DateFormat('MMM dd, yyyy').format(inv.date), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),

        // Items header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text('Select Items to Return', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (final item in inv.items) {
                      _returnQtys[item.id] = item.quantity;
                    }
                  });
                },
                icon: const Icon(LucideIcons.checkSquare, size: 12),
                label: const Text('Select All', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _returnQtys.clear()),
                icon: const Icon(LucideIcons.xSquare, size: 12),
                label: const Text('Clear', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: inv.items.length,
            itemBuilder: (context, index) => _buildItemRow(inv.items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(InvoiceLineItem item) {
    final returnQty = _returnQtys[item.id] ?? 0;
    final isSelected = returnQty > 0;
    final unitPrice = item.lineTotal / item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSelected ? Colors.orange.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    const SizedBox(width: 8),
                    Text('@ Rs. ${_f.format(unitPrice)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    if (item.imei != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                        child: Text(item.imei!, style: const TextStyle(fontSize: 8, color: Colors.blue, fontFamily: 'monospace')),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Return value preview
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('Rs. ${_f.format(unitPrice * returnQty)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
            ),
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.minus, size: 12, color: returnQty > 0 ? Colors.orange : Colors.grey[700]),
                  onPressed: returnQty > 0 ? () => setState(() => _returnQtys[item.id] = returnQty - 1) : null,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text('$returnQty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.orange : Colors.grey[500])),
                ),
                IconButton(
                  icon: Icon(LucideIcons.plus, size: 12, color: returnQty < item.quantity ? Colors.orange : Colors.grey[700]),
                  onPressed: returnQty < item.quantity ? () => setState(() => _returnQtys[item.id] = returnQty + 1) : null,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnForm() {
    final totalItems = _returnQtys.values.fold(0, (a, b) => a + b);
    final returnValue = _calculateReturnValue();
    final deductionAmount = returnValue * (_deductionPercent / 100);
    final finalRefund = returnValue - deductionAmount;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
          child: Row(
            children: [
              Icon(LucideIcons.undo2, size: 16, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text('Return Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(child: _summaryCard('Items', '$totalItems', Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _summaryCard('Value', 'Rs. ${_f.format(returnValue)}', Colors.purple)),
                  ],
                ),

                const SizedBox(height: 20),

                // Deduction slider
                const Text('Deduction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Apply restocking fee or damage deduction', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: Colors.orange,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                          thumbColor: Colors.orange,
                        ),
                        child: Slider(
                          value: _deductionPercent,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          onChanged: (v) => setState(() => _deductionPercent = v),
                        ),
                      ),
                    ),
                    Container(
                      width: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text('${_deductionPercent.toInt()}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                    ),
                  ],
                ),
                if (_deductionPercent > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Deduction: Rs. ${_f.format(deductionAmount)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ),

                const SizedBox(height: 20),

                // Reason
                const Text('Return Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter reason for return (defective, wrong item, customer request, etc.)',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (v) => _reason = v,
                ),

                const SizedBox(height: 24),

                // Final Refund
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Refund', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text('Customer will receive', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                      Text('Rs. ${_f.format(finalRefund)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Process button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedInvoice = null;
                    _returnQtys.clear();
                    _deductionPercent = 0;
                    _reason = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(LucideIcons.x, size: 14),
                label: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: totalItems > 0 && !_isProcessing ? _processReturn : null,
                icon: _isProcessing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.check, size: 14),
                label: Text(_isProcessing ? 'Processing...' : 'Process Return', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ==========================================
  // History View
  // ==========================================
  Widget _buildHistoryView(List<ReturnRequest> returns) {
    // Filter by search
    var filtered = returns;
    if (_historySearch.isNotEmpty) {
      final q = _historySearch.toLowerCase();
      filtered = returns.where((r) => r.id.toLowerCase().contains(q) || r.saleId.toLowerCase().contains(q) || (r.customerName ?? '').toLowerCase().contains(q)).toList();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text('Return No', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                SizedBox(width: 100, child: Text('Invoice', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                Expanded(child: Text('Customer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                SizedBox(width: 80, child: Text('Items', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                SizedBox(width: 100, child: Text('Refund', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                SizedBox(width: 100, child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              ],
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No returns found', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildHistoryRow(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(ReturnRequest r) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReturnDetails(r),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 3, height: 28, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                SizedBox(width: 88, child: Text(r.id.length > 12 ? '${r.id.substring(0, 10)}...' : r.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'monospace'))),
                SizedBox(width: 100, child: Text(r.saleId, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontFamily: 'monospace'))),
                Expanded(child: Text(r.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                SizedBox(width: 80, child: Text('${r.quantity} items', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                SizedBox(width: 100, child: Text('Rs. ${_f.format(r.refundAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange))),
                SizedBox(width: 100, child: Text(DateFormat('MMM dd, yyyy').format(r.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Completed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.green), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReturnDetails(ReturnRequest r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Return Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Return ID', r.id),
              _detailRow('Original Invoice', r.saleId),
              _detailRow('Customer', r.customerName ?? 'Walk-in'),
              _detailRow('Product', r.productName),
              _detailRow('Quantity', '${r.quantity} items'),
              _detailRow('Refund Amount', 'Rs. ${_f.format(r.refundAmount)}'),
              _detailRow('Reason', r.reason.isNotEmpty ? r.reason : 'Not specified'),
              _detailRow('Date', DateFormat('MMM dd, yyyy @ hh:mm a').format(r.createdAt)),
              _detailRow('Status', r.status.name.toUpperCase()),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ==========================================
  // Actions
  // ==========================================
  void _searchInvoice() async {
    final billNo = _searchController.text.trim();
    if (billNo.isEmpty) return;

    final repository = ref.read(invoiceRepositoryProvider);
    final invoice = await repository.getByBillNo(billNo);

    if (invoice != null && invoice.type == InvoiceType.sale) {
      setState(() {
        _selectedInvoice = invoice;
        _returnQtys.clear();
        _deductionPercent = 0;
        _reason = '';
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(invoice == null ? 'Invoice not found' : 'Only sale invoices can be returned'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double _calculateReturnValue() {
    if (_selectedInvoice == null) return 0;
    double total = 0;
    for (final item in _selectedInvoice!.items) {
      final qty = _returnQtys[item.id] ?? 0;
      if (qty > 0) total += (item.lineTotal / item.quantity) * qty;
    }
    return total;
  }

  void _processReturn() async {
    if (_selectedInvoice == null || _returnQtys.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      await ref.read(returnsProvider.notifier).processReturn(
            originalInvoice: _selectedInvoice!,
            returnQuantities: _returnQtys,
            deductionPercent: _deductionPercent,
            reason: _reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return processed successfully'), backgroundColor: Colors.green));
        setState(() {
          _selectedInvoice = null;
          _returnQtys.clear();
          _deductionPercent = 0;
          _reason = '';
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
