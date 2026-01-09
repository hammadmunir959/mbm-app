import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/features/suppliers/view/add_supplier_modal.dart';
import 'package:cellaris/features/suppliers/view/supplier_history_dialog.dart';

/// Suppliers Screen - Minimalist Design
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _search = '';
  String _filter = 'All'; // All, Active, Inactive
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierProvider);

    // Filter
    var filtered = suppliers.where((s) {
      if (_filter == 'Active' && !s.isActive) return false;
      if (_filter == 'Inactive' && s.isActive) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return s.name.toLowerCase().contains(q) || s.contact.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Stats
    final totalSuppliers = suppliers.length;
    final active = suppliers.where((s) => s.isActive).length;
    final inactive = suppliers.where((s) => !s.isActive).length;
    final totalBalance = suppliers.fold(0.0, (sum, s) => sum + s.balance);

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
                const Text('Suppliers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddSupplier(context),
                  icon: const Icon(LucideIcons.truck, size: 14),
                  label: const Text('Add Supplier', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // Stats + Search/Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStat('Total', totalSuppliers.toString(), Colors.blue),
                const SizedBox(width: 12),
                _buildStat('Active', active.toString(), Colors.green),
                const SizedBox(width: 12),
                _buildStat('Inactive', inactive.toString(), Colors.grey),
                const SizedBox(width: 12),
                _buildStat('Payable', 'Rs. ${_numberFormat.format(totalBalance)}', Colors.orange),
                const Spacer(),
                // Search
                SizedBox(
                  width: 200,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                      prefixIcon: Icon(LucideIcons.search, size: 14, color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(fontSize: 12),
                      items: ['All', 'Active', 'Inactive'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _filter = v ?? 'All'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: filtered.isEmpty
                  ? Center(child: Text('No suppliers found', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildSupplierRow(filtered[index]),
                    ),
            ),
          ),
        ],
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

  Widget _buildSupplierRow(Supplier supplier) {
    final statusColor = supplier.isActive ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showDialog(context: context, builder: (_) => SupplierHistoryDialog(supplier: supplier)),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Status indicator
                Container(width: 3, height: 28, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  child: Text(supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
                const SizedBox(width: 12),
                // Name & Contact Person
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(supplier.company, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // Status badge
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(supplier.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ),
                // Contact
                SizedBox(width: 120, child: Text(supplier.contact, style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
                // Email
                Expanded(child: Text(supplier.email ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                // Balance
                SizedBox(
                  width: 100,
                  child: Text(
                    'Rs. ${_numberFormat.format(supplier.balance)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: supplier.balance > 0 ? Colors.orange : Colors.grey[500]),
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.edit3, size: 14, color: Colors.grey[500]),
                      tooltip: 'Edit',
                      onPressed: () => _showAddSupplier(context, supplier: supplier),
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, size: 14, color: Colors.red[400]),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(supplier),
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSupplier(BuildContext context, {Supplier? supplier}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AddSupplierModal(supplier: supplier));
  }

  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Supplier'),
        content: Text('Delete "${supplier.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(supplierProvider.notifier).deleteSupplier(supplier.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
