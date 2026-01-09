import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/inventory/controller/inventory_controller.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

/// Simplified Add/Edit Product Modal - Minimalist Design
class AddProductModal extends ConsumerStatefulWidget {
  final Product? product;
  const AddProductModal({super.key, this.product});

  @override
  ConsumerState<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends ConsumerState<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _lowStockController = TextEditingController();
  
  String? _selectedSupplier;
  ProductCondition _condition = ProductCondition.new_;
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _categoryController.text = p.category;
      _costPriceController.text = p.purchasePrice.toString();
      _salePriceController.text = p.sellingPrice.toString();
      _quantityController.text = p.stock.toString();
      _lowStockController.text = p.lowStockThreshold.toString();
      _selectedSupplier = p.supplierId;
      _condition = p.condition;
    } else {
      _lowStockController.text = '10'; // Default
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = Product(
      id: _isEditing ? widget.product!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      sku: _isEditing ? widget.product!.sku : 'P-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      category: _categoryController.text.trim(),
      purchasePrice: double.tryParse(_costPriceController.text) ?? 0,
      sellingPrice: double.tryParse(_salePriceController.text) ?? 0,
      stock: int.tryParse(_quantityController.text) ?? 0,
      condition: _condition,
      isActive: true,
      isSerialized: false,
      supplierId: _selectedSupplier,
      lowStockThreshold: int.tryParse(_lowStockController.text) ?? 10,
      minStockLevel: _isEditing ? widget.product!.minStockLevel : 5,
    );

    try {
      if (_isEditing) {
        await ref.read(productProvider.notifier).updateProduct(product);
      } else {
        await ref.read(productProvider.notifier).addProduct(product);
      }

      if (mounted) {
        // Capture messenger BEFORE popping the dialog
        final messenger = ScaffoldMessenger.of(context);
        final productName = product.name;
        final isEdit = _isEditing;
        
        Navigator.pop(context);
        
        // Now show snackbar using captured messenger
        messenger.showSnackBar(
          SnackBar(content: Text('$productName ${isEdit ? 'updated' : 'added'}.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(supplierProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isEditing ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name & Brand
                  Row(
                    children: [
                      Expanded(child: _buildField('Name', _nameController, required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Brand', _brandController)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category & Supplier
                  Row(
                    children: [
                      Expanded(child: _buildField('Category', _categoryController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown(suppliers)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prices
                  Row(
                    children: [
                      Expanded(child: _buildField('Cost Price', _costPriceController, isNumber: true, prefix: 'Rs.')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Sale Price', _salePriceController, isNumber: true, prefix: 'Rs.', required: true)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quantity, Low Stock & Condition
                  Row(
                    children: [
                      Expanded(child: _buildField('Quantity', _quantityController, isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Low Stock Alert', _lowStockController, isNumber: true, hint: 'Alert when below')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildConditionSelector()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Update' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = false, bool isNumber = false, String? prefix, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (required) Text(' *', style: TextStyle(color: Colors.red[400], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          validator: required ? (v) => v?.isEmpty == true ? 'Required' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(List<Supplier> suppliers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supplier', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupplier,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(fontSize: 14),
              hint: Text('Select', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedSupplier = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Condition', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Row(
          children: [
            _conditionChip('New', ProductCondition.new_),
            const SizedBox(width: 8),
            _conditionChip('Used', ProductCondition.used),
          ],
        ),
      ],
    );
  }

  Widget _conditionChip(String label, ProductCondition value) {
    final isSelected = _condition == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _condition = value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.transparent),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
