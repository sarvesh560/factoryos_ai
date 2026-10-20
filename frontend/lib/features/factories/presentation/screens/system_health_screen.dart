import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../../../shared/widgets/factory_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../controllers/factory_controller.dart';

class SystemHealthScreen extends ConsumerStatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  ConsumerState<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends ConsumerState<SystemHealthScreen> {
  bool _isChecking = false;
  Map<String, dynamic>? _healthData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  Future<void> _fetchHealth() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });
    try {
      final repo = ref.read(factoryRepositoryProvider);
      final data = await repo.checkHealth();
      setState(() {
        _healthData = data;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final surfaceColor = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    final dbData = _healthData?['services']?['database'] as Map<String, dynamic>?;
    final isConnected = dbData?['connected'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FactorySpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FactorySpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health & Diagnostic Telemetry',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live diagnostic connection tracking for Django REST Framework and PostgreSQL 18',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                  FactoryButton(
                    text: 'Run Health Probe',
                    icon: Icons.refresh,
                    isLoading: _isChecking,
                    onPressed: _fetchHealth,
                  ),
                ],
              ),
              const SizedBox(height: FactorySpacing.lg),

              // Diagnostics Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Database Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(FactorySpacing.xl),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(FactoryRadius.md),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'POSTGRESQL DATABASE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              StatusBadge(
                                status: isConnected ? 'HEALTHY' : 'OFFLINE',
                                label: isConnected ? 'Connected' : 'Disconnected',
                              ),
                            ],
                          ),
                          const SizedBox(height: FactorySpacing.lg),
                          _healthItem('Engine', 'PostgreSQL 18 (Enterprise)', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('Connection Status', isConnected ? 'Active' : 'Unreachable', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('Ping Latency', dbData?['latency_ms'] != null ? '${dbData!['latency_ms']} ms' : '—', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('Connection Details', dbData?['details'] ?? 'No active probe response', textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: FactorySpacing.lg),
                  // API Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(FactorySpacing.xl),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(FactoryRadius.md),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DJANGO REST FRAMEWORK API',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const StatusBadge(
                                status: 'RUNNING',
                                label: 'Operational',
                              ),
                            ],
                          ),
                          const SizedBox(height: FactorySpacing.lg),
                          _healthItem('API Version', AppConfig.appVersion, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('Base Endpoint', AppConfig.apiBaseUrl, textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('Authentication', 'Development Mode (Clean Interfaces)', textPrimary, textSecondary),
                          const Divider(height: 16),
                          _healthItem('OpenAPI Schema', '${AppConfig.apiBaseUrl}/api/schema/', textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: FactorySpacing.lg),
                Container(
                  padding: const EdgeInsets.all(FactorySpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? FactoryColors.statusOfflineBgDark : FactoryColors.statusOfflineBgLight,
                    borderRadius: BorderRadius.circular(FactoryRadius.md),
                    border: Border.all(color: isDark ? FactoryColors.statusOfflineBorderDark : FactoryColors.statusOfflineBorderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: FactoryColors.statusOffline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 12, color: FactoryColors.statusOffline),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _healthItem(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
      ],
    );
  }
}
