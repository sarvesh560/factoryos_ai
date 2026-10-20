/// FactoryOS AI — Process Builder State Controller
/// Phase 3: Visual Graph Canvas, Panning, Zooming, Node Selection & Publishing
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class ProcessBuilderState {
  final ProcessVersionItem? currentVersion;
  final ProcessNodeItem? selectedNode;
  final ProcessEdgeItem? selectedEdge;
  final bool isLoading;
  final bool isSaving;
  final bool isValidating;
  final GraphValidationResult? validationResult;
  final double zoomLevel;
  final Offset panOffset;
  final bool isConnecting;
  final ProcessNodeItem? connectingSourceNode;
  final String? errorMessage;
  final String? successMessage;

  const ProcessBuilderState({
    this.currentVersion,
    this.selectedNode,
    this.selectedEdge,
    this.isLoading = false,
    this.isSaving = false,
    this.isValidating = false,
    this.validationResult,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.isConnecting = false,
    this.connectingSourceNode,
    this.errorMessage,
    this.successMessage,
  });

  ProcessBuilderState copyWith({
    ProcessVersionItem? currentVersion,
    ProcessNodeItem? selectedNode,
    bool clearSelectedNode = false,
    ProcessEdgeItem? selectedEdge,
    bool clearSelectedEdge = false,
    bool? isLoading,
    bool? isSaving,
    bool? isValidating,
    GraphValidationResult? validationResult,
    bool clearValidationResult = false,
    double? zoomLevel,
    Offset? panOffset,
    bool? isConnecting,
    ProcessNodeItem? connectingSourceNode,
    bool clearConnectingSource = false,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProcessBuilderState(
      currentVersion: currentVersion ?? this.currentVersion,
      selectedNode: clearSelectedNode ? null : (selectedNode ?? this.selectedNode),
      selectedEdge: clearSelectedEdge ? null : (selectedEdge ?? this.selectedEdge),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isValidating: isValidating ?? this.isValidating,
      validationResult: clearValidationResult ? null : (validationResult ?? this.validationResult),
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      isConnecting: isConnecting ?? this.isConnecting,
      connectingSourceNode: clearConnectingSource ? null : (connectingSourceNode ?? this.connectingSourceNode),
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ProcessBuilderNotifier extends Notifier<ProcessBuilderState> {
  late final ProcessRepository _repository;

  @override
  ProcessBuilderState build() {
    _repository = ref.watch(processRepositoryProvider);
    return const ProcessBuilderState();
  }

  Future<void> loadVersion(String versionId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final version = await _repository.getProcessVersion(versionId);
      final meta = version.graphMetadata;
      double zoom = 1.0;
      Offset pan = Offset.zero;
      if (meta.containsKey('zoom')) {
        zoom = (meta['zoom'] as num).toDouble();
      }
      if (meta.containsKey('pan_x') && meta.containsKey('pan_y')) {
        pan = Offset((meta['pan_x'] as num).toDouble(), (meta['pan_y'] as num).toDouble());
      }

      state = state.copyWith(
        currentVersion: version,
        isLoading: false,
        zoomLevel: zoom,
        panOffset: pan,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load process version: $e');
    }
  }

  void selectNode(ProcessNodeItem? node) {
    state = state.copyWith(
      selectedNode: node,
      clearSelectedNode: node == null,
      clearSelectedEdge: true,
      errorMessage: null,
      successMessage: null,
    );
  }

  void selectEdge(ProcessEdgeItem? edge) {
    state = state.copyWith(
      selectedEdge: edge,
      clearSelectedEdge: edge == null,
      clearSelectedNode: true,
      errorMessage: null,
      successMessage: null,
    );
  }

  void updateNodePosition(String nodeKey, Offset delta) {
    final ver = state.currentVersion;
    if (ver == null || ver.isPublished) return;

    final updatedNodes = ver.nodes.map((n) {
      if (n.nodeKey == nodeKey) {
        return n.copyWith(
          positionX: n.positionX + delta.dx,
          positionY: n.positionY + delta.dy,
        );
      }
      return n;
    }).toList();

    state = state.copyWith(
      currentVersion: ProcessVersionItem(
        id: ver.id,
        processDefinition: ver.processDefinition,
        versionNumber: ver.versionNumber,
        versionTag: ver.versionTag,
        status: ver.status,
        changeSummary: ver.changeSummary,
        isPublished: ver.isPublished,
        validationErrors: ver.validationErrors,
        graphMetadata: ver.graphMetadata,
        nodeCount: ver.nodeCount,
        edgeCount: ver.edgeCount,
        nodes: updatedNodes,
        edges: ver.edges,
        publishedAt: ver.publishedAt,
        createdAt: ver.createdAt,
      ),
    );
  }

  void setZoom(double newZoom) {
    final clamped = newZoom.clamp(0.4, 2.5);
    state = state.copyWith(zoomLevel: clamped);
  }

  void setPan(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  Future<void> saveLayout() async {
    final ver = state.currentVersion;
    if (ver == null) return;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final nodesData = ver.nodes.map((n) => {
        'id': n.id,
        'position_x': n.positionX,
        'position_y': n.positionY,
      }).toList();

      final meta = {
        'zoom': state.zoomLevel,
        'pan_x': state.panOffset.dx,
        'pan_y': state.panOffset.dy,
      };

      await _repository.saveGraphLayout(ver.id, metadata: meta, nodes: nodesData);
      state = state.copyWith(isSaving: false, successMessage: 'Layout saved successfully.');
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save layout: $e');
    }
  }

  Future<void> addNode({
    required String name,
    required String nodeType,
    double cycleTimeSeconds = 30.0,
    int capacityPerHour = 60,
    String? assignedLine,
    String? assignedMachine,
  }) async {
    final ver = state.currentVersion;
    if (ver == null) return;

    try {
      final payload = {
        'name': name,
        'node_type': nodeType,
        'position_x': -state.panOffset.dx + 300,
        'position_y': -state.panOffset.dy + 250,
        'cycle_time_seconds': cycleTimeSeconds,
        'standard_capacity_per_hour': capacityPerHour,
        'assigned_line': assignedLine,
        'assigned_machine': assignedMachine,
      };

      await _repository.addNode(ver.id, payload);
      await loadVersion(ver.id);
      state = state.copyWith(
        clearValidationResult: true,
        successMessage: "Node '$name' added.",
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add node: $e');
    }
  }

  Future<void> updateNode(String nodeId, Map<String, dynamic> data) async {
    final ver = state.currentVersion;
    if (ver == null) return;

    try {
      final updated = await _repository.updateNode(nodeId, data);
      await loadVersion(ver.id);
      state = state.copyWith(
        clearValidationResult: true,
        selectedNode: updated,
        successMessage: "Node '${updated.name}' updated.",
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update node: $e');
    }
  }

  Future<void> deleteNode(String nodeId) async {
    final ver = state.currentVersion;
    if (ver == null) return;

    try {
      await _repository.deleteNode(nodeId);
      await loadVersion(ver.id);
      state = state.copyWith(
        clearValidationResult: true,
        clearSelectedNode: true,
        successMessage: 'Node deleted successfully.',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete node: $e');
    }
  }

  void startConnecting(ProcessNodeItem sourceNode) {
    state = state.copyWith(
      isConnecting: true,
      connectingSourceNode: sourceNode,
      successMessage: "Connecting from '${sourceNode.name}'. Select a target node.",
    );
  }

  void cancelConnecting() {
    state = state.copyWith(
      isConnecting: false,
      clearConnectingSource: true,
      successMessage: null,
    );
  }

  Future<void> completeConnecting(ProcessNodeItem targetNode, {String edgeType = 'STANDARD', String condition = ''}) async {
    final ver = state.currentVersion;
    final src = state.connectingSourceNode;
    if (ver == null || src == null) return;

    if (src.id == targetNode.id) {
      state = state.copyWith(errorMessage: 'Cannot connect a node to itself.');
      cancelConnecting();
      return;
    }

    try {
      final payload = {
        'source_node': src.id,
        'target_node': targetNode.id,
        'edge_type': edgeType,
        'condition_expression': condition,
      };
      await _repository.addEdge(ver.id, payload);
      cancelConnecting();
      await loadVersion(ver.id);
      state = state.copyWith(
        clearValidationResult: true,
        successMessage: "Connected '${src.name}' -> '${targetNode.name}'.",
      );
    } catch (e) {
      state = state.copyWith(isConnecting: false, clearConnectingSource: true, errorMessage: 'Failed to connect edge: $e');
    }
  }

  Future<void> deleteEdge(String edgeId) async {
    final ver = state.currentVersion;
    if (ver == null) return;

    try {
      await _repository.deleteEdge(edgeId);
      await loadVersion(ver.id);
      state = state.copyWith(
        clearValidationResult: true,
        clearSelectedEdge: true,
        successMessage: 'Edge deleted.',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete edge: $e');
    }
  }

  void dismissValidationResult() {
    state = state.copyWith(clearValidationResult: true, errorMessage: null, successMessage: null);
  }

  Future<bool> validateGraph() async {
    final ver = state.currentVersion;
    if (ver == null) return false;

    state = state.copyWith(isValidating: true, errorMessage: null, successMessage: null);
    try {
      final result = await _repository.validateVersion(ver.id);
      final updatedVer = await _repository.getProcessVersion(ver.id);

      state = state.copyWith(
        isValidating: false,
        currentVersion: updatedVer,
        validationResult: result,
        successMessage: result.isValid ? 'Process graph validated successfully! Ready to publish.' : null,
        errorMessage: !result.isValid
            ? 'Validation failed with ${result.errors.length} issue${result.errors.length > 1 ? 's' : ''}. Resolve errors before publishing.'
            : null,
      );
      return result.isValid;
    } catch (e) {
      state = state.copyWith(isValidating: false, errorMessage: 'Validation error: $e');
      return false;
    }
  }

  Future<bool> publishVersion() async {
    final ver = state.currentVersion;
    if (ver == null) return false;

    // Guard: Do not publish if known to be invalid
    if (state.validationResult != null && !state.validationResult!.isValid) {
      state = state.copyWith(
        errorMessage: 'Cannot publish: Graph validation has errors. Please resolve detected errors first.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final published = await _repository.publishVersion(ver.id);
      state = state.copyWith(
        isSaving: false,
        currentVersion: published,
        validationResult: const GraphValidationResult(isValid: true, status: 'PUBLISHED'),
        successMessage: "Process version '${published.versionTag}' published into production successfully!",
      );
      return true;
    } on ServerException catch (e) {
      GraphValidationResult? valResult;
      if (e.details is Map<String, dynamic>) {
        valResult = GraphValidationResult.fromJson(e.details as Map<String, dynamic>);
      }
      state = state.copyWith(
        isSaving: false,
        validationResult: valResult ?? state.validationResult,
        errorMessage: 'Cannot publish invalid process graph. Resolve validation errors first.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to publish version: $e');
      return false;
    }
  }

  Future<String?> cloneVersion(String definitionId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final cloned = await _repository.cloneVersion(definitionId);
      state = state.copyWith(
        isSaving: false,
        successMessage: "New editable draft version '${cloned.versionTag}' created.",
      );
      await loadVersion(cloned.id);
      return cloned.id;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to clone version: $e');
      return null;
    }
  }
}

final processBuilderControllerProvider =
    NotifierProvider<ProcessBuilderNotifier, ProcessBuilderState>(() => ProcessBuilderNotifier());
