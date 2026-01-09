import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/features/inventory/controller/purchase_order_controller.dart';
import 'package:cellaris/features/inventory/controller/buyback_controller.dart';
import '../purchase_order_dialog.dart';

/// Purchase Orders Tab - Minimalist Design
class PurchaseOrdersTab extends ConsumerStatefulWidget {
  const PurchaseOrdersTab({super.key});

  @override
  ConsumerState<PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends ConsumerState<PurchaseOrdersTab> {
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _buildSubTab('Inventory POs', 0),
              const SizedBox(width: 8),
              _buildSubTab('Phone Buyback', 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: _subTab == 0 ? const _InventoryPOView() : const _BuybackView(),
        ),
      ],
    );
  }

  Widget _buildSubTab(String label, int index) {
    final selected = _subTab == index;
    return InkWell(
      onTap: () => setState(() => _subTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppTheme.primaryColor : Colors.grey[500])),
      ),
    );
  }
}

// ============================================================================
// Inventory PO View
// ============================================================================
class _InventoryPOView extends ConsumerWidget {
  const _InventoryPOView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(purchaseOrderProvider);
    final f = NumberFormat('#,###');

    final draft = pos.where((p) => p.status == PurchaseOrderStatus.draft).length;
    final sent = pos.where((p) => p.status == PurchaseOrderStatus.sent).length;
    final received = pos.where((p) => p.status == PurchaseOrderStatus.received).length;
    final total = pos.fold(0.0, (sum, p) => sum + p.totalCost);

    return Column(
      children: [
        // Stats + Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStat('Total', pos.length.toString(), Colors.blue),
              const SizedBox(width: 12),
              _buildStat('Draft', draft.toString(), Colors.orange),
              const SizedBox(width: 12),
              _buildStat('Sent', sent.toString(), Colors.purple),
              const SizedBox(width: 12),
              _buildStat('Received', received.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildStat('Value', 'Rs. ${f.format(total)}', AppTheme.primaryColor),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showDialog(context: context, builder: (_) => const PurchaseOrderDialog()),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('New PO', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: pos.isEmpty
                ? Center(child: Text('No purchase orders', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: pos.length,
                    itemBuilder: (context, index) => _buildPORow(context, pos[index], f),
                  ),
          ),
        ),
      ],
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

  Widget _buildPORow(BuildContext context, PurchaseOrder po, NumberFormat f) {
    final color = _statusColor(po.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showDialog(context: context, builder: (_) => PurchaseOrderDialog(purchaseOrder: po)),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 3, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PO #${po.id.length > 8 ? po.id.substring(0, 8) : po.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(po.supplierName, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                SizedBox(width: 80, child: Text('${po.items.length} items', style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(po.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                ),
                SizedBox(width: 100, child: Text('Rs. ${f.format(po.totalCost)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                SizedBox(width: 80, child: Text(DateFormat('MMM dd').format(po.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
                Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft: return Colors.orange;
      case PurchaseOrderStatus.sent: return Colors.blue;
      case PurchaseOrderStatus.confirmed: return Colors.purple;
      case PurchaseOrderStatus.received: return Colors.green;
      case PurchaseOrderStatus.cancelled: return Colors.red;
    }
  }
}

// ============================================================================
// Buyback View
// ============================================================================
class _BuybackView extends ConsumerWidget {
  const _BuybackView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(buybackProvider);
    final f = NumberFormat('#,###');
    final totalSpent = records.fold(0.0, (sum, r) => sum + r.purchasePrice);

    return Column(
      children: [
        // Stats + Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStat('Total', records.length.toString(), Colors.teal),
              const SizedBox(width: 12),
              _buildStat('Spent', 'Rs. ${f.format(totalSpent)}', AppTheme.primaryColor),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showBuybackForm(context, ref),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('New Buyback', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: records.isEmpty
                ? Center(child: Text('No buyback records', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: records.length,
                    itemBuilder: (context, index) => _buildBuybackRow(records[index], f, ref),
                  ),
          ),
        ),
      ],
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

  Widget _buildBuybackRow(BuybackRecord record, NumberFormat f, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(width: 3, height: 28, decoration: BoxDecoration(color: record.isListed ? Colors.teal : Colors.grey, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.fullPhoneName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('IMEI: ${record.displayImei}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          SizedBox(width: 120, child: Text(record.sellerName, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
              child: Text(record.condition.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 100, child: Text('Rs. ${f.format(record.purchasePrice)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal))),
          SizedBox(width: 80, child: Text(DateFormat('MMM dd').format(record.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          // List/Unlist toggle
          SizedBox(
            width: 80,
            child: InkWell(
              onTap: () => ref.read(buybackProvider.notifier).toggleListing(record.id),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: record.isListed ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(record.isListed ? LucideIcons.check : LucideIcons.x, size: 10, color: record.isListed ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    Text(record.isListed ? 'Listed' : 'Unlisted', style: TextStyle(fontSize: 9, color: record.isListed ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuybackForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BuybackFormDialog(ref: ref),
    );
  }
}

// Stateful dialog for image uploads
class _BuybackFormDialog extends StatefulWidget {
  final WidgetRef ref;
  const _BuybackFormDialog({required this.ref});

  @override
  State<_BuybackFormDialog> createState() => _BuybackFormDialogState();
}

class _BuybackFormDialogState extends State<_BuybackFormDialog> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final cnicC = TextEditingController();
  final brandC = TextEditingController();
  final modelC = TextEditingController();
  final imeiC = TextEditingController();
  final priceC = TextEditingController();
  
  // Image paths
  String? cnicFrontPath;
  String? cnicBackPath;
  String? phoneFrontPath;
  String? phoneBackPath;

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    cnicC.dispose();
    brandC.dispose();
    modelC.dispose();
    imeiC.dispose();
    priceC.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      // Using dynamic import to avoid direct dependency
      final result = await _selectFile();
      if (result != null) {
        setState(() {
          switch (type) {
            case 'cnic_front': cnicFrontPath = result; break;
            case 'cnic_back': cnicBackPath = result; break;
            case 'phone_front': phoneFrontPath = result; break;
            case 'phone_back': phoneBackPath = result; break;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _selectFile() async {
    // Simple file selection using native dialogs
    // For now, we'll use a placeholder - in production, use file_picker
    // ignore: unnecessary_import
    try {
      final picker = await _showFilePickerDialog();
      return picker;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _showFilePickerDialog() async {
    // Use file_picker package
    try {
      // Import dynamically to handle the package
      final result = await pickImageFile();
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('New Phone Buyback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller Section
                    const Text('Seller Information', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildField('Name *', nameC)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Phone', phoneC)),
                    ]),
                    const SizedBox(height: 8),
                    _buildField('CNIC Number *', cnicC),
                    const SizedBox(height: 12),
                    
                    // CNIC Images
                    const Text('CNIC Images', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildImagePicker('CNIC Front', cnicFrontPath, () => _pickImage('cnic_front'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildImagePicker('CNIC Back', cnicBackPath, () => _pickImage('cnic_back'))),
                    ]),

                    const SizedBox(height: 20),

                    // Phone Section
                    const Text('Phone Information', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildField('Brand *', brandC)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Model *', modelC)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(flex: 2, child: _buildField('IMEI *', imeiC)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Price *', priceC)),
                    ]),
                    const SizedBox(height: 12),

                    // Phone Images
                    const Text('Phone Images', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildImagePicker('Phone Front', phoneFrontPath, () => _pickImage('phone_front'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildImagePicker('Phone Back', phoneBackPath, () => _pickImage('phone_back'))),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveBuyback,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Save Buyback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildImagePicker(String label, String? path, VoidCallback onTap) {
    final hasImage = path != null && path.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: hasImage ? Colors.teal.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasImage ? Colors.teal.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasImage ? LucideIcons.checkCircle : LucideIcons.camera,
              size: 24,
              color: hasImage ? Colors.teal : Colors.grey[600],
            ),
            const SizedBox(height: 6),
            Text(
              hasImage ? 'Image Selected' : label,
              style: TextStyle(fontSize: 10, color: hasImage ? Colors.teal : Colors.grey[500]),
            ),
            if (hasImage)
              Text(
                path.split('/').last.length > 20 ? '${path.split('/').last.substring(0, 17)}...' : path.split('/').last,
                style: TextStyle(fontSize: 8, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  void _saveBuyback() {
    if (nameC.text.isEmpty || cnicC.text.isEmpty || imeiC.text.isEmpty || priceC.text.isEmpty || brandC.text.isEmpty || modelC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    final productId = const Uuid().v4();
    final purchasePrice = double.tryParse(priceC.text) ?? 0;

    // Create the buyback record
    final record = BuybackRecord(
      id: const Uuid().v4(),
      productId: productId,
      sellerName: nameC.text,
      sellerPhone: phoneC.text,
      sellerCnic: cnicC.text,
      cnicFrontPath: cnicFrontPath,
      cnicBackPath: cnicBackPath,
      brand: brandC.text,
      model: modelC.text,
      imei: imeiC.text,
      purchasePrice: purchasePrice,
      sellingPrice: purchasePrice * 1.2, // Default 20% margin
      condition: 'used',
      phoneImage1Path: phoneFrontPath,
      phoneImage2Path: phoneBackPath,
      isListed: true, // Auto-list by default
    );
    widget.ref.read(buybackProvider.notifier).addRecord(record);

    // Also create a Product in inventory (auto-listed)
    final product = Product(
      id: productId,
      name: '${brandC.text} ${modelC.text}',
      sku: 'BUY-${imeiC.text.substring(imeiC.text.length - 6)}',
      brand: brandC.text,
      category: 'Used Phones',
      purchasePrice: purchasePrice,
      sellingPrice: purchasePrice * 1.2, // Default 20% margin
      stock: 1, // Single unit
      condition: ProductCondition.used,
      isActive: true,
      isSerialized: true,
      imei: imeiC.text,
      lowStockThreshold: 0,
      minStockLevel: 0,
    );
    widget.ref.read(productProvider.notifier).addProduct(product);

    // Capture messenger before pop
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Buyback saved & listed in inventory'), backgroundColor: Colors.teal),
    );
  }
}

// Helper function to pick image file using file_picker
Future<String?> pickImageFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      return result.files.first.path;
    }
  } catch (e) {
    debugPrint('File picker error: $e');
  }
  return null;
}
