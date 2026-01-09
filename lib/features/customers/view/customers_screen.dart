import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/features/customers/view/add_customer_modal.dart';
import 'package:cellaris/features/customers/view/customer_history_dialog.dart';

/// Customers Screen - Minimalist Design
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';
  String _filter = 'All'; // All, Wholesale, Retail
  final _searchController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);

    // Filter
    var filtered = customers.where((c) {
      if (_filter == 'Wholesale' && !c.isWholesale) return false;
      if (_filter == 'Retail' && c.isWholesale) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return c.name.toLowerCase().contains(q) || c.contact.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Stats
    final totalCustomers = customers.length;
    final wholesale = customers.where((c) => c.isWholesale).length;
    final retail = customers.where((c) => !c.isWholesale).length;
    final totalBalance = customers.fold(0.0, (sum, c) => sum + c.balance);

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
                const Text('Customers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomer(context),
                  icon: const Icon(LucideIcons.userPlus, size: 14),
                  label: const Text('Add Customer', style: TextStyle(fontSize: 12)),
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
                _buildStat('Total', totalCustomers.toString(), Colors.blue),
                const SizedBox(width: 12),
                _buildStat('Wholesale', wholesale.toString(), Colors.purple),
                const SizedBox(width: 12),
                _buildStat('Retail', retail.toString(), Colors.green),
                const SizedBox(width: 12),
                _buildStat('Balance', 'Rs. ${_numberFormat.format(totalBalance)}', totalBalance >= 0 ? Colors.teal : Colors.red),
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
                      items: ['All', 'Wholesale', 'Retail'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
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
                  ? Center(child: Text('No customers found', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildCustomerRow(filtered[index]),
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

  Widget _buildCustomerRow(Customer customer) {
    final typeColor = customer.isWholesale ? Colors.purple : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showDialog(context: context, builder: (_) => CustomerHistoryDialog(customer: customer)),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Type indicator
                Container(width: 3, height: 28, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                ),
                const SizedBox(width: 12),
                // Name & Tax ID
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      if (customer.taxId != null) Text(customer.taxId!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // Type badge
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(customer.isWholesale ? 'Wholesale' : 'Retail', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                  ),
                ),
                // Contact
                SizedBox(width: 120, child: Text(customer.contact, style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
                // Email
                Expanded(child: Text(customer.email ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                // Balance
                SizedBox(
                  width: 100,
                  child: Text(
                    'Rs. ${_numberFormat.format(customer.balance)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: customer.balance >= 0 ? Colors.green : Colors.red),
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.edit3, size: 14, color: Colors.grey[500]),
                      tooltip: 'Edit',
                      onPressed: () => _showAddCustomer(context, customer: customer),
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, size: 14, color: Colors.red[400]),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(customer),
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

  void _showAddCustomer(BuildContext context, {Customer? customer}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => AddCustomerModal(customer: customer));
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(customerProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
