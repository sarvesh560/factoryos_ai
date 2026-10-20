/// FactoryOS AI — Work Order State Controller
/// Phase 3: Work Order Management, Order Scheduling & Execution Initiation
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/process_models.dart';
import '../../data/repositories/process_repository.dart';

class WorkOrderState {
  final List<WorkOrderItem> orders;
  final bool isLoading;
  final String? actionLoadingOrderId;
  final String? statusFilter;
  final String? factoryFilter;
  final String? errorMessage;
  final String? successMessage;

  const WorkOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.actionLoadingOrderId,
    this.statusFilter,
    this.factoryFilter,
    this.errorMessage,
    this.successMessage,
  });

  WorkOrderState copyWith({
    List<WorkOrderItem>? orders,
    bool? isLoading,
    String? actionLoadingOrderId,
    bool clearActionLoading = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? factoryFilter,
    bool clearFactoryFilter = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return WorkOrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      actionLoadingOrderId: clearActionLoading ? null : (actionLoadingOrderId ?? this.actionLoadingOrderId),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      factoryFilter: clearFactoryFilter ? null : (factoryFilter ?? this.factoryFilter),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

class WorkOrderNotifier extends Notifier<WorkOrderState> {
  late final ProcessRepository _repository;

  @override
  WorkOrderState build() {
    _repository = ref.watch(processRepositoryProvider);
    Future.microtask(() => loadOrders());
    return const WorkOrderState(isLoading: true);
  }

  Future<void> loadOrders({String? factoryId, String? status}) async {
    final targetFactory = factoryId ?? state.factoryFilter;
    final targetStatus = status ?? state.statusFilter;
    state = state.copyWith(isLoading: true, clearErrorMessage: true, factoryFilter: targetFactory);
    try {
      final list = await _repository.getWorkOrders(
        factoryId: targetFactory,
        status: targetStatus,
      );
      state = state.copyWith(orders: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load work orders: $e');
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
    loadOrders(status: status);
  }

  void setFactory(String? factoryId) {
    state = state.copyWith(factoryFilter: factoryId, clearFactoryFilter: factoryId == null);
    loadOrders(factoryId: factoryId);
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    state = state.copyWith(clearErrorMessage: true, clearSuccessMessage: true);
    try {
      final created = await _repository.createWorkOrder(data);
      await loadOrders(factoryId: state.factoryFilter);
      state = state.copyWith(successMessage: "Work order '${created.orderNumber}' created successfully.");
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(errorMessage: 'Failed to create work order: $msg');
      return false;
    }
  }

  Future<void> executeAction(String orderId, String action, {Map<String, dynamic>? extra}) async {
    state = state.copyWith(actionLoadingOrderId: orderId, clearErrorMessage: true, clearSuccessMessage: true);
    try {
      await _repository.executeWorkOrderAction(orderId, action, payload: extra);
      await loadOrders(factoryId: state.factoryFilter);
      state = state.copyWith(successMessage: "Work order action '${action.toUpperCase()}' executed successfully.");
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(errorMessage: 'Action failed: $msg');
    } finally {
      state = state.copyWith(clearActionLoading: true);
    }
  }
}

final workOrderControllerProvider =
    NotifierProvider<WorkOrderNotifier, WorkOrderState>(() => WorkOrderNotifier());
