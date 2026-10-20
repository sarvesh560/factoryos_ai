/// FactoryOS AI — Work Order Management Screen
/// Phase 3: Production Orders, Scheduling, Lifecycle State Actions & Tracking
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/data/models/factory_model.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../controllers/work_order_controller.dart';
import '../controllers/process_library_controller.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class WorkOrderManagementScreen extends ConsumerStatefulWidget {
  const WorkOrderManagementScreen({super.key});

  @override
  ConsumerState<WorkOrderManagementScreen> createState() => _WorkOrderManagementScreenState();
}

class _WorkOrderManagementScreenState extends ConsumerState<WorkOrderManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final factoryId = ref.read(factoryControllerProvider).selectedFactory?.id;
      if (factoryId != null) {
        ref.read(workOrderControllerProvider.notifier).loadOrders(factoryId: factoryId);
        ref.read(processLibraryControllerProvider.notifier).loadDefinitions(factoryId: factoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      factoryControllerProvider.select((s) => s.selectedFactory?.id),
      (prev, next) {
        if (next != null && next != prev) {
          ref.read(workOrderControllerProvider.notifier).loadOrders(factoryId: next);
          ref.read(processLibraryControllerProvider.notifier).loadDefinitions(factoryId: next);
        }
      },
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(workOrderControllerProvider);
    final notifier = ref.read(workOrderControllerProvider.notifier);
    final currentFactory = ref.watch(factoryControllerProvider).selectedFactory;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final totalOrders = state.orders.length;
    final inProgress = state.orders.where((o) => o.status == 'IN_PROGRESS').length;
    final completed = state.orders.where((o) => o.status == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manufacturing Work Orders',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Schedule production runs, track WIP output batches, and initiate process executions.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Create Work Order', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () => _showCreateOrderDialog(context, ref, currentFactory?.id),
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Notification Messages
            if (state.errorMessage != null)
              Container(
                key: const Key('work_order_error_banner'),
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusOfflineBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: FactoryColors.statusOffline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.errorMessage!, style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 13))),
                    const SizedBox(width: 8),
                    TextButton(
                      key: const Key('work_order_retry_button'),
                      onPressed: () => notifier.loadOrders(factoryId: currentFactory?.id),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, color: FactoryColors.statusOffline)),
                    ),
                  ],
                ),
              ),

            if (state.successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusRunningBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusRunningBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: FactoryColors.statusRunning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.successMessage!, style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 13))),
                  ],
                ),
              ),

            // Top Metric Summary Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Orders', '$totalOrders', Icons.inventory_2_outlined, cardBg, borderColor, textPrimary, textSecondary)),
                const SizedBox(width: FactorySpacing.md),
                Expanded(child: _buildMetricCard('In Progress', '$inProgress', Icons.sync, cardBg, borderColor, FactoryColors.primaryBlue, textSecondary)),
                const SizedBox(width: FactorySpacing.md),
                Expanded(child: _buildMetricCard('Completed', '$completed', Icons.check_circle_outline, cardBg, borderColor, FactoryColors.statusRunning, textSecondary)),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Status Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Orders', state.statusFilter == null, notifier),
                  _buildFilterChip('RELEASED', 'Released', state.statusFilter == 'RELEASED', notifier),
                  _buildFilterChip('IN_PROGRESS', 'In Progress', state.statusFilter == 'IN_PROGRESS', notifier),
                  _buildFilterChip('PAUSED', 'Paused', state.statusFilter == 'PAUSED', notifier),
                  _buildFilterChip('COMPLETED', 'Completed', state.statusFilter == 'COMPLETED', notifier),
                ],
              ),
            ),
            const SizedBox(height: FactorySpacing.md),

            // Orders Table / List
            if (state.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (state.orders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text('No Work Orders Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 4),
                    Text('Create a production work order to schedule manufacturing throughput.', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.orders.length,
                  separatorBuilder: (ctx, idx) => Divider(height: 1, color: borderColor),
                  itemBuilder: (ctx, idx) {
                    final order = state.orders[idx];
                    return _buildOrderRow(context, ref, order, notifier, state, isDark, textPrimary, textSecondary);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String? key, String label, bool isSelected, WorkOrderNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
        onSelected: (_) => notifier.setFilter(key == 'ALL' ? null : key),
        selectedColor: FactoryColors.primaryBlue.withValues(alpha: 0.15),
        checkmarkColor: FactoryColors.primaryBlue,
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color cardBg, Color borderColor, Color valColor, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: valColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: valColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: valColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(
    BuildContext context,
    WidgetRef ref,
    WorkOrderItem order,
    WorkOrderNotifier notifier,
    WorkOrderState state,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    Color statusColor;
    Color statusBg;
    switch (order.status) {
      case 'IN_PROGRESS':
        statusColor = FactoryColors.primaryBlue;
        statusBg = FactoryColors.primaryBlue.withValues(alpha: 0.1);
        break;
      case 'COMPLETED':
        statusColor = FactoryColors.statusRunning;
        statusBg = FactoryColors.statusRunningBgLight;
        break;
      case 'PAUSED':
        statusColor = FactoryColors.statusAmber;
        statusBg = FactoryColors.statusIdleBgLight;
        break;
      case 'CANCELLED':
        statusColor = FactoryColors.statusOffline;
        statusBg = FactoryColors.statusOfflineBgLight;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFF64748B).withValues(alpha: 0.1);
    }

    final isActing = state.actionLoadingOrderId == order.id;

    return Padding(
      padding: const EdgeInsets.all(FactorySpacing.lg),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(order.orderNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(order.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${order.productName} (${order.productSku})', style: TextStyle(fontSize: 12, color: textSecondary)),
                Text('Workflow: ${order.processName} [${order.processVersionTag}]', style: const TextStyle(fontSize: 11, color: FactoryColors.primaryBlue)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Output: ${order.quantityCompleted} / ${order.quantityTarget} units (${order.progressPercent}%)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: order.quantityTarget > 0 ? (order.quantityCompleted / order.quantityTarget) : 0,
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(order.status == 'COMPLETED' ? FactoryColors.statusRunning : FactoryColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FactorySpacing.lg),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActing) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: FactoryColors.primaryBlue),
                ),
                const SizedBox(width: 8),
              ],
              if (order.status == 'DRAFT' || order.status == 'PLANNED') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Release', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'release'),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Start Run', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'start', extra: {'mode': 'SIMULATION'}),
                ),
              ],
              if (order.status == 'RELEASED') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Start Run', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'start', extra: {'mode': 'SIMULATION'}),
                ),
              ],
              if (order.status == 'IN_PROGRESS') ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.pause, size: 14),
                  label: const Text('Pause', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'pause'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.statusRunning,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.task_alt, size: 14),
                  label: const Text('Complete', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'complete'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 14),
                  label: const Text('Live Monitor', style: TextStyle(fontSize: 11)),
                  onPressed: () => context.go('/production-execution?workOrderId=${order.id}'),
                ),
              ],
              if (order.status == 'PAUSED') ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 14),
                  label: const Text('Resume', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'resume'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.statusRunning,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.task_alt, size: 14),
                  label: const Text('Complete', style: TextStyle(fontSize: 11)),
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'complete'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactoryColors.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 14),
                  label: const Text('Live Monitor', style: TextStyle(fontSize: 11)),
                  onPressed: () => context.go('/production-execution?workOrderId=${order.id}'),
                ),
              ],
              if (order.status != 'COMPLETED' && order.status != 'CANCELLED') ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: FactoryColors.statusOffline),
                  tooltip: 'Cancel Work Order',
                  onPressed: isActing ? null : () => notifier.executeAction(order.id, 'cancel'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateOrderDialog(BuildContext context, WidgetRef ref, String? defaultFactoryId) async {
    final factoryState = ref.read(factoryControllerProvider);
    final factoryId = defaultFactoryId ??
        factoryState.selectedFactory?.id ??
        (factoryState.factories.isNotEmpty ? factoryState.factories.first.id : null);

    if (factoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active factory from the top bar first.')),
      );
      return;
    }

    // 1. Fetch products for this factory
    List<ProductModel> products = [];
    try {
      products = await ref.read(processRepositoryProvider).getFactoryProducts(factoryId);
    } catch (_) {}

    if (!context.mounted) return;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products found for this factory. Please configure factory products first.')),
      );
      return;
    }

    // 2. Fetch/filter published workflows for this factory (excluding inactive/archived workflows)
    await ref.read(processLibraryControllerProvider.notifier).loadDefinitions(factoryId: factoryId);
    if (!context.mounted) return;

    final allDefinitions = ref.read(processLibraryControllerProvider).definitions;
    final publishedDefinitions = allDefinitions.where((d) =>
      d.isActive && d.publishedVersionId != null && (d.factory.isEmpty || d.factory == factoryId)
    ).toList();

    if (publishedDefinitions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No published process workflows available for this factory. Please validate and publish a workflow first.')),
      );
      return;
    }

    final productionLines = factoryState.overview?.productionLines ?? [];
    final orderNumCtrl = TextEditingController(text: 'WO-${DateTime.now().millisecondsSinceEpoch % 100000}');
    final qtyCtrl = TextEditingController(text: '100');
    final notesCtrl = TextEditingController();
    String selectedProductId = products.first.id;
    String selectedProcId = publishedDefinitions.first.id;
    String? selectedLineId;
    String priority = 'NORMAL';
    String status = 'RELEASED';
    DateTime plannedStart = DateTime.now();
    DateTime plannedDue = DateTime.now().add(const Duration(days: 3));
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final selectedProc = publishedDefinitions.where((d) => d.id == selectedProcId).firstOrNull ?? publishedDefinitions.first;

          return AlertDialog(
            title: const Text('Create Production Work Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        key: const Key('create_work_order_dialog_error'),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FactoryColors.statusOfflineBgLight,
                          borderRadius: BorderRadius.circular(FactoryRadius.sm),
                          border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: FactoryColors.statusOffline),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      key: const Key('create_work_order_number_field'),
                      controller: orderNumCtrl,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Work Order Number *',
                        hintText: 'e.g. WO-2026-001',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('create_work_order_product_dropdown'),
                      isExpanded: true,
                      initialValue: selectedProductId,
                      decoration: const InputDecoration(labelText: 'Manufactured Product (SKU) *'),
                      items: products.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${p.sku}) [${p.unitOfMeasure}]', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: isSubmitting ? null : (val) => setDlgState(() => selectedProductId = val ?? selectedProductId),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('create_work_order_process_dropdown'),
                      isExpanded: true,
                      initialValue: selectedProcId,
                      decoration: const InputDecoration(labelText: 'Published Process Workflow *'),
                      items: publishedDefinitions.map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.name} [${d.code}] — Published', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: isSubmitting ? null : (val) => setDlgState(() => selectedProcId = val ?? selectedProcId),
                    ),
                    const SizedBox(height: 12),
                    if (productionLines.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        key: const Key('create_work_order_line_dropdown'),
                        isExpanded: true,
                        initialValue: selectedLineId,
                        decoration: const InputDecoration(labelText: 'Assigned Production Line (Optional)'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Unassigned / Flexible Line')),
                          ...productionLines.map((l) => DropdownMenuItem<String?>(
                            value: l.id,
                            child: Text('${l.name} [${l.code}]', overflow: TextOverflow.ellipsis),
                          )),
                        ],
                        onChanged: isSubmitting ? null : (val) => setDlgState(() => selectedLineId = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('create_work_order_qty_field'),
                            controller: qtyCtrl,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target Production Units *',
                              hintText: '100',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: priority,
                            decoration: const InputDecoration(labelText: 'Operational Priority'),
                            items: const [
                              DropdownMenuItem(value: 'LOW', child: Text('Low')),
                              DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                              DropdownMenuItem(value: 'HIGH', child: Text('High')),
                              DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                            ],
                            onChanged: isSubmitting ? null : (val) => setDlgState(() => priority = val ?? priority),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Initial Order Status'),
                      items: const [
                        DropdownMenuItem(value: 'RELEASED', child: Text('RELEASED — Ready for Execution')),
                        DropdownMenuItem(value: 'PLANNED', child: Text('PLANNED — Scheduled Order')),
                        DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT — Preliminary Order')),
                      ],
                      onChanged: isSubmitting ? null : (val) => setDlgState(() => status = val ?? status),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      enabled: !isSubmitting,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Production Notes / Routing Instructions',
                        hintText: 'Optional instructions for shop floor operators...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('create_work_order_submit_button'),
                style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.primaryBlue, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final orderNum = orderNumCtrl.text.trim();
                        final qty = int.tryParse(qtyCtrl.text.trim());
                        if (orderNum.isEmpty || qty == null || qty <= 0) {
                          setDlgState(() {
                            dialogError = 'Please enter a valid work order number and positive quantity.';
                          });
                          return;
                        }
                        setDlgState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });
                        final success = await ref.read(workOrderControllerProvider.notifier).createOrder({
                          'factory': factoryId,
                          'order_number': orderNum,
                          'product': selectedProductId,
                          'process_definition': selectedProc.id,
                          'process_version': selectedProc.publishedVersionId,
                          'assigned_line': selectedLineId,
                          'quantity_target': qty,
                          'status': status,
                          'priority': priority,
                          'planned_start_date': plannedStart.toIso8601String(),
                          'planned_due_date': plannedDue.toIso8601String(),
                          'notes': notesCtrl.text.trim(),
                        });
                        if (ctx.mounted) {
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            setDlgState(() {
                              isSubmitting = false;
                              dialogError = ref.read(workOrderControllerProvider).errorMessage ?? 'Failed to create work order.';
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Work Order'),
              ),
            ],
          );
        },
      ),
    );
  }
}

