import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

/// Simplified Add/Edit Customer Modal - Minimalist Design
class AddCustomerModal extends ConsumerStatefulWidget {
  final Customer? customer;
  const AddCustomerModal({super.key, this.customer});

  @override
  ConsumerState<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends ConsumerState<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isWholesale = false;
  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      _nameController.text = c.name;
      _contactController.text = c.contact;
      _emailController.text = c.email ?? '';
      _addressController.text = c.address ?? '';
      _cityController.text = c.city ?? '';
      _isWholesale = c.isWholesale;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = Customer(
      id: _isEditing ? widget.customer!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      contact: _contactController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      isWholesale: _isWholesale,
      balance: _isEditing ? widget.customer!.balance : 0,
      debitLimit: _isEditing ? widget.customer!.debitLimit : 0,
    );

    if (_isEditing) {
      await ref.read(customerProvider.notifier).updateCustomer(customer);
    } else {
      await ref.read(customerProvider.notifier).addCustomer(customer);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${customer.name} ${_isEditing ? 'updated' : 'added'}.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isEditing ? 'Edit Customer' : 'Add Customer',
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
                  _buildField('Name', _nameController, required: true),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildField('Phone', _contactController, required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Email', _emailController)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildField('Address', _addressController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('City', _cityController)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wholesale toggle
                  InkWell(
                    onTap: () => setState(() => _isWholesale = !_isWholesale),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isWholesale ? LucideIcons.checkSquare : LucideIcons.square,
                            size: 18,
                            color: _isWholesale ? AppTheme.primaryColor : Colors.grey[600],
                          ),
                          const SizedBox(width: 10),
                          Text('Wholesale Customer', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                        ],
                      ),
                    ),
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

  Widget _buildField(String label, TextEditingController controller, {bool required = false}) {
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
          style: const TextStyle(fontSize: 14),
          validator: required ? (v) => v?.isEmpty == true ? 'Required' : null : null,
          decoration: InputDecoration(
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
}
