/// FactoryOS AI — Application Configuration
class AppConfig {
  static const String appName = 'FactoryOS AI';
  static const String appTagline = 'Universal Manufacturing Automation Platform';
  static const String appVersion = '2.0.0 (Phase 2)';

  // Backend API URL (Django REST Framework)
  static const String defaultApiBaseUrl = 'http://127.0.0.1:8000';

  // Configurable base URL via environment or runtime override
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  // System Endpoints
  static const String healthEndpoint = '/api/health/';

  // Company Endpoints
  static const String companiesEndpoint = '/api/companies/';
  static String companyDetailEndpoint(String id) => '/api/companies/$id/';
  static String companyArchiveEndpoint(String id) => '/api/companies/$id/archive/';
  static String companyFactoriesEndpoint(String id) => '/api/companies/$id/factories/';

  // Factory Endpoints
  static const String factoriesEndpoint = '/api/factories/';
  static String factoryDetailEndpoint(String id) => '/api/factories/$id/';
  static String factoryArchiveEndpoint(String id) => '/api/factories/$id/archive/';
  static String factoryOverviewEndpoint(String id) => '/api/factories/$id/overview/';
  static String factoryProductsEndpoint(String id) => '/api/factories/$id/products/';

  // Universal Onboarding Endpoints
  static const String aiSuggestEndpoint = '/api/onboarding/ai-suggest/';
  static const String onboardingTemplatesEndpoint = '/api/onboarding/templates/';
  static const String onboardingDraftsEndpoint = '/api/onboarding/drafts/';
  static String onboardingDraftDetailEndpoint(String id) => '/api/onboarding/drafts/$id/';
  static const String onboardingActivateEndpoint = '/api/onboarding/activate/';

  // Universal Manufacturing Process Engine (UMPE) Endpoints (Phase 3)
  static const String processTemplatesEndpoint = '/api/processes/templates/';
  static String processTemplateInstantiateEndpoint(String templateKey) => '/api/processes/templates/$templateKey/instantiate/';
  static const String processDefinitionsEndpoint = '/api/processes/definitions/';
  static String processDefinitionDetailEndpoint(String id) => '/api/processes/definitions/$id/';
  static String processDefinitionDuplicateEndpoint(String id) => '/api/processes/definitions/$id/duplicate/';
  static String processDefinitionArchiveEndpoint(String id) => '/api/processes/definitions/$id/archive/';
  static String processVersionCloneEndpoint(String id) => '/api/processes/definitions/$id/clone-version/';
  static String processVersionDetailEndpoint(String id) => '/api/processes/versions/$id/';
  static String processVersionValidateEndpoint(String id) => '/api/processes/versions/$id/validate/';
  static String processVersionPublishEndpoint(String id) => '/api/processes/versions/$id/publish/';
  static String processVersionLayoutEndpoint(String id) => '/api/processes/versions/$id/layout/';
  static String processNodesEndpoint(String versionId) => '/api/processes/versions/$versionId/nodes/';
  static String processNodeDetailEndpoint(String id) => '/api/processes/nodes/$id/';
  static String processEdgesEndpoint(String versionId) => '/api/processes/versions/$versionId/edges/';
  static String processEdgeDetailEndpoint(String id) => '/api/processes/edges/$id/';

  // Work Orders Endpoints
  static const String workOrdersEndpoint = '/api/processes/work-orders/';
  static String workOrderDetailEndpoint(String id) => '/api/processes/work-orders/$id/';
  static String workOrderActionEndpoint(String id, String action) => '/api/processes/work-orders/$id/$action/';

  // Production Execution Endpoints
  static const String processExecutionsEndpoint = '/api/processes/execution/';
  static String processExecutionDetailEndpoint(String id) => '/api/processes/execution/$id/';
  static String processExecutionActionEndpoint(String id, String action) => '/api/processes/execution/$id/$action/';
  static String stageAdvanceEndpoint(String stageId) => '/api/processes/execution/stages/$stageId/advance/';
  static String stageFailEndpoint(String stageId) => '/api/processes/execution/stages/$stageId/fail/';

  // Material Flow & WIP Endpoints
  static const String materialFlowsEndpoint = '/api/processes/materials/flows/';
  static const String materialWipSummaryEndpoint = '/api/processes/materials/wip-summary/';

  // Simulation Endpoints
  static const String simulationScenariosEndpoint = '/api/processes/simulation/scenarios/';
  static const String simulationInjectAnomalyEndpoint = '/api/processes/simulation/inject-anomaly/';
  static const String simulationStepEndpoint = '/api/processes/simulation/step/';
  static const String simulationRunFullEndpoint = '/api/processes/simulation/run-full/';

  // Production Events Audit Endpoints
  static const String productionEventsEndpoint = '/api/processes/events/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Polling intervals
  static const Duration healthCheckInterval = Duration(seconds: 10);
  static const Duration telemetryRefreshInterval = Duration(seconds: 15);
}
