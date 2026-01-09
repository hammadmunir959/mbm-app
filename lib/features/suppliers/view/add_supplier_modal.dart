import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:uuid/uuid.dart';

/// Simplified Add/Edit Supplier Modal - Minimalist Design
class AddSupplierModal extends ConsumerStatefulWidget {
  final Supplier? supplier;
  const AddSupplierModal({super.key, this.supplier});

  @override
  ConsumerState<AddSupplierModal> createState() => _AddSupplierModalState();
}

class _AddSupplierModalState extends ConsumerState<AddSupplierModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameController.text = s.name;
      _companyController.text = s.company;
      _contactController.text = s.contact;
      _emailController.text = s.email ?? '';
      _addressController.text = s.address ?? '';
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supplier = Supplier(
      id: _isEditing ? widget.supplier!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      company: _companyController.text.trim(),
      contact: _contactController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      isActive: _isActive,
      balance: _isEditing ? widget.supplier!.balance : 0,
      debitLimit: _isEditing ? widget.supplier!.debitLimit : 0,
      agingLimit: _isEditing ? widget.supplier!.agingLimit : 0,
    );

    if (_isEditing) {
      await ref.read(supplierProvider.notifier).updateSupplier(supplier);
    } else {
      await ref.read(supplierProvider.notifier).addSupplier(supplier);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${supplier.company} ${_isEditing ? 'updated' : 'added'}.'), backgroundColor: Colors.green),
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
                  _isEditing ? 'Edit Supplier' : 'Add Supplier',
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
                  Row(
                    children: [
                      Expanded(child: _buildField('Company', _companyController, required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Contact Person', _nameController, required: true)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildField('Phone', _contactController, required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Email', _emailController)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildField('Address', _addressController),
                  const SizedBox(height: 16),
                  // Active toggle
                  InkWell(
                    onTap: () => setState(() => _isActive = !_isActive),
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
                            _isActive ? LucideIcons.checkSquare : LucideIcons.square,
                            size: 18,
                            color: _isActive ? Colors.green : Colors.grey[600],
                          ),
                          const SizedBox(width: 10),
                          Text('Active Supplier', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
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
