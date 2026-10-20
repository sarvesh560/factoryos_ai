/// FactoryOS AI — Visual Manufacturing Process Builder Screen
/// Phase 3: Interactive Graph Canvas, Zoom, Pan, Node Selection, Edge Wiring & Validation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../factories/data/models/factory_model.dart';
import '../../../factories/presentation/controllers/factory_controller.dart';
import '../controllers/process_builder_controller.dart';
import '../../data/models/process_models.dart';

class VisualProcessBuilderScreen extends ConsumerStatefulWidget {
  final String versionId;

  const VisualProcessBuilderScreen({super.key, required this.versionId});

  @override
  ConsumerState<VisualProcessBuilderScreen> createState() => _VisualProcessBuilderScreenState();
}

class _VisualProcessBuilderScreenState extends ConsumerState<VisualProcessBuilderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(processBuilderControllerProvider.notifier).loadVersion(widget.versionId);
    });
  }

  @override
  void didUpdateWidget(VisualProcessBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.versionId != widget.versionId) {
      Future.microtask(() {
        ref.read(processBuilderControllerProvider.notifier).loadVersion(widget.versionId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(processBuilderControllerProvider);
    final notifier = ref.read(processBuilderControllerProvider.notifier);
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final ver = state.currentVersion;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Top Action Toolbar
          _buildTopToolbar(context, ref, state, notifier, ver, isDark, textPrimary, textSecondary, cardBg, borderColor),

          // Validation Result Persistent Panel
          if (state.validationResult != null)
            _buildValidationPanel(context, state.validationResult!, notifier, ver, isDark),

          // Notification Banner
          if (state.errorMessage != null && state.validationResult == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 8),
              color: FactoryColors.statusOfflineBgLight,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: FactoryColors.statusOffline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!, style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: FactoryColors.statusOffline),
                    onPressed: () => notifier.selectNode(state.selectedNode), // triggers clear
                  ),
                ],
              ),
            ),

          if (state.successMessage != null && state.validationResult == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 8),
              color: FactoryColors.statusRunningBgLight,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: FactoryColors.statusRunning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.successMessage!, style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 12))),
                ],
              ),
            ),

          // Main Canvas & Inspector Area
          Expanded(
            child: Row(
              children: [
                // Interactive Visual Canvas
                Expanded(
                  child: ClipRect(
                    child: Stack(
                      children: [
                        // Background Grid & Pan Detector
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              notifier.setPan(state.panOffset + details.delta);
                            },
                            child: CustomPaint(
                              painter: _GridPainter(
                                panOffset: state.panOffset,
                                zoomLevel: state.zoomLevel,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),

                        // Edges & Nodes Container (scaled and translated)
                        if (ver != null)
                          Positioned.fill(
                            child: Transform(
                              alignment: Alignment.topLeft,
                              transform: Matrix4.translationValues(state.panOffset.dx, state.panOffset.dy, 0.0)
                                ..scaleByDouble(state.zoomLevel, state.zoomLevel, 1.0, 1.0),
                              child: Stack(
                                children: [
                                  // Edges Painter
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _EdgePainter(
                                        nodes: ver.nodes,
                                        edges: ver.edges,
                                        selectedEdge: state.selectedEdge,
                                        invalidNodeKeys: state.validationResult?.invalidNodeKeys ?? const [],
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),

                                  // Draggable Nodes
                                  ...ver.nodes.map((node) {
                                    return Positioned(
                                      left: node.positionX,
                                      top: node.positionY,
                                      child: _buildNodeWidget(context, ref, node, state, notifier, isDark),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                        // Bottom-Left Canvas Controls (Zoom, Reset)
                        Positioned(
                          left: FactorySpacing.lg,
                          bottom: FactorySpacing.lg,
                          child: _buildCanvasControls(notifier, state, cardBg, borderColor, textPrimary),
                        ),

                        // Loading Overlay
                        if (state.isLoading || state.isSaving || state.isValidating)
                          Container(
                            color: Colors.black26,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),

                // Side Inspector Panel
                if (state.selectedNode != null || state.selectedEdge != null)
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(left: BorderSide(color: borderColor)),
                    ),
                    child: _buildInspectorPanel(context, ref, state, notifier, ver, isDark, textPrimary, textSecondary, borderColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(
    BuildContext context,
    WidgetRef ref,
    ProcessBuilderState state,
    ProcessBuilderNotifier notifier,
    ProcessVersionItem? ver,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final isPublished = ver?.isPublished ?? false;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back to Process Library',
            onPressed: () => context.go('/processes'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Workflow Canvas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                if (ver != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPublished ? FactoryColors.statusRunningBgLight : FactoryColors.statusIdleBgLight,
                      borderRadius: BorderRadius.circular(FactoryRadius.sm),
                      border: Border.all(color: isPublished ? FactoryColors.statusRunningBorderLight : FactoryColors.statusIdleBorderLight),
                    ),
                    child: Text(
                      '${ver.versionTag} [${ver.status}]',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPublished ? FactoryColors.statusRunning : FactoryColors.statusIdle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (ver != null && !isPublished) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.add_box_outlined, size: 16),
              label: const Text('Add Node', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAddNodeDialog(context, notifier),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: state.isValidating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, size: 16),
              label: Text(
                state.isValidating ? 'Validating...' : 'Validate Graph',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: state.isValidating ? null : notifier.validateGraph,
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final isInvalid = state.validationResult != null && !state.validationResult!.isValid;
                return Tooltip(
                  message: isInvalid
                      ? 'Publishing disabled: Graph has validation errors. Fix issues or re-validate.'
                      : (state.isSaving ? 'Publishing version...' : 'Publish Version to Production'),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInvalid ? Colors.grey.shade500 : FactoryColors.statusRunning,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.publish, size: 16),
                    label: Text(
                      state.isSaving ? 'Publishing...' : 'Publish Version',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: (isInvalid || state.isSaving || state.isValidating) ? null : notifier.publishVersion,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.save_outlined, size: 20),
              tooltip: 'Save Layout Coordinates',
              onPressed: notifier.saveLayout,
            ),
          ] else if (ver != null && isPublished) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Read-Only (Published)', style: TextStyle(fontSize: 11, color: FactoryColors.primaryBlue)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FactoryColors.primaryBlue,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.copy, size: 15),
              label: const Text('Clone Editable Draft', style: TextStyle(fontSize: 12)),
              onPressed: () => notifier.cloneVersion(ver.processDefinition),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCanvasControls(
    ProcessBuilderNotifier notifier,
    ProcessBuilderState state,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(FactoryRadius.md),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            tooltip: 'Zoom Out',
            onPressed: () => notifier.setZoom(state.zoomLevel - 0.1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${(state.zoomLevel * 100).toInt()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'Zoom In',
            onPressed: () => notifier.setZoom(state.zoomLevel + 0.1),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.center_focus_strong_outlined, size: 16),
            tooltip: 'Reset Pan & Zoom',
            onPressed: () {
              notifier.setZoom(1.0);
              notifier.setPan(Offset.zero);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(
    BuildContext context,
    WidgetRef ref,
    ProcessNodeItem node,
    ProcessBuilderState state,
    ProcessBuilderNotifier notifier,
    bool isDark,
  ) {
    final isSelected = state.selectedNode?.id == node.id;
    final isConnectSource = state.connectingSourceNode?.id == node.id;
    final isInvalid = state.validationResult != null &&
        !state.validationResult!.isValid &&
        state.validationResult!.invalidNodeKeys.contains(node.nodeKey);

    Color headerBg;
    IconData icon;
    switch (node.nodeType) {
      case 'START':
        headerBg = const Color(0xFF10B981);
        icon = Icons.play_arrow;
        break;
      case 'END':
        headerBg = const Color(0xFFEF4444);
        icon = Icons.flag;
        break;
      case 'PARALLEL_SPLIT':
      case 'PARALLEL_JOIN':
        headerBg = const Color(0xFFF59E0B);
        icon = Icons.call_split;
        break;
      case 'QUALITY_GATE':
        headerBg = const Color(0xFF8B5CF6);
        icon = Icons.verified_outlined;
        break;
      default:
        headerBg = FactoryColors.primaryBlue;
        icon = Icons.precision_manufacturing;
    }

    final cardBg = isDark ? FactoryColors.darkSurface : Colors.white;

    final Color borderColor;
    final double borderWidth;
    if (isInvalid) {
      borderColor = const Color(0xFFEF4444);
      borderWidth = 2.5;
    } else if (isConnectSource) {
      borderColor = Colors.amber;
      borderWidth = 2.0;
    } else if (isSelected) {
      borderColor = FactoryColors.primaryBlue;
      borderWidth = 2.0;
    } else {
      borderColor = isDark ? FactoryColors.darkBorder : const Color(0xFFE5E7EB);
      borderWidth = 1.0;
    }

    return GestureDetector(
      onTap: () {
        if (state.isConnecting) {
          notifier.completeConnecting(node);
        } else {
          notifier.selectNode(node);
        }
      },
      onPanUpdate: (verState) {
        if (!state.isConnecting && !(state.currentVersion?.isPublished ?? false)) {
          notifier.updateNodePosition(node.nodeKey, verState.delta / state.zoomLevel);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 180,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(FactoryRadius.md),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            if (isInvalid)
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              )
            else if (isSelected)
              BoxShadow(
                color: FactoryColors.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Node Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(FactoryRadius.md - 1)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node.nodeKey,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isInvalid) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'INVALID',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (node.nodeType == 'OPERATION')
                    Text(
                      '${node.cycleTimeSeconds.toInt()}s',
                      style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),

            // Node Body
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (node.assignedMachineName != null)
                    Text(
                      node.assignedMachineName!,
                      style: const TextStyle(fontSize: 10, color: FactoryColors.primaryBlue, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (node.assignedLineName != null)
                    Text(
                      node.assignedLineName!,
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Wiring Anchor Button
            if (node.nodeType != 'END' && !(state.currentVersion?.isPublished ?? false))
              InkWell(
                onTap: () => notifier.startConnecting(node),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(FactoryRadius.md - 1)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 12, color: isConnectSource ? Colors.amber : FactoryColors.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        isConnectSource ? 'Connecting...' : 'Connect to Node',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isConnectSource ? Colors.amber : FactoryColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorPanel(
    BuildContext context,
    WidgetRef ref,
    ProcessBuilderState state,
    ProcessBuilderNotifier notifier,
    ProcessVersionItem? ver,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final node = state.selectedNode;
    final edge = state.selectedEdge;
    final isPublished = ver?.isPublished ?? false;

    if (edge != null) {
      return Padding(
        padding: const EdgeInsets.all(FactorySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edge Inspector', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => notifier.selectEdge(null)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Routing Connection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 4),
            Text('${edge.sourceNodeKey}  ➔  ${edge.targetNodeKey}', style: const TextStyle(fontSize: 13, color: FactoryColors.primaryBlue, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Edge Type: ${edge.edgeType}', style: TextStyle(fontSize: 12, color: textSecondary)),
            if (edge.conditionExpression.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Condition: ${edge.conditionExpression}', style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
            const Spacer(),
            if (!isPublished)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.statusOffline, foregroundColor: Colors.white),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete Edge'),
                  onPressed: () => notifier.deleteEdge(edge.id),
                ),
              ),
          ],
        ),
      );
    }

    if (node == null) return const SizedBox.shrink();

    return _NodeInspectorView(
      node: node,
      ver: ver,
      state: state,
      notifier: notifier,
      isDark: isDark,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  void _showAddNodeDialog(BuildContext context, ProcessBuilderNotifier notifier) {
    final nameCtrl = TextEditingController(text: 'Inspection / Assembly Cell');
    String nodeType = 'OPERATION';
    final cycleCtrl = TextEditingController(text: '30.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: const Text('Add Process Stage Node', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Stage Name')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: nodeType,
                    decoration: const InputDecoration(labelText: 'Node Type'),
                    items: const [
                      DropdownMenuItem(value: 'OPERATION', child: Text('Standard Operation')),
                      DropdownMenuItem(value: 'PARALLEL_SPLIT', child: Text('Parallel Split (AND Fork)')),
                      DropdownMenuItem(value: 'PARALLEL_JOIN', child: Text('Parallel Join (AND Sync)')),
                      DropdownMenuItem(value: 'CONDITION_BRANCH', child: Text('Conditional Branch')),
                      DropdownMenuItem(value: 'QUALITY_GATE', child: Text('Quality Gate / Inspection')),
                    ],
                    onChanged: (val) => setDlgState(() => nodeType = val ?? nodeType),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: cycleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cycle Time (seconds)')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.primaryBlue, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.addNode(
                    name: nameCtrl.text.trim(),
                    nodeType: nodeType,
                    cycleTimeSeconds: double.tryParse(cycleCtrl.text.trim()) ?? 30.0,
                  );
                },
                child: const Text('Add to Canvas'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildValidationPanel(
    BuildContext context,
    GraphValidationResult result,
    ProcessBuilderNotifier notifier,
    ProcessVersionItem? ver,
    bool isDark,
  ) {
    final isValid = result.isValid;
    final bgColor = isValid
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.35) : const Color(0xFFFEF2F2));
    final borderColor = isValid
        ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
        : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA));
    final titleColor = isValid
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B));
    final textColor = isValid
        ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C));

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error_outline,
                color: isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      isValid
                          ? 'Graph Topology Validation Passed'
                          : 'Graph Validation Failed (${result.errors.length} Issue${result.errors.length > 1 ? 's' : ''})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isValid ? 'READY TO PUBLISH' : 'CANNOT PUBLISH',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: titleColor,
                tooltip: 'Dismiss Validation Panel',
                visualDensity: VisualDensity.compact,
                onPressed: notifier.dismissValidationResult,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isValid) ...[
                    Text(
                      'All workflow nodes are reachable and properly connected from START to END. Graph topology is structurally sound and ready to be deployed to manufacturing lines.',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ] else ...[
                    if (result.invalidNodeKeys.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Affected Nodes: ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: titleColor),
                          ),
                          const SizedBox(width: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: result.invalidNodeKeys.map((nodeKey) {
                              final node = ver?.nodes.where((n) => n.nodeKey == nodeKey).firstOrNull;
                              return ActionChip(
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                                backgroundColor: const Color(0xFFDC2626),
                                label: Text(
                                  nodeKey,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                tooltip: 'Click to select $nodeKey in Inspector',
                                onPressed: () {
                                  if (node != null) {
                                    notifier.selectNode(node);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    ...result.errors.map((err) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.circle, size: 5, color: Color(0xFFEF4444)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  err,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (result.warnings.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...result.warnings.map((warn) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Warning: $warn',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Offset panOffset;
  final double zoomLevel;
  final bool isDark;

  _GridPainter({required this.panOffset, required this.zoomLevel, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    final step = gridSize * zoomLevel;
    final startX = panOffset.dx % step;
    final startY = panOffset.dy % step;

    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) {
    return old.panOffset != panOffset || old.zoomLevel != zoomLevel || old.isDark != isDark;
  }
}

class _EdgePainter extends CustomPainter {
  final List<ProcessNodeItem> nodes;
  final List<ProcessEdgeItem> edges;
  final ProcessEdgeItem? selectedEdge;
  final List<String> invalidNodeKeys;
  final bool isDark;

  _EdgePainter({
    required this.nodes,
    required this.edges,
    this.selectedEdge,
    this.invalidNodeKeys = const [],
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (var n in nodes) n.id: n};

    for (final edge in edges) {
      final src = nodeMap[edge.sourceNode];
      final tgt = nodeMap[edge.targetNode];
      if (src == null || tgt == null) continue;

      final isSelected = selectedEdge?.id == edge.id;
      final isInvalidEdge = invalidNodeKeys.contains(src.nodeKey) || invalidNodeKeys.contains(tgt.nodeKey);

      final Color edgeColor;
      final double edgeWidth;
      if (isSelected) {
        edgeColor = Colors.amber;
        edgeWidth = 3.0;
      } else if (isInvalidEdge) {
        edgeColor = const Color(0xFFEF4444);
        edgeWidth = 2.5;
      } else if (edge.edgeType == 'EXCEPTION') {
        edgeColor = FactoryColors.statusOffline;
        edgeWidth = 2.0;
      } else {
        edgeColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        edgeWidth = 2.0;
      }

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke;

      // Source anchor (right center of src node)
      final srcX = src.positionX + 180.0;
      final srcY = src.positionY + 35.0;

      // Target anchor (left center of tgt node)
      final tgtX = tgt.positionX;
      final tgtY = tgt.positionY + 35.0;

      final dx = (tgtX - srcX).abs() * 0.5;
      final path = Path()
        ..moveTo(srcX, srcY)
        ..cubicTo(srcX + dx, srcY, tgtX - dx, tgtY, tgtX, tgtY);

      canvas.drawPath(path, paint);

      // Arrowhead at target
      final arrowPaint = Paint()
        ..color = edgeColor
        ..style = PaintingStyle.fill;

      const arrowSize = 6.0;
      final arrowPath = Path()
        ..moveTo(tgtX, tgtY)
        ..lineTo(tgtX - arrowSize * 1.5, tgtY - arrowSize)
        ..lineTo(tgtX - arrowSize * 1.5, tgtY + arrowSize)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => true;
}

// =============================================================================
// NODE INSPECTOR WIDGET WITH PRODUCTION LINE & MACHINE ASSIGNMENTS
// =============================================================================

class _NodeInspectorView extends ConsumerStatefulWidget {
  final ProcessNodeItem node;
  final ProcessVersionItem? ver;
  final ProcessBuilderState state;
  final ProcessBuilderNotifier notifier;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const _NodeInspectorView({
    required this.node,
    required this.ver,
    required this.state,
    required this.notifier,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  ConsumerState<_NodeInspectorView> createState() => _NodeInspectorViewState();
}

class _NodeInspectorViewState extends ConsumerState<_NodeInspectorView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cycleCtrl;
  late TextEditingController _setupCtrl;
  late TextEditingController _capCtrl;
  late TextEditingController _operatorsCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _skillsCtrl;
  late TextEditingController _yieldCtrl;
  late String _nodeType;
  String? _selectedLineId;
  String? _selectedMachineId;
  String? _validationError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFields(widget.node);
  }

  @override
  void didUpdateWidget(covariant _NodeInspectorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _initFields(widget.node);
    }
  }

  void _initFields(ProcessNodeItem node) {
    _nameCtrl = TextEditingController(text: node.name);
    _cycleCtrl = TextEditingController(text: node.cycleTimeSeconds.toString());
    _setupCtrl = TextEditingController(text: node.setupTimeSeconds.toString());
    _capCtrl = TextEditingController(text: node.standardCapacityPerHour.toString());
    _operatorsCtrl = TextEditingController(text: node.requiredOperators.toString());
    _roleCtrl = TextEditingController(text: node.operatorRole);
    _skillsCtrl = TextEditingController(text: node.requiredSkills.join(', '));
    _yieldCtrl = TextEditingController(text: node.yieldRatePercent.toString());
    _nodeType = node.nodeType;
    _selectedLineId = node.assignedLine;
    _selectedMachineId = node.assignedMachine;
    _validationError = null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cycleCtrl.dispose();
    _setupCtrl.dispose();
    _capCtrl.dispose();
    _operatorsCtrl.dispose();
    _roleCtrl.dispose();
    _skillsCtrl.dispose();
    _yieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final ver = widget.ver;
    final state = widget.state;
    final notifier = widget.notifier;
    final isPublished = ver?.isPublished ?? false;

    final factoryState = ref.watch(factoryControllerProvider);
    final productionLines = factoryState.overview?.productionLines ?? [];

    ProductionLineItem? currentLine;
    if (_selectedLineId != null) {
      for (final l in productionLines) {
        if (l.id == _selectedLineId) {
          currentLine = l;
          break;
        }
      }
    }
    final availableMachines = currentLine?.machines ?? [];

    final isNodeInvalid = state.validationResult != null &&
        !state.validationResult!.isValid &&
        state.validationResult!.invalidNodeKeys.contains(node.nodeKey);

    return Padding(
      padding: const EdgeInsets.all(FactorySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Node Inspector', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: widget.textPrimary)),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => notifier.selectNode(null)),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNodeInvalid) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: FactoryColors.statusOfflineBgLight,
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: FactoryColors.statusOffline),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Node has graph validation errors (unreachable from START or disconnected). Connect or configure edges.',
                              style: TextStyle(fontSize: 11, color: FactoryColors.statusOffline, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_validationError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: FactoryColors.statusOfflineBgLight,
                        borderRadius: BorderRadius.circular(FactoryRadius.sm),
                        border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                      ),
                      child: Text(
                        _validationError!,
                        style: const TextStyle(fontSize: 11, color: FactoryColors.statusOffline, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  // Node Key & Type Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Key: ${node.nodeKey}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FactoryColors.primaryBlue)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(_nodeType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FactoryColors.primaryBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Node Name
                  TextField(
                    key: const Key('inspector_node_name'),
                    controller: _nameCtrl,
                    enabled: !isPublished,
                    decoration: const InputDecoration(labelText: 'Operation Name *', isDense: true),
                  ),
                  const SizedBox(height: 12),

                  // Node Type Dropdown
                  DropdownButtonFormField<String>(
                    key: ValueKey('inspector_node_type_$_nodeType'),
                    initialValue: _nodeType,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Node Type', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'START', child: Text('START — Process Ingest', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'OPERATION', child: Text('OPERATION — Standard Stage', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'PARALLEL_SPLIT', child: Text('PARALLEL SPLIT — AND Fork', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'PARALLEL_JOIN', child: Text('PARALLEL JOIN — AND Sync', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'CONDITION_BRANCH', child: Text('CONDITION BRANCH — Decision/OR', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'QUALITY_GATE', child: Text('QUALITY GATE — Inspection', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'END', child: Text('END — Process Completion', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: isPublished ? null : (val) {
                      if (val != null) setState(() => _nodeType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cycle Time & Setup Time
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('inspector_cycle_time'),
                          controller: _cycleCtrl,
                          enabled: !isPublished,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cycle Time (sec) *', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('inspector_setup_time'),
                          controller: _setupCtrl,
                          enabled: !isPublished,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Setup Time (sec)', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Standard Capacity & Required Operators
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('inspector_capacity'),
                          controller: _capCtrl,
                          enabled: !isPublished,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacity (units/hr)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('inspector_operators'),
                          controller: _operatorsCtrl,
                          enabled: !isPublished,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Operators Count', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Operator Role
                  TextField(
                    key: const Key('inspector_operator_role'),
                    controller: _roleCtrl,
                    enabled: !isPublished,
                    decoration: const InputDecoration(labelText: 'Operator Role (e.g. CNC Specialist)', isDense: true),
                  ),
                  const SizedBox(height: 12),

                  // Required Skills
                  TextField(
                    key: const Key('inspector_required_skills'),
                    controller: _skillsCtrl,
                    enabled: !isPublished,
                    decoration: const InputDecoration(labelText: 'Required Skills (comma-separated)', isDense: true),
                  ),
                  const SizedBox(height: 12),

                  // Target Yield Rate
                  TextField(
                    key: const Key('inspector_yield_rate'),
                    controller: _yieldCtrl,
                    enabled: !isPublished,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Target Yield Rate (0-100%)', isDense: true),
                  ),
                  const SizedBox(height: 12),

                  // Production Line Dropdown
                  DropdownButtonFormField<String?>(
                    key: const Key('inspector_line_assignment'),
                    initialValue: productionLines.any((l) => l.id == _selectedLineId) ? _selectedLineId : null,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assigned Production Line', isDense: true),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned / Flexible Line', style: TextStyle(fontSize: 12)),
                      ),
                      ...productionLines.map((l) => DropdownMenuItem<String?>(
                            value: l.id,
                            child: Text('${l.name} [${l.code}]', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: isPublished
                        ? null
                        : (newLineId) {
                            setState(() {
                              _selectedLineId = newLineId;
                              if (newLineId == null) {
                                _selectedMachineId = null;
                              } else {
                                final lineObj = productionLines.firstWhere((l) => l.id == newLineId, orElse: () => productionLines.first);
                                if (!lineObj.machines.any((m) => m.id == _selectedMachineId)) {
                                  _selectedMachineId = null;
                                }
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),

                  // Machine Dropdown Filtered by Line
                  DropdownButtonFormField<String?>(
                    key: const Key('inspector_machine_assignment'),
                    initialValue: availableMachines.any((m) => m.id == _selectedMachineId) ? _selectedMachineId : null,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assigned Machine Cell', isDense: true),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None / General Cell', style: TextStyle(fontSize: 12)),
                      ),
                      ...availableMachines.map((m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text('${m.name} [${m.code}]', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (isPublished || _selectedLineId == null)
                        ? null
                        : (newMachineId) {
                            setState(() => _selectedMachineId = newMachineId);
                          },
                  ),
                  const SizedBox(height: 14),

                  // Layout Position Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF161B22) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(FactoryRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: widget.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Graph Position: X: ${node.positionX.toInt()} px, Y: ${node.positionY.toInt()} px',
                            style: TextStyle(fontSize: 11, color: widget.textSecondary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Apply Changes Button
                  if (!isPublished)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('inspector_apply_changes_button'),
                        style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.primaryBlue, foregroundColor: Colors.white),
                        icon: _isSaving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check, size: 16),
                        label: Text(_isSaving ? 'Applying...' : 'Apply Changes'),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final name = _nameCtrl.text.trim();
                                final cycle = double.tryParse(_cycleCtrl.text.trim());
                                final setup = double.tryParse(_setupCtrl.text.trim());
                                final cap = int.tryParse(_capCtrl.text.trim());
                                final operators = int.tryParse(_operatorsCtrl.text.trim());
                                final yieldRate = double.tryParse(_yieldCtrl.text.trim());

                                if (name.isEmpty) {
                                  setState(() => _validationError = 'Operation name is required.');
                                  return;
                                }
                                if (cycle == null || cycle < 0) {
                                  setState(() => _validationError = 'Cycle time must be a non-negative number.');
                                  return;
                                }
                                if (setup == null || setup < 0) {
                                  setState(() => _validationError = 'Setup time must be a non-negative number.');
                                  return;
                                }
                                if (cap == null || cap < 1) {
                                  setState(() => _validationError = 'Standard capacity must be at least 1 unit/hr.');
                                  return;
                                }
                                if (operators != null && operators < 0) {
                                  setState(() => _validationError = 'Required operators cannot be negative.');
                                  return;
                                }
                                if (yieldRate != null && (yieldRate < 0 || yieldRate > 100)) {
                                  setState(() => _validationError = 'Yield rate must be between 0% and 100%.');
                                  return;
                                }

                                setState(() {
                                  _validationError = null;
                                  _isSaving = true;
                                });

                                final skills = _skillsCtrl.text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();

                                final payload = {
                                  'name': name,
                                  'node_type': _nodeType,
                                  'cycle_time_seconds': cycle,
                                  'setup_time_seconds': setup,
                                  'standard_capacity_per_hour': cap,
                                  'required_operators': operators ?? 1,
                                  'operator_role': _roleCtrl.text.trim(),
                                  'required_skills': skills,
                                  'yield_rate_percent': yieldRate ?? 100.0,
                                  'assigned_line': _selectedLineId,
                                  'assigned_machine': _selectedMachineId,
                                };

                                try {
                                  await notifier.updateNode(node.id, payload);
                                  if (mounted) setState(() => _isSaving = false);
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _isSaving = false;
                                      _validationError = 'Failed to update node: $e';
                                    });
                                  }
                                }
                              },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Incoming Connections
                  Text('Incoming Connections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textPrimary)),
                  const SizedBox(height: 8),
                  if (ver != null) ...[
                    ...ver.edges.where((e) => e.targetNode == node.id).map((e) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.arrow_forward, size: 14),
                        title: Text('${e.sourceNodeKey} ➔ this', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text(e.edgeType, style: TextStyle(fontSize: 11, color: widget.textSecondary)),
                        trailing: isPublished
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: FactoryColors.statusOffline),
                                onPressed: () => notifier.deleteEdge(e.id),
                              ),
                      );
                    }),
                    if (ver.edges.where((e) => e.targetNode == node.id).isEmpty && node.nodeType != 'START')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No incoming connections (unreachable from START).',
                          style: TextStyle(fontSize: 11, color: FactoryColors.statusOffline, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                  const SizedBox(height: 14),

                  // Outgoing Connections
                  Text('Outgoing Connections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textPrimary)),
                  const SizedBox(height: 8),
                  if (ver != null) ...[
                    ...ver.edges.where((e) => e.sourceNode == node.id).map((e) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.arrow_forward, size: 14),
                        title: Text('➔ ${e.targetNodeKey}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text(e.edgeType, style: TextStyle(fontSize: 11, color: widget.textSecondary)),
                        trailing: isPublished
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: FactoryColors.statusOffline),
                                onPressed: () => notifier.deleteEdge(e.id),
                              ),
                      );
                    }),
                    if (ver.edges.where((e) => e.sourceNode == node.id).isEmpty && node.nodeType != 'END')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No outgoing connections (dead end).',
                          style: TextStyle(fontSize: 11, color: FactoryColors.statusOffline, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (!isPublished && node.nodeType != 'START' && node.nodeType != 'END')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('inspector_delete_node_button'),
                style: OutlinedButton.styleFrom(foregroundColor: FactoryColors.statusOffline),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete Node'),
                onPressed: () => notifier.deleteNode(node.id),
              ),
            ),
        ],
      ),
    );
  }
}

