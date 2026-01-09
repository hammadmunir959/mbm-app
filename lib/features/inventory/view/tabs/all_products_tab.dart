import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import '../add_product_modal.dart';

/// All Products Tab - Feature-Rich Design
class AllProductsTab extends ConsumerStatefulWidget {
  const AllProductsTab({super.key});

  @override
  ConsumerState<AllProductsTab> createState() => _AllProductsTabState();
}

class _AllProductsTabState extends ConsumerState<AllProductsTab> {
  String _search = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'All'; // All, In Stock, Low Stock, Out of Stock
  String _sortBy = 'name';
  bool _sortAsc = true;
  int _viewMode = 0; // 0 = List, 1 = Grid
  final _searchController = TextEditingController();
  final _f = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final categories = ['All', ...products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort()];

    // Filter
    var filtered = products.where((p) {
      // Category filter
      if (_categoryFilter != 'All' && p.category != _categoryFilter) return false;
      // Stock filter
      if (_stockFilter == 'In Stock' && p.stock <= 0) return false;
      if (_stockFilter == 'Low Stock' && !(p.stock > 0 && p.stock <= p.lowStockThreshold)) return false;
      if (_stockFilter == 'Out of Stock' && p.stock > 0) return false;
      // Search
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            (p.brand?.toLowerCase().contains(q) ?? false) ||
            p.sku.toLowerCase().contains(q) ||
            (p.imei?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'stock':
          cmp = a.stock.compareTo(b.stock);
          break;
        case 'price':
          cmp = a.sellingPrice.compareTo(b.sellingPrice);
          break;
        case 'value':
          cmp = (a.sellingPrice * a.stock).compareTo(b.sellingPrice * b.stock);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return Column(
      children: [
        // Actions Row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search products, SKU, brand, IMEI...',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                      prefixIcon: Icon(LucideIcons.search, size: 14, color: Colors.grey[600]),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, size: 12, color: Colors.grey[500]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Category filter
              _buildDropdown(_categoryFilter, categories, (v) => setState(() => _categoryFilter = v!), LucideIcons.folder),
              const SizedBox(width: 8),
              // Stock filter
              _buildDropdown(_stockFilter, ['All', 'In Stock', 'Low Stock', 'Out of Stock'], (v) => setState(() => _stockFilter = v!), LucideIcons.layers),
              const SizedBox(width: 8),
              // Sort
              _buildDropdown(_sortBy, ['name', 'stock', 'price', 'value'], (v) => setState(() => _sortBy = v!), LucideIcons.arrowUpDown),
              IconButton(
                icon: Icon(_sortAsc ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 14, color: Colors.grey[500]),
                onPressed: () => setState(() => _sortAsc = !_sortAsc),
                tooltip: _sortAsc ? 'Ascending' : 'Descending',
                constraints: const BoxConstraints(minWidth: 32),
              ),
              const SizedBox(width: 8),
              // View toggle
              _buildViewToggle(LucideIcons.list, 0),
              _buildViewToggle(LucideIcons.layoutGrid, 1),
              const SizedBox(width: 12),
              // Add button
              ElevatedButton.icon(
                onPressed: () => _showAddProduct(context),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('Add Product', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),

        // Results info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('${filtered.length} products', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const Spacer(),
              if (filtered.isNotEmpty) ...[
                Text('Total Value: ', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text('Rs. ${_f.format(filtered.fold(0.0, (sum, p) => sum + (p.sellingPrice * p.stock)))}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
              ],
            ],
          ),
        ),

        // Products List/Grid
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
                        Icon(LucideIcons.package, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('No products found', style: TextStyle(color: Colors.grey[500])),
                        if (_search.isNotEmpty || _categoryFilter != 'All' || _stockFilter != 'All')
                          TextButton(
                            onPressed: () => setState(() {
                              _search = '';
                              _searchController.clear();
                              _categoryFilter = 'All';
                              _stockFilter = 'All';
                            }),
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  )
                : _viewMode == 0
                    ? _buildListView(filtered)
                    : _buildGridView(filtered),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, IconData icon) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(fontSize: 11),
              items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, int mode) {
    final selected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey[600]),
      ),
    );
  }

  // ==========================================
  // LIST VIEW
  // ==========================================
  Widget _buildListView(List<Product> products) {
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16), // For indicator
              Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              SizedBox(width: 100, child: Text('Category', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              SizedBox(width: 60, child: Text('Stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              SizedBox(width: 80, child: Text('Cost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              SizedBox(width: 80, child: Text('Price', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              SizedBox(width: 90, child: Text('Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500]))),
              const SizedBox(width: 100), // Actions
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductRow(products[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(Product product) {
    final stockColor = _getStockColor(product);
    final profit = product.sellingPrice - product.purchasePrice;
    final profitMargin = product.purchasePrice > 0 ? (profit / product.purchasePrice * 100).toStringAsFixed(0) : '0';
    final stockValue = product.sellingPrice * product.stock;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddProduct(context, product: product),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 3, height: 32, decoration: BoxDecoration(color: stockColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                // Name & Brand
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text(product.brand ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          if (product.imei != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                              child: Text('IMEI', style: TextStyle(fontSize: 8, color: Colors.blue[300])),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Category
                SizedBox(
                  width: 100,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                    child: Text(product.category, style: TextStyle(fontSize: 10, color: Colors.grey[400]), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  ),
                ),
                // Stock
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      Text('${product.stock}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stockColor)),
                      if (product.stock <= product.lowStockThreshold && product.stock > 0)
                        const SizedBox(width: 4),
                      if (product.stock <= product.lowStockThreshold && product.stock > 0)
                        Icon(LucideIcons.alertTriangle, size: 10, color: Colors.orange),
                    ],
                  ),
                ),
                // Cost
                SizedBox(width: 80, child: Text('Rs. ${_f.format(product.purchasePrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                // Price + margin
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rs. ${_f.format(product.sellingPrice)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text('+$profitMargin%', style: TextStyle(fontSize: 9, color: Colors.green[400])),
                    ],
                  ),
                ),
                // Stock Value
                SizedBox(width: 90, child: Text('Rs. ${_f.format(stockValue)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: stockColor))),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAction(LucideIcons.scale, 'Adjust Stock', () => _showStockAdjust(product)),
                    _buildAction(LucideIcons.edit3, 'Edit', () => _showAddProduct(context, product: product)),
                    _buildAction(LucideIcons.trash2, 'Delete', () => _confirmDelete(product), color: Colors.red[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return IconButton(
      icon: Icon(icon, size: 14, color: color ?? Colors.grey[500]),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 32),
    );
  }

  // ==========================================
  // GRID VIEW
  // ==========================================
  Widget _buildGridView(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    final stockColor = _getStockColor(product);
    final stockValue = product.sellingPrice * product.stock;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddProduct(context, product: product),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: stockColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Text(product.brand ?? product.category, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rs. ${_f.format(product.sellingPrice)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${product.stock} in stock', style: TextStyle(fontSize: 10, color: stockColor)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs. ${_f.format(stockValue)}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      const Text('value', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStockColor(Product product) {
    if (product.stock == 0) return Colors.red;
    if (product.stock <= product.lowStockThreshold) return Colors.orange;
    return Colors.green;
  }

  // ==========================================
  // DIALOGS
  // ==========================================
  void _showAddProduct(BuildContext context, {Product? product}) {
    showDialog(context: context, builder: (_) => AddProductModal(product: product));
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Product', style: TextStyle(fontSize: 16)),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} deleted'), backgroundColor: Colors.red));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStockAdjust(Product product) {
    final controller = TextEditingController();
    bool isAdd = true;
    String reason = 'Manual Adjustment';

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
                Text('Adjust Stock: ${product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Current stock: ${product.stock}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 16),
                // Add/Remove toggle
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isAdd = true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdd ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isAdd ? Colors.green : Colors.grey[700]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plus, size: 14, color: isAdd ? Colors.green : Colors.grey),
                              const SizedBox(width: 6),
                              Text('Add', style: TextStyle(color: isAdd ? Colors.green : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isAdd = false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !isAdd ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: !isAdd ? Colors.red : Colors.grey[700]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.minus, size: 14, color: !isAdd ? Colors.red : Colors.grey),
                              const SizedBox(width: 6),
                              Text('Remove', style: TextStyle(color: !isAdd ? Colors.red : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: reason,
                  dropdownColor: const Color(0xFF1E293B),
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                  items: ['Manual Adjustment', 'Damaged', 'Returned', 'Stock Count', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => reason = v ?? reason,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final qty = int.tryParse(controller.text) ?? 0;
                        if (qty > 0) {
                          final change = isAdd ? qty : -qty;
                          if (!isAdd && qty > product.stock) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cannot remove more than available stock'), backgroundColor: Colors.orange));
                            return;
                          }
                          ref.read(productProvider.notifier).updateStock(product.id, change);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Stock ${isAdd ? 'added' : 'removed'}: $qty units'), backgroundColor: isAdd ? Colors.green : Colors.orange),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: isAdd ? Colors.green : Colors.red),
                      child: Text(isAdd ? 'Add Stock' : 'Remove Stock'),
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
}
