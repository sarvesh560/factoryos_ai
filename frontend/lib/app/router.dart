import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/factories/presentation/screens/command_center_screen.dart';
import '../features/factories/presentation/screens/facility_overview_screen.dart';
import '../features/factories/presentation/screens/production_lines_screen.dart';
import '../features/factories/presentation/screens/system_health_screen.dart';
import '../features/factories/presentation/screens/company_management_screen.dart';
import '../features/factories/presentation/screens/universal_onboarding_screen.dart';
import '../features/processes/presentation/screens/process_library_screen.dart';
import '../features/processes/presentation/screens/visual_process_builder_screen.dart';
import '../features/processes/presentation/screens/work_order_management_screen.dart';
import '../features/processes/presentation/screens/live_execution_screen.dart';
import '../features/processes/presentation/screens/material_flow_screen.dart';
import '../features/processes/presentation/screens/simulation_console_screen.dart';
import '../features/agent_automation/presentation/screens/agent_automation_screen.dart';
import '../shared/layout/app_shell.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/command-center',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/command-center',
        ),
        GoRoute(
          path: '/command-center',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CommandCenterScreen(),
          ),
        ),
        GoRoute(
          path: '/lines',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProductionLinesScreen(),
          ),
        ),
        GoRoute(
          path: '/details',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FacilityOverviewScreen(),
          ),
        ),
        GoRoute(
          path: '/companies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CompanyManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: UniversalOnboardingScreen(),
          ),
        ),
        GoRoute(
          path: '/processes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProcessLibraryScreen(),
          ),
        ),
        GoRoute(
          path: '/processes/:versionId/builder',
          pageBuilder: (context, state) => NoTransitionPage(
            child: VisualProcessBuilderScreen(
              versionId: state.pathParameters['versionId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/work-orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkOrderManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/production-execution',
          pageBuilder: (context, state) => NoTransitionPage(
            child: LiveExecutionScreen(
              initialExecutionId: state.uri.queryParameters['executionId'],
              initialWorkOrderId: state.uri.queryParameters['workOrderId'],
            ),
          ),
        ),
        GoRoute(
          path: '/material-flow',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MaterialFlowScreen(),
          ),
        ),
        GoRoute(
          path: '/simulation',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SimulationConsoleScreen(),
          ),
        ),
        GoRoute(
          path: '/agent-automation',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AgentAutomationScreen(),
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SystemHealthScreen(),
          ),
        ),
      ],
    ),
  ],
);
