import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:factoryos_frontend/app/app.dart';
import 'package:factoryos_frontend/shared/widgets/status_badge.dart';
import 'package:factoryos_frontend/shared/widgets/kpi_card.dart';
import 'package:factoryos_frontend/features/factories/data/repositories/factory_repository.dart';
import 'package:factoryos_frontend/features/factories/data/models/factory_model.dart';
import 'package:factoryos_frontend/features/factories/presentation/controllers/factory_controller.dart';

class MockFactoryRepository extends FactoryRepository {
  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {'status': 'healthy', 'success': true};
  }

  @override
  Future<List<FactoryItem>> getFactories({
    String? industryType,
    String? status,
    String? search,
    bool includeArchived = false,
  }) async {
    return [
      const FactoryItem(
        id: 'test-factory-1',
        name: 'Apex Precision Textiles',
        code: 'FAC-TEX-01',
        industryType: 'TEXTILE',
        industryTypeDisplay: 'Textile Manufacturing',
        configurationStatus: 'CONFIGURED',
        configurationStatusDisplay: 'Configured',
        location: 'Greensboro, NC',
        country: 'USA',
        timezone: 'America/New_York',
        totalProductionLines: 6,
        activeLines: 5,
        isActive: true,
      ),
    ];
  }

  @override
  Future<FactoryOverviewData> getFactoryOverview(String factoryId) async {
    return const FactoryOverviewData(
      factory: FactoryItem(
        id: 'test-factory-1',
        name: 'Apex Precision Textiles',
        code: 'FAC-TEX-01',
        industryType: 'TEXTILE',
        industryTypeDisplay: 'Textile Manufacturing',
        configurationStatus: 'CONFIGURED',
        configurationStatusDisplay: 'Configured',
        location: 'Greensboro, NC',
        country: 'USA',
        timezone: 'America/New_York',
        totalProductionLines: 6,
        activeLines: 5,
        isActive: true,
      ),
      metrics: MetricSnapshotItem(
        id: 'm-1',
        overallOee: 89.4,
        availability: 94.2,
        performance: 96.0,
        qualityRate: 98.8,
        energyConsumptionKwh: 3420.5,
        activeAlertsCount: 2,
        activeShifts: 3,
        plannedUnits: 75000,
        actualUnits: 72400,
        scrapUnits: 850,
        timestamp: '2026-10-15T12:00:00Z',
      ),
      linesSummary: LinesSummary(
        total: 6,
        running: 5,
        idle: 0,
        maintenance: 1,
        offline: 0,
        averageEfficiency: 92.5,
      ),
      productionLines: [
        ProductionLineItem(
          id: 'line-1',
          name: 'Automated Ring Spinning A1',
          code: 'TEX-SPIN-01',
          status: 'RUNNING',
          statusDisplay: 'Running',
          currentProduct: '30s Combed Cotton Yarn',
          efficiencyRate: 94.8,
          targetHourlyUnits: 450,
          actualHourlyUnits: 438,
          operatorCount: 2,
        ),
      ],
      alertsSummary: AlertsSummary(critical: 0, warning: 1, info: 1, totalActive: 2),
      shiftProgress: ShiftProgress(
        plannedUnits: 75000,
        actualUnits: 72400,
        scrapUnits: 850,
        completionPercentage: 96.5,
        currentShift: 'Day Shift',
      ),
    );
  }
}

void main() {
  testWidgets('FactoryOSApp builds without crashing and renders command center', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          factoryRepositoryProvider.overrideWithValue(MockFactoryRepository()),
        ],
        child: const FactoryOSApp(),
      ),
    );

    // Allow microtasks and state to settle
    await tester.pumpAndSettle();

    // Verify brand title is visible
    expect(find.text('FactoryOS'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Command Center'), findsOneWidget);
  });

  testWidgets('StatusBadge displays correct text and status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'RUNNING', label: 'Running Operational'),
        ),
      ),
    );

    expect(find.text('Running Operational'), findsOneWidget);
  });

  testWidgets('KpiCard displays formatted values and handles hover/tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KpiCard(
            title: 'Overall OEE',
            value: '89.4%',
            subtitle: 'Target: 85.0%',
            icon: Icons.speed,
            accentColor: Colors.blue,
            trendText: '+2.4%',
            isPositiveTrend: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('OVERALL OEE'), findsOneWidget);
    expect(find.text('89.4%'), findsOneWidget);
    expect(find.text('Target: 85.0%'), findsOneWidget);
    expect(find.text('+2.4%'), findsOneWidget);

    await tester.tap(find.byType(KpiCard));
    expect(tapped, isTrue);
  });
}
