/// FactoryOS AI — Material Flow & WIP Tracking Screen
/// Phase 3: Raw Material Consumption, WIP Quantities, Finished Output & Scrap Analytics
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class MaterialFlowScreen extends ConsumerStatefulWidget {
  const MaterialFlowScreen({super.key});

  @override
  ConsumerState<MaterialFlowScreen> createState() => _MaterialFlowScreenState();
}

class _MaterialFlowScreenState extends ConsumerState<MaterialFlowScreen> {
  bool _isLoading = true;
  List<MaterialFlowItem> _flows = [];
  List<Map<String, dynamic>> _wipStages = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(processRepositoryProvider);
    final factory = ref.read(factoryControllerProvider).selectedFactory;
    try {
      final flows = await repo.getMaterialFlows(factoryId: factory?.id);
      final wip = await repo.getWipSummary(factoryId: factory?.id);
      if (mounted) {
        setState(() {
          _flows = flows;
          _wipStages = wip;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final totalConsumption = _flows.where((f) => f.flowType == 'INPUT_CONSUMPTION').fold(0.0, (acc, f) => acc + f.quantity);
    final totalWip = _wipStages.fold(0, (acc, s) => acc + ((s['units_in_progress'] as int?) ?? 0));
    final totalFinished = _flows.where((f) => f.flowType == 'FINISHED_GOODS').fold(0.0, (acc, f) => acc + f.quantity);
    final totalScrap = _flows.where((f) => f.flowType == 'SCRAP_REJECT').fold(0.0, (acc, f) => acc + f.quantity);

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
                        'Material Flow & WIP Tracking',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time material consumption, buffer WIP balances, scrap generation, and finished goods reconciliation.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Inventory Flows',
                  onPressed: _loadData,
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Metric Summary Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Raw Consumed', '${totalConsumption.toInt()} units/kg', Icons.input, cardBg, borderColor, FactoryColors.primaryBlue, textSecondary)),
                const SizedBox(width: FactorySpacing.md),
                Expanded(child: _buildMetricCard('Active WIP', '$totalWip units', Icons.hourglass_top, cardBg, borderColor, Colors.amber, textSecondary)),
                const SizedBox(width: FactorySpacing.md),
                Expanded(child: _buildMetricCard('Finished Output', '${totalFinished.toInt()} units', Icons.inventory, cardBg, borderColor, FactoryColors.statusRunning, textSecondary)),
                const SizedBox(width: FactorySpacing.md),
                Expanded(child: _buildMetricCard('Total Scrap', '${totalScrap.toInt()} units', Icons.delete_sweep_outlined, cardBg, borderColor, FactoryColors.statusOffline, textSecondary)),
              ],
            ),
            const SizedBox(height: FactorySpacing.xl),

            // Active Stage WIP Balances
            Text('Stage-Level Work-in-Progress (WIP) Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
            else if (_wipStages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(FactoryRadius.md), border: Border.all(color: borderColor)),
                child: Center(child: Text('No active WIP queues found.', style: TextStyle(color: textSecondary))),
              )
            else
              Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(FactoryRadius.md), border: Border.all(color: borderColor)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wipStages.length,
                  separatorBuilder: (ctx, idx) => Divider(height: 1, color: borderColor),
                  itemBuilder: (ctx, idx) {
                    final item = _wipStages[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['node_name'] ?? 'Operation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                                Text('Key: ${item['node_key']} • Order: ${item['work_order']}', style: TextStyle(fontSize: 11, color: textSecondary)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('In Progress: ${item['units_in_progress']} units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FactoryColors.primaryBlue)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Completed: ${item['units_completed']} units', style: const TextStyle(fontSize: 12, color: FactoryColors.statusRunning)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Scrap: ${item['units_scrapped']} units', style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: FactorySpacing.xl),

            // Material Flow Audit Log
            Text('Granular Material Movements Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(FactoryRadius.md), border: Border.all(color: borderColor)),
              child: _flows.isEmpty
                  ? Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('No material flow logs recorded yet.', style: TextStyle(color: textSecondary))))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _flows.take(20).length,
                      separatorBuilder: (ctx, idx) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, idx) {
                        final flow = _flows[idx];
                        Color badgeColor;
                        switch (flow.flowType) {
                          case 'INPUT_CONSUMPTION':
                            badgeColor = FactoryColors.primaryBlue;
                            break;
                          case 'FINISHED_GOODS':
                            badgeColor = FactoryColors.statusRunning;
                            break;
                          case 'SCRAP_REJECT':
                            badgeColor = FactoryColors.statusOffline;
                            break;
                          default:
                            badgeColor = Colors.amber;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: Text(flow.flowType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${flow.quantity} ${flow.unitOfMeasure} — ${flow.rawMaterialName ?? flow.stageName}',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                    ),
                                    if (flow.notes.isNotEmpty)
                                      Text(flow.notes, style: TextStyle(fontSize: 11, color: textSecondary)),
                                  ],
                                ),
                              ),
                              Text(
                                flow.timestamp.length >= 19 ? flow.timestamp.substring(11, 19) : flow.timestamp,
                                style: TextStyle(fontSize: 11, color: textSecondary),
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
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color cardBg, Color borderColor, Color valColor, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(FactorySpacing.lg),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(FactoryRadius.md), border: Border.all(color: borderColor)),
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
              Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: valColor)),
            ],
          ),
        ],
      ),
    );
  }
}
