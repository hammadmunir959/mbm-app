import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/features/inventory/controller/purchase_order_controller.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';

/// Low Stock Tab - Feature-Rich with PO Integration
class LowStockTab extends ConsumerStatefulWidget {
  const LowStockTab({super.key});

  @override
  ConsumerState<LowStockTab> createState() => _LowStockTabState();
}

class _LowStockTabState extends ConsumerState<LowStockTab> {
  String _filter = 'All'; // All, Out of Stock, Low Stock
  final _selectedProducts = <String>{}; // For batch PO creation
  final _f = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final suppliers = ref.watch(supplierProvider);

    // Filter low and out of stock
    final outOfStock = products.where((p) => p.stock == 0).toList();
    final lowStock = products.where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).toList();
    final allAlerts = [...outOfStock, ...lowStock];

    // Apply filter
    List<Product> filtered;
    switch (_filter) {
      case 'Out of Stock':
        filtered = outOfStock;
        break;
      case 'Low Stock':
        filtered = lowStock;
        break;
      default:
        filtered = allAlerts;
    }

    // Calculate reorder cost
    final totalReorderCost = allAlerts.fold(0.0, (sum, p) {
      final qty = p.lowStockThreshold - p.stock + 10;
      return sum + (p.purchasePrice * qty);
    });

    return Column(
      children: [
        // Stats + Actions Row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStat('Out of Stock', '${outOfStock.length}', Colors.red, LucideIcons.xCircle),
              const SizedBox(width: 12),
              _buildStat('Low Stock', '${lowStock.length}', Colors.orange, LucideIcons.alertTriangle),
              const SizedBox(width: 12),
              _buildStat('Total Alerts', '${allAlerts.length}', Colors.amber, LucideIcons.bell),
              const SizedBox(width: 12),
              _buildStat('Est. Reorder', 'Rs. ${_f.format(totalReorderCost)}', Colors.teal, LucideIcons.shoppingCart),
              const Spacer(),
              // Filter dropdown
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
                    items: ['All', 'Out of Stock', 'Low Stock'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _filter = v ?? 'All'),
                  ),
                ),
              ),
              if (_selectedProducts.isNotEmpty) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showBatchPODialog(filtered.where((p) => _selectedProducts.contains(p.id)).toList(), suppliers),
                  icon: const Icon(LucideIcons.shoppingCart, size: 14),
                  label: Text('Create PO (${_selectedProducts.length})', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Select all / Clear
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text('${filtered.length} items need attention', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() {
                    if (_selectedProducts.length == filtered.length) {
                      _selectedProducts.clear();
                    } else {
                      _selectedProducts.addAll(filtered.map((p) => p.id));
                    }
                  }),
                  icon: Icon(_selectedProducts.length == filtered.length ? LucideIcons.checkSquare : LucideIcons.square, size: 12),
                  label: Text(_selectedProducts.length == filtered.length ? 'Deselect All' : 'Select All', style: const TextStyle(fontSize: 10)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),

        // Alerts List
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.packageCheck, size: 48, color: Colors.green[400]),
                        const SizedBox(height: 12),
                        Text('All products are well stocked!', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('No items need reordering', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 32), // Checkbox
                            const SizedBox(width: 20), // Status icon
                            Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                            SizedBox(width: 70, child: Text('Current', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                            SizedBox(width: 70, child: Text('Reorder At', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                            SizedBox(width: 70, child: Text('Order Qty', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                            SizedBox(width: 100, child: Text('Est. Cost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
                            const SizedBox(width: 120), // Actions
                          ],
                        ),
                      ),
                      // List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildAlertRow(filtered[index], suppliers),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(Product product, List<Supplier> suppliers) {
    final isOut = product.stock == 0;
    final color = isOut ? Colors.red : Colors.orange;
    final reorderQty = product.lowStockThreshold - product.stock + 10;
    final estCost = product.purchasePrice * reorderQty;
    final isSelected = _selectedProducts.contains(product.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedProducts.remove(product.id);
            } else {
              _selectedProducts.add(product.id);
            }
          }),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedProducts.add(product.id);
                    } else {
                      _selectedProducts.remove(product.id);
                    }
                  }),
                  activeColor: Colors.teal,
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                // Alert icon
                Icon(isOut ? LucideIcons.xCircle : LucideIcons.alertTriangle, size: 16, color: color),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text(product.brand ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                            child: Text(isOut ? 'OUT' : 'LOW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Current Stock
                SizedBox(
                  width: 70,
                  child: Text('${product.stock}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                ),
                // Reorder Point
                SizedBox(
                  width: 70,
                  child: Text('${product.lowStockThreshold}', style: const TextStyle(fontSize: 12)),
                ),
                // Suggested Order
                SizedBox(
                  width: 70,
                  child: Text('+$reorderQty', style: TextStyle(fontSize: 12, color: Colors.green[400], fontWeight: FontWeight.w500)),
                ),
                // Cost
                SizedBox(
                  width: 100,
                  child: Text('Rs. ${_f.format(estCost)}', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ),
                // Quick actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showQuickPODialog(product, reorderQty, suppliers),
                      icon: const Icon(LucideIcons.shoppingCart, size: 12),
                      label: const Text('Reorder', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        minimumSize: const Size(0, 28),
                      ),
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

  void _showQuickPODialog(Product product, int suggestedQty, List<Supplier> suppliers) {
    final qtyController = TextEditingController(text: suggestedQty.toString());
    Supplier? selectedSupplier = suppliers.isNotEmpty ? suppliers.first : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E293B),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Reorder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(width: 3, height: 24, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Current stock: ${product.stock}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (suppliers.isNotEmpty) ...[
                  const Text('Supplier', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Supplier>(
                    value: selectedSupplier,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setDialogState(() => selectedSupplier = v),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Order Quantity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Cost preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Cost', style: TextStyle(fontSize: 12)),
                      Text('Rs. ${_f.format(product.purchasePrice * (int.tryParse(qtyController.text) ?? 0))}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _createPurchaseOrder(ctx, selectedSupplier, [product], [int.tryParse(qtyController.text) ?? suggestedQty]),
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: const Text('Create PO'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
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

  void _showBatchPODialog(List<Product> products, List<Supplier> suppliers) {
    Supplier? selectedSupplier = suppliers.isNotEmpty ? suppliers.first : null;
    final quantities = <String, int>{for (var p in products) p.id: p.lowStockThreshold - p.stock + 10};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E293B),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Batch PO (${products.length} items)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (suppliers.isNotEmpty) ...[
                  const Text('Supplier', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Supplier>(
                    value: selectedSupplier,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                    items: suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setDialogState(() => selectedSupplier = v),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Items', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (ctx, index) {
                        final p = products[index];
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontSize: 12)),
                          subtitle: Text('Cost: Rs. ${_f.format(p.purchasePrice)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          trailing: SizedBox(
                            width: 60,
                            child: TextField(
                              controller: TextEditingController(text: quantities[p.id].toString()),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onChanged: (v) => quantities[p.id] = int.tryParse(v) ?? 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Cost', style: TextStyle(fontSize: 12)),
                      Text(
                        'Rs. ${_f.format(products.fold(0.0, (sum, p) => sum + (p.purchasePrice * (quantities[p.id] ?? 0))))}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _createPurchaseOrder(ctx, selectedSupplier, products, products.map((p) => quantities[p.id] ?? 0).toList()),
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: const Text('Create PO'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
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

  void _createPurchaseOrder(BuildContext ctx, Supplier? supplier, List<Product> products, List<int> quantities) {
    if (supplier == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please select a supplier'), backgroundColor: Colors.orange));
      return;
    }

    final items = <PurchaseOrderItem>[];
    for (var i = 0; i < products.length; i++) {
      if (quantities[i] > 0) {
        items.add(PurchaseOrderItem(
          productId: products[i].id,
          productName: products[i].name,
          quantity: quantities[i],
          costPrice: products[i].purchasePrice,
        ));
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please add quantities'), backgroundColor: Colors.orange));
      return;
    }

    ref.read(purchaseOrderProvider.notifier).addPurchaseOrder(
          supplierId: supplier.id,
          supplierName: supplier.name,
          items: items,
        );

    // Clear selections
    setState(() => _selectedProducts.clear());

    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PO created for ${items.length} items'), backgroundColor: Colors.teal),
    );
  }
}
