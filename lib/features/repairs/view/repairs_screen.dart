import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/repairs/controller/repair_controller.dart';
import 'package:cellaris/shared/controller/shared_controller.dart';
import 'package:cellaris/core/models/app_models.dart';

/// Repairs Screen - Feature-Rich Sleek Design
class RepairsScreen extends ConsumerStatefulWidget {
  const RepairsScreen({super.key});

  @override
  ConsumerState<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends ConsumerState<RepairsScreen> {
  String _search = '';
  int _viewMode = 0; // 0 = Kanban, 1 = List
  final _searchController = TextEditingController();
  final _f = NumberFormat('#,###');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(repairProvider.notifier);
    final tickets = notifier.searchTickets(_search);
    final revenue = notifier.calculateTotalRevenue();
    final active = notifier.getActiveRepairsCount();
    final dueToday = notifier.getDueTodayCount();

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
                const Text('Repairs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                const SizedBox(width: 24),
                // View mode toggle
                _buildViewToggle('Board', 0, LucideIcons.layoutGrid),
                const SizedBox(width: 4),
                _buildViewToggle('List', 1, LucideIcons.list),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showNewRepairDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('New Repair', style: TextStyle(fontSize: 12)),
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

          // Stats + Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStat('Revenue', 'Rs. ${_f.format(revenue)}', Colors.green),
                const SizedBox(width: 12),
                _buildStat('Active', '$active', Colors.blue),
                const SizedBox(width: 12),
                _buildStat('Due Today', '$dueToday', dueToday > 0 ? Colors.orange : Colors.grey),
                const SizedBox(width: 12),
                _buildStat('Total', '${tickets.length}', Colors.purple),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search repairs...',
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
              ],
            ),
          ),

          // Content - Kanban or List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _viewMode == 0 ? _buildKanbanView(tickets) : _buildListView(tickets),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(String label, int mode, IconData icon) {
    final selected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.grey[600])),
          ],
        ),
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

  // =========================================
  // KANBAN VIEW
  // =========================================
  Widget _buildKanbanView(List<RepairTicket> tickets) {
    final received = tickets.where((t) => t.status == RepairStatus.received).toList();
    final inRepair = tickets.where((t) => t.status == RepairStatus.inRepair).toList();
    final ready = tickets.where((t) => t.status == RepairStatus.ready).toList();
    final delivered = tickets.where((t) => t.status == RepairStatus.delivered).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildColumn('Received', received, Colors.blue, RepairStatus.received),
        const SizedBox(width: 12),
        _buildColumn('In Repair', inRepair, Colors.orange, RepairStatus.inRepair),
        const SizedBox(width: 12),
        _buildColumn('Ready', ready, Colors.green, RepairStatus.ready),
        const SizedBox(width: 12),
        _buildColumn('Delivered', delivered, Colors.grey, RepairStatus.delivered),
      ],
    );
  }

  Widget _buildColumn(String title, List<RepairTicket> tickets, Color color, RepairStatus status) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Column header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text('${tickets.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
            ),
            // Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tickets.length,
                itemBuilder: (context, index) => _buildTicketCard(tickets[index], color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(RepairTicket ticket, Color color) {
    final now = DateTime.now();
    final isPriority = ticket.expectedReturnDate != null &&
        ticket.expectedReturnDate!.isAfter(now) &&
        ticket.expectedReturnDate!.difference(now).inHours <= 2 &&
        ticket.status != RepairStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetails(ticket),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isPriority ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ticket.id, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.grey[500], fontFamily: 'monospace')),
                    const Spacer(),
                    if (isPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
                        child: const Text('URGENT', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(ticket.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(LucideIcons.smartphone, size: 10, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(ticket.deviceModel, style: TextStyle(fontSize: 10, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Rs. ${_f.format(ticket.estimatedCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal)),
                    const Spacer(),
                    // Quick actions
                    _buildIconBtn(LucideIcons.printer, () => ref.read(repairProvider.notifier).printTicket(ticket)),
                    const SizedBox(width: 4),
                    _buildIconBtn(LucideIcons.arrowRight, () => _showStatusUpdateDialog(ticket), color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 10, color: color ?? Colors.grey[500]),
      ),
    );
  }

  // =========================================
  // LIST VIEW
  // =========================================
  Widget _buildListView(List<RepairTicket> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: tickets.isEmpty
          ? Center(child: Text('No repairs found', style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tickets.length,
              itemBuilder: (context, index) => _buildListRow(tickets[index]),
            ),
    );
  }

  Widget _buildListRow(RepairTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetails(ticket),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 3, height: 28, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                SizedBox(width: 90, child: Text(ticket.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'monospace'))),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(ticket.deviceModel, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(_getStatusLabel(ticket.status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor), textAlign: TextAlign.center),
                  ),
                ),
                SizedBox(width: 100, child: Text('Rs. ${_f.format(ticket.estimatedCost)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal))),
                SizedBox(width: 80, child: Text(DateFormat('MMM dd').format(ticket.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[500]))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.printer, size: 14, color: Colors.grey[500]),
                      tooltip: 'Print',
                      onPressed: () => ref.read(repairProvider.notifier).printTicket(ticket),
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.refreshCw, size: 14, color: Colors.blue[400]),
                      tooltip: 'Update Status',
                      onPressed: () => _showStatusUpdateDialog(ticket),
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

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.received: return Colors.blue;
      case RepairStatus.inRepair: return Colors.orange;
      case RepairStatus.ready: return Colors.green;
      case RepairStatus.delivered: return Colors.grey;
    }
  }

  String _getStatusLabel(RepairStatus status) {
    switch (status) {
      case RepairStatus.received: return 'Received';
      case RepairStatus.inRepair: return 'In Repair';
      case RepairStatus.ready: return 'Ready';
      case RepairStatus.delivered: return 'Delivered';
    }
  }

  // =========================================
  // DIALOGS
  // =========================================
  void _showNewRepairDialog(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final deviceC = TextEditingController();
    final issueC = TextEditingController();
    final costC = TextEditingController();
    DateTime? dueDate;
    final customers = ref.read(customerProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
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
                Row(
                  children: [
                    Icon(LucideIcons.wrench, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('New Repair Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Autocomplete<Customer>(
                          optionsBuilder: (text) {
                            if (text.text.isEmpty) return customers.take(5);
                            return customers.where((c) => c.name.toLowerCase().contains(text.text.toLowerCase()) || c.contact.contains(text.text));
                          },
                          displayStringForOption: (c) => c.name,
                          onSelected: (c) {
                            nameC.text = c.name;
                            phoneC.text = c.contact;
                          },
                          fieldViewBuilder: (ctx, controller, focus, submit) => _buildField('Customer Name *', controller, focus: focus),
                        ),
                        const SizedBox(height: 8),
                        _buildField('Phone *', phoneC),
                        const SizedBox(height: 16),
                        const Text('Device', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 8),
                        _buildField('Device Model *', deviceC),
                        const SizedBox(height: 8),
                        _buildField('Issue Description *', issueC),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildField('Estimated Cost', costC)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) setDialogState(() => dueDate = date);
                                },
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.calendar, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dueDate == null ? 'Due Date' : DateFormat('MMM dd').format(dueDate!),
                                          style: TextStyle(fontSize: 12, color: dueDate == null ? Colors.grey[600] : Colors.white),
                                        ),
                                      ),
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
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _createTicket(ctx, nameC.text, phoneC.text, deviceC.text, issueC.text, costC.text, dueDate, false),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[700]!)),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _createTicket(ctx, nameC.text, phoneC.text, deviceC.text, issueC.text, costC.text, dueDate, true),
                      icon: const Icon(LucideIcons.printer, size: 14),
                      label: const Text('Save & Print'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
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

  Widget _buildField(String hint, TextEditingController controller, {FocusNode? focus}) {
    return TextField(
      controller: controller,
      focusNode: focus,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _createTicket(BuildContext ctx, String name, String phone, String device, String issue, String cost, DateTime? dueDate, bool print) async {
    if (name.isEmpty || phone.isEmpty || device.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill required fields'), backgroundColor: Colors.orange));
      return;
    }
    try {
      await ref.read(repairProvider.notifier).createTicket(
        name: name,
        contact: phone,
        device: device,
        issue: issue,
        cost: double.tryParse(cost) ?? 0,
        expectedReturnDate: dueDate,
        printAfter: print,
      );
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showTicketDetails(RepairTicket ticket) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 18, decoration: BoxDecoration(color: _getStatusColor(ticket.status), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(ticket.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                  const Spacer(),
                  IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('Customer', ticket.customerName),
              _detailRow('Contact', ticket.customerContact),
              _detailRow('Device', ticket.deviceModel),
              _detailRow('Issue', ticket.issueDescription),
              _detailRow('Cost', 'Rs. ${_f.format(ticket.estimatedCost)}'),
              _detailRow('Status', _getStatusLabel(ticket.status)),
              _detailRow('Due', ticket.expectedReturnDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(ticket.expectedReturnDate!)),
              const SizedBox(height: 16),
              const Text('Notes', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ticket.notes.isEmpty
                        ? [Text('No notes', style: TextStyle(fontSize: 11, color: Colors.grey[600]))]
                        : ticket.notes.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $n', style: const TextStyle(fontSize: 10)),
                          )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => ref.read(repairProvider.notifier).printTicket(ticket),
                    icon: const Icon(LucideIcons.printer, size: 14),
                    label: const Text('Print'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showStatusUpdateDialog(ticket);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(RepairTicket ticket) {
    RepairStatus selectedStatus = ticket.status;
    final noteC = TextEditingController();

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
                const Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const Text('New Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: RepairStatus.values.map((s) {
                    final selected = selectedStatus == s;
                    final color = _getStatusColor(s);
                    return ChoiceChip(
                      label: Text(_getStatusLabel(s)),
                      selected: selected,
                      onSelected: (v) => setDialogState(() => selectedStatus = s),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      selectedColor: color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(fontSize: 11, color: selected ? color : Colors.grey),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Note (optional)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildField('Add a note...', noteC),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(repairProvider.notifier).updateStatus(ticket.id, selectedStatus, note: noteC.text);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Update'),
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
