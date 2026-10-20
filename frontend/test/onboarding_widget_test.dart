import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:factoryos_frontend/features/factories/data/repositories/factory_repository.dart';
import 'package:factoryos_frontend/features/factories/data/models/factory_model.dart';
import 'package:factoryos_frontend/features/factories/presentation/controllers/factory_controller.dart';
import 'package:factoryos_frontend/features/factories/presentation/screens/company_management_screen.dart';
import 'package:factoryos_frontend/features/factories/presentation/screens/universal_onboarding_screen.dart';

class MockOnboardingRepository extends FactoryRepository {
  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {'status': 'healthy', 'success': true};
  }

  @override
  Future<List<CompanyItem>> getCompanies({bool includeArchived = false}) async {
    return [
      const CompanyItem(
        id: 'comp-1',
        name: 'Apex Global Industries',
        slug: 'apex-global-industries',
        description: 'Advanced manufacturing enterprise holding',
        website: 'https://apex.example.com',
        contactEmail: 'ops@apex.example.com',
        isActive: true,
        factoryCount: 1,
        factories: [
          FactoryItem(
            id: 'fact-1',
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
        ],
      ),
    ];
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
        id: 'fact-1',
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
  Future<List<IndustryTemplate>> getIndustryTemplates() async {
    return [
      const IndustryTemplate(
        id: 'automotive_ev',
        title: 'Automotive & EV Powertrain',
        industryType: 'AUTOMOTIVE',
        industryCustom: 'Electric Vehicle Powertrain',
        description: 'Automotive manufacturing template',
        icon: 'directions_car',
        defaults: {
          'factory_name': 'NextGen EV Facility',
          'code_prefix': 'EV',
          'products': [
            {'name': 'Stator Rotor Assembly', 'sku': 'EV-STAT-01', 'unit_of_measure': 'units', 'target_hourly_rate': 120}
          ],
          'raw_materials': [
            {'name': 'Silicon Steel Sheet', 'code': 'RAW-STL-01', 'category': 'Metals', 'unit_of_measure': 'kg', 'safety_stock': 1000.0}
          ],
          'process_stages': [
            {'sequence': 1, 'name': 'Lamination Stamping', 'cycle_time_seconds': 30, 'quality_check_required': true, 'description': 'Precision stamping'}
          ],
          'production_lines': [
            {
              'name': 'Assembly Line 1',
              'code': 'LINE-01',
              'target_hourly_units': 120,
              'machines': [
                {'name': 'Stamping Press', 'code': 'M-01', 'machine_type': 'Press', 'rated_power_kw': 30.0}
              ]
            }
          ],
          'shifts': [
            {'name': 'Shift 1', 'start_time': '06:00', 'end_time': '14:00', 'operating_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], 'planned_capacity_units': 1000}
          ]
        },
      ),
    ];
  }

  @override
  Future<List<OnboardingDraftItem>> getOnboardingDrafts() async {
    return [
      const OnboardingDraftItem(
        id: 'draft-test-123',
        name: 'Aerospace Plant Alpha',
        currentStep: 3,
        status: 'IN_PROGRESS',
        createdAt: '2026-10-20T00:00:00Z',
        updatedAt: '2026-10-20T00:00:00Z',
        wizardData: {
          'company_name': 'Apex Global Industries',
          'factory_name': 'Alpha Aero 1',
          'industry_type': 'AEROSPACE',
          'factory_type': 'PRIMARY_MANUFACTURING',
          'manufacturing_model': 'DISCRETE',
        },
      ),
    ];
  }

  @override
  Future<OnboardingDraftItem> saveOnboardingDraft({
    String? id,
    required String name,
    required int currentStep,
    String aiPrompt = '',
    Map<String, dynamic> aiSuggestions = const {},
    required Map<String, dynamic> wizardData,
  }) async {
    return OnboardingDraftItem(
      id: id ?? 'draft-test-123',
      name: name,
      currentStep: currentStep,
      status: 'IN_PROGRESS',
      createdAt: '2026-10-20T00:00:00Z',
      updatedAt: '2026-10-20T00:00:00Z',
      wizardData: wizardData,
    );
  }

  @override
  Future<void> deleteOnboardingDraft(String draftId) async {}
}

void main() {
  testWidgets('CompanyManagementScreen renders enterprise companies and factories list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          factoryRepositoryProvider.overrideWithValue(MockOnboardingRepository()),
        ],
        child: const MaterialApp(
          home: CompanyManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Enterprise Companies & Factories'), findsOneWidget);
    expect(find.text('Apex Global Industries'), findsOneWidget);
    expect(find.text('Apex Precision Textiles'), findsOneWidget);
    expect(find.text('Register Company'), findsOneWidget);
  });

  testWidgets('UniversalOnboardingScreen renders 8-step wizard with action buttons and draft controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          factoryRepositoryProvider.overrideWithValue(MockOnboardingRepository()),
        ],
        child: const MaterialApp(
          home: UniversalOnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Universal Factory Onboarding'), findsOneWidget);
    expect(find.text('Industry Templates'), findsOneWidget);
    expect(find.text('AI Advisor Assist'), findsOneWidget);
    expect(find.textContaining('Resume Draft'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Step 1: Enterprise Company Holding'), findsOneWidget);
  });

  testWidgets('UniversalOnboardingScreen opens saved drafts dialog and lists drafts', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          factoryRepositoryProvider.overrideWithValue(MockOnboardingRepository()),
        ],
        child: const MaterialApp(
          home: UniversalOnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Resume Draft button
    final resumeBtn = find.textContaining('Resume Draft');
    expect(resumeBtn, findsOneWidget);
    await tester.tap(resumeBtn);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Saved Onboarding Sessions'), findsOneWidget);
    expect(find.text('Aerospace Plant Alpha'), findsOneWidget);
  });

  testWidgets('UniversalOnboardingScreen navigates to Step 2 and displays universal manufacturing controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          factoryRepositoryProvider.overrideWithValue(MockOnboardingRepository()),
        ],
        child: const MaterialApp(
          home: UniversalOnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // In Step 1, select the existing company 'Apex Global Industries'
    final selectCompanyDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.tap(selectCompanyDropdown);
    await tester.pumpAndSettle();

    final apexOption = find.text('Apex Global Industries (1 factories)').last;
    await tester.tap(apexOption);
    await tester.pumpAndSettle();

    // Click Continue to next step
    final nextBtn = find.textContaining('Continue to');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Verify Step 2 rendered with universal fields
    expect(find.text('Step 2: Manufacturing Facility Details'), findsOneWidget);
    expect(find.text('Operational Factory Type'), findsOneWidget);
    expect(find.text('Manufacturing Operating Model'), findsOneWidget);
    expect(find.textContaining('Sector Compliance & Environmental Standard'), findsOneWidget);
  });
}
