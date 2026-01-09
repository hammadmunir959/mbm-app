import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/features/inventory/controller/purchase_order_controller.dart';
import 'tabs/all_products_tab.dart';
import 'tabs/low_stock_tab.dart';
import 'tabs/purchase_orders_tab.dart';

/// Inventory Hub Screen - Feature-Rich Sleek Design
class InventoryHubScreen extends ConsumerStatefulWidget {
  const InventoryHubScreen({super.key});

  @override
  ConsumerState<InventoryHubScreen> createState() => _InventoryHubScreenState();
}

class _InventoryHubScreenState extends ConsumerState<InventoryHubScreen> {
  int _selectedTab = 0;
  final _f = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final purchaseOrders = ref.watch(purchaseOrderProvider);

    // Calculate stats
    final totalProducts = products.length;
    final totalStock = products.fold(0, (sum, p) => sum + p.stock);
    final lowStock = products.where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold).length;
    final outOfStock = products.where((p) => p.stock == 0).length;
    final stockValue = products.fold(0.0, (sum, p) => sum + (p.purchasePrice * p.stock));
    final retailValue = products.fold(0.0, (sum, p) => sum + (p.sellingPrice * p.stock));
    final pendingPOs = purchaseOrders.where((po) => po.status != PurchaseOrderStatus.received).length;
    final openPOValue = purchaseOrders.where((po) => po.status != PurchaseOrderStatus.received).fold(0.0, (sum, po) => sum + po.totalCost);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    const Text('Inventory Hub', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                    const Spacer(),
                    // Quick stats summary
                    _buildQuickStat(LucideIcons.package, '$totalProducts', 'Products'),
                    const SizedBox(width: 16),
                    _buildQuickStat(LucideIcons.layers, '$totalStock', 'In Stock'),
                    const SizedBox(width: 16),
                    _buildQuickStat(
                      LucideIcons.alertTriangle,
                      '${lowStock + outOfStock}',
                      'Alerts',
                      color: lowStock + outOfStock > 0 ? Colors.orange : Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats cards row
                Row(
                  children: [
                    _buildStatCard('Stock Value', 'Rs. ${_f.format(stockValue)}', LucideIcons.wallet, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Retail Value', 'Rs. ${_f.format(retailValue)}', LucideIcons.tag, Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Potential Profit', 'Rs. ${_f.format(retailValue - stockValue)}', LucideIcons.trendingUp, Colors.purple),
                    const SizedBox(width: 12),
                    _buildStatCard('Open POs', pendingPOs > 0 ? '$pendingPOs (Rs. ${_f.format(openPOValue)})' : 'None', LucideIcons.shoppingCart, Colors.teal),
                  ],
                ),

                const SizedBox(height: 16),

                // Tabs
                Row(
                  children: [
                    _buildTab('All Products', 0, LucideIcons.package, totalProducts),
                    const SizedBox(width: 8),
                    _buildTab('Low Stock', 1, LucideIcons.alertTriangle, lowStock + outOfStock, alertColor: lowStock + outOfStock > 0 ? Colors.orange : null),
                    const SizedBox(width: 8),
                    _buildTab('Purchase Orders', 2, LucideIcons.shoppingCart, purchaseOrders.length),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                AllProductsTab(),
                LowStockTab(),
                PurchaseOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon, int count, {Color? alertColor}) {
    final selected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? AppTheme.primaryColor : Colors.grey[500]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primaryColor : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (alertColor ?? (selected ? AppTheme.primaryColor : Colors.grey)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: alertColor ?? (selected ? AppTheme.primaryColor : Colors.grey[500])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
