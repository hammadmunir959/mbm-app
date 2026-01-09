import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/widgets/glass_card.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/core/models/invoice.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/features/sales/controller/unified_sales_controller.dart';
import 'package:cellaris/core/repositories/invoice_repository.dart';
import '../../pos/view/imei_selection_dialog.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales Terminal', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.store, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text('Manage POS, Orders & History', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ],
              ),
              // Modern Tab Bar
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  padding: const EdgeInsets.all(4),
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(LucideIcons.shoppingCart, size: 16), SizedBox(width: 8), Text('POS')]))),
                    Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(LucideIcons.history, size: 16), SizedBox(width: 8), Text('History')]))),
                    Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(LucideIcons.packageCheck, size: 16), SizedBox(width: 8), Text('Orders')]))),
                    Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Icon(LucideIcons.pauseCircle, size: 16), SizedBox(width: 8), Text('On Hold')]))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Content Area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe for desktop feel
            children: [
              const _POSTab(),
              const _SalesHistoryTab(),
              const _OrdersTab(),
              const _OnHoldTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// POS TAB
// -----------------------------------------------------------------------------

class _POSTab extends ConsumerWidget {
  const _POSTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watchers
    final products = ref.watch(salesFilteredProductsProvider);
    final allProducts = ref.watch(productProvider);
    final categories = ['All', ...allProducts.map((e) => e.category).toSet()];
    final currentCategory = ref.watch(salesCategoryFilterProvider);
    
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Product Grid
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Filter Bar
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Search Field
                      Expanded(
                        child: TextField(
                          onChanged: (val) => ref.read(salesSearchQueryProvider.notifier).state = val,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search products by name, SKU or IMEI...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Category Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2), 
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentCategory,
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => ref.read(salesCategoryFilterProvider.notifier).state = v ?? 'All',
                            dropdownColor: const Color(0xFF1E1E1E),
                            icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Products Grid
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.packageOpen, size: 64, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 16),
                              Text('No products found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductCard(
                              product: product,
                              onTap: () => _addToCart(context, product, ref),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Right Side: Cart
          SizedBox(
            width: 400,
            child: _CartPanel(),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product, WidgetRef ref) async {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [const Icon(LucideIcons.alertCircle, color: Colors.white, size: 16), const SizedBox(width: 8), Text('${product.name} is out of stock')]),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      return;
    }
    if (product.requiresImei) {
      final imeis = await showImeiSelectionDialog(context, product);
      if (imeis != null && imeis.isNotEmpty) ref.read(unifiedSalesProvider.notifier).addToCartWithImeis(product, imeis);
    } else {
      ref.read(unifiedSalesProvider.notifier).addToCart(product);
    }
  }
}

// -----------------------------------------------------------------------------
// CART PANEL
// -----------------------------------------------------------------------------

class _CartPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedSalesProvider);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Cart Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(LucideIcons.shoppingCart, size: 18, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Sale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${state.totalItems} Items', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                    ]),
                    // Mode Toggle
                    Container(
                      height: 32,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          _ModeButton(label: 'Direct', icon: LucideIcons.zap, isActive: state.isDirectSale, onTap: () => ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.directSale)),
                          _ModeButton(label: 'Order', icon: LucideIcons.fileText, isActive: state.isCreateOrder, onTap: () => ref.read(unifiedSalesProvider.notifier).setMode(SalesMode.createOrder)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Customer Input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.user, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Customer Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: TextField(
                                onChanged: (v) => ref.read(unifiedSalesProvider.notifier).setWalkInName(v),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Name',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: TextField(
                                onChanged: (v) => ref.read(unifiedSalesProvider.notifier).setWalkInPhone(v),
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Phone',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          // Cart Items List
          Expanded(
            child: state.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shoppingBag, size: 48, color: Colors.white.withOpacity(0.05)),
                        const SizedBox(height: 12),
                        Text('Cart is empty', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Select products to begin', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return _CartItemRow(item: item);
                    },
                  ),
          ),
          
          // Footer / Totals
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: 'Rs. ${NumberFormat('#,###').format(state.subtotal)}'),
                const SizedBox(height: 8),
                _SummaryRow(label: 'Discount', value: '- Rs. ${NumberFormat('#,###').format(state.discountAmount)}', isDiscount: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      'Rs. ${NumberFormat('#,###').format(state.total)}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.items.isEmpty ? null : () => ref.read(unifiedSalesProvider.notifier).holdCurrentOrder(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hold', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: state.items.isNotEmpty ? BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                        ) : null,
                        child: ElevatedButton(
                          onPressed: (state.items.isEmpty || state.isProcessing) ? null : () => _processSale(context, ref, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0, // Handled by Container
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.disabled)) return Colors.grey.withOpacity(0.2);
                              return AppTheme.primaryColor;
                            }),
                          ),
                          child: state.isProcessing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(state.isDirectSale ? 'Checkout' : 'Save Order', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.arrowRight, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processSale(BuildContext context, WidgetRef ref, UnifiedSalesState state) async {
    final result = state.isDirectSale 
      ? await ref.read(unifiedSalesProvider.notifier).processDirectSale()
      : await ref.read(unifiedSalesProvider.notifier).saveOrder();
      
    if (result != null && context.mounted) {
      showDialog(
        context: context,
        builder: (c) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, color: Colors.green, size: 32),
                ),
                const SizedBox(height: 20),
                Text(state.isDirectSale ? 'Sale Completed!' : 'Order Saved!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Reference: $result', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(c),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;
  const _SummaryRow({required this.label, required this.value, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDiscount ? Colors.greenAccent : Colors.white)),
      ],
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  final SalesCartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(item.product.isSerialized ? LucideIcons.smartphone : LucideIcons.box, size: 20, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1),
                const SizedBox(height: 2),
                Text('Rs. ${NumberFormat('#,###').format(item.unitPrice)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${NumberFormat('#,###').format(item.lineTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    _QtyAction(icon: LucideIcons.minus, onTap: () => ref.read(unifiedSalesProvider.notifier).updateQuantity(item.product.id, -1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    _QtyAction(icon: LucideIcons.plus, onTap: () => ref.read(unifiedSalesProvider.notifier).updateQuantity(item.product.id, 1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 12, color: Colors.white70),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUCT CARD
// -----------------------------------------------------------------------------

class _ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isOut = widget.product.stock <= 0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: isOut ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? AppTheme.primaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: isHovered ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          widget.product.isSerialized ? LucideIcons.smartphone : LucideIcons.package,
                          size: 36,
                          color: isOut ? Colors.grey[700] : (isHovered ? AppTheme.primaryColor : Colors.grey[400]),
                        ),
                      ),
                      if (isOut) 
                        Positioned(
                          top: 8, right: 8, 
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                            child: const Text('OUT OF STOCK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          )
                        ),
                      if (widget.product.isSerialized && !isOut)
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                            child: const Text('IMEI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(widget.product.sku, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rs. ${NumberFormat.compact().format(widget.product.sellingPrice)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isOut ? Colors.grey : AppTheme.primaryColor)),
                        if (!isOut) 
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.plus, size: 12, color: Colors.white),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HISTORY TAB
// -----------------------------------------------------------------------------

class _SalesHistoryTab extends ConsumerWidget {
  const _SalesHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(_salesHistoryProvider);

    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.history, size: 64, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text('No sales history yet', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // Stats Row
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  _StatCard(title: 'Total Sales', value: '${sales.length}', icon: LucideIcons.shoppingBag, color: Colors.blue),
                  const SizedBox(width: 16),
                  _StatCard(
                    title: 'Revenue', 
                    value: 'Rs. ${NumberFormat.compact().format(sales.fold(0.0, (sum, s) => sum + s.summary.netValue))}', 
                    icon: LucideIcons.dollarSign, 
                    color: Colors.green
                  ),
                ],
              ),
            ),
            
            // Table
            Expanded(
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                        color: Colors.white.withOpacity(0.02),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text('INVOICE #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400]))),
                          Expanded(flex: 2, child: Text('CUSTOMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400]))),
                          Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400]))),
                          Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400]))),
                          Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400]))),
                        ],
                      ),
                    ),
                    // Table Body
                    Expanded(
                      child: ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          final isAlt = index % 2 == 1;
                          return Container(
                            color: isAlt ? Colors.white.withOpacity(0.02) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(sale.billNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white70))),
                                Expanded(flex: 2, child: Text(sale.partyName, style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 2, child: Text(DateFormat('MMM dd, hh:mm a').format(sale.date), style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
                                Expanded(flex: 2, child: Text('Rs. ${NumberFormat('#,###').format(sale.summary.netValue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor))),
                                Expanded(
                                  flex: 1, 
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sale.status == InvoiceStatus.completed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sale.status.name.toUpperCase(), 
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sale.status == InvoiceStatus.completed ? Colors.green : Colors.orange),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORDERS TAB (Online & Offline)
// -----------------------------------------------------------------------------

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _orderTabController;

  @override
  void initState() {
    super.initState();
    _orderTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _orderTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Switcher
        Container(
          width: 300,
          height: 40,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TabBar(
            controller: _orderTabController,
            indicator: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'Offline Orders'),
              Tab(text: 'Online Orders'),
            ],
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _orderTabController,
            children: const [
              _OfflineOrdersView(),
              _OnlineOrdersView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfflineOrdersView extends ConsumerWidget {
  const _OfflineOrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_offlineOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.clipboardList, size: 64, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text('No pending offline orders', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return InkWell(
              onTap: () => _showOrderDetails(context, order, ref),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.box, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.orderNo ?? order.billNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LucideIcons.user, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(order.partyName, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              const SizedBox(width: 16),
                              Icon(LucideIcons.clock, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(DateFormat('MMM dd, hh:mm a').format(order.date), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs. ${NumberFormat('#,###').format(order.summary.netValue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(order.status.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight, color: Colors.grey),
                      onPressed: () => _showOrderDetails(context, order, ref),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }
}

class _OnlineOrdersView extends StatelessWidget {
  const _OnlineOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.globe, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No online orders received', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {}, 
            icon: const Icon(LucideIcons.refreshCw, size: 14), 
            label: const Text('Refresh')
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ON HOLD TAB
// -----------------------------------------------------------------------------

class _OnHoldTab extends ConsumerWidget {
  const _OnHoldTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldOrders = ref.watch(unifiedSalesProvider).heldOrders;

    if (heldOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.pauseCircle, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('No orders on hold', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: heldOrders.length,
      itemBuilder: (context, index) {
        final order = heldOrders.values.elementAt(index);
        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Row(children: [
                      const Icon(LucideIcons.clock, size: 12, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(DateFormat('hh:mm a').format(order.heldAt), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Text('ID: ${order.id.substring(order.id.length - 6)}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(order.customerName ?? 'Walk-in Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${order.itemCount} Items', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const Spacer(),
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rs. ${NumberFormat('#,###').format(order.total)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                        onPressed: () => ref.read(unifiedSalesProvider.notifier).deleteHeldOrder(order.id),
                        tooltip: 'Delete',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(unifiedSalesProvider.notifier).resumeHeldOrder(order.id),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 16)),
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

final _salesHistoryProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAll(type: InvoiceType.sale);
});

final _offlineOrdersProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  // Fetch pending offline orders (sales that are pending)
  return repo.getAll(status: InvoiceStatus.pending, type: InvoiceType.sale);
});

void _showOrderDetails(BuildContext context, Invoice order, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNo ?? order.billNo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy - hh:mm a').format(order.date), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.printer, size: 20, color: Colors.blue),
                      onPressed: () {
                        // PDF Print logic here
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            
            // Customer Details
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.partyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (order.customerMobile != null) ...[
                    const SizedBox(height: 4),
                    Text(order.customerMobile!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Items
            Row(
              children: [
                Icon(LucideIcons.shoppingBag, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: 16, color: Colors.white10),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontSize: 13)),
                            if (item.imei != null) Text('IMEI: ${item.imei}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text('x${item.quantity}', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(width: 16),
                      Text('Rs. ${NumberFormat("#,###").format(item.lineTotal)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 32, color: Colors.white10),
            
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Rs. ${NumberFormat("#,###").format(order.summary.netValue)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Update Status Logic - For now just close
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


