import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/app_animations.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/factory_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/factories/presentation/controllers/factory_controller.dart';
import '../../features/factories/presentation/widgets/factory_selector_dropdown.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1024;
    final effectiveCollapsed = isTablet ? true : _isSidebarCollapsed;

    final canvasColor = isDark ? FactoryColors.darkCanvas : FactoryColors.lightCanvas;
    final sidebarBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final headerBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    return Scaffold(
      backgroundColor: canvasColor,
      body: Row(
        children: [
          // Collapsible Animated Sidebar
          AnimatedContainer(
            duration: AppAnimations.responsiveDuration(context, AppAnimations.medium),
            curve: AppAnimations.easeInOut,
            width: effectiveCollapsed
                ? FactorySpacing.sidebarCollapsedWidth
                : FactorySpacing.sidebarExpandedWidth,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor, width: 1)),
            ),
            child: _SidebarContent(
              isCollapsed: effectiveCollapsed,
              onToggleCollapse: _toggleSidebar,
              isDark: isDark,
            ),
          ),
          // Main Body Canvas with Top Navigation
          Expanded(
            child: Column(
              children: [
                // Top Navigation Bar
                Container(
                  height: FactorySpacing.topNavHeight,
                  padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg),
                  decoration: BoxDecoration(
                    color: headerBg,
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    children: [
                      if (isTablet)
                        IconButton(
                          icon: const Icon(Icons.menu, size: 20),
                          onPressed: _toggleSidebar,
                          splashRadius: 18,
                        ),
                      // Active Factory Selector Dropdown
                      const FactorySelectorDropdown(),
                      const SizedBox(width: FactorySpacing.xs),
                      IconButton(
                        tooltip: 'Onboard New Plant',
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: FactoryColors.primaryBlue),
                        splashRadius: 18,
                        onPressed: () => context.go('/onboarding'),
                      ),
                      const Spacer(),
                      // Backend Connection Status Indicator
                      const _BackendStatusIndicator(),
                      const SizedBox(width: FactorySpacing.sm),
                      // Refresh Telemetry Button
                      IconButton(
                        tooltip: 'Refresh Telemetry',
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        splashRadius: 18,
                        onPressed: () {
                          ref.read(factoryControllerProvider.notifier).refreshCurrentFactory();
                        },
                      ),
                      const SizedBox(width: FactorySpacing.xs),
                      // Theme Mode Toggle (Light/Dark)
                      Consumer(
                        builder: (context, ref, _) {
                          final currentTheme = ref.watch(themeProvider);
                          final isDarkNow = currentTheme == ThemeMode.dark;
                          return IconButton(
                            tooltip: isDarkNow ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            icon: AnimatedSwitcher(
                              duration: AppAnimations.fast,
                              child: Icon(
                                isDarkNow ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                key: ValueKey(isDarkNow),
                                size: 18,
                              ),
                            ),
                            splashRadius: 18,
                            onPressed: () {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                          );
                        },
                      ),
                      const SizedBox(width: FactorySpacing.sm),
                      // Enterprise Tenant Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                          borderRadius: BorderRadius.circular(FactoryRadius.pill),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.corporate_fare,
                              size: 14,
                              color: FactoryColors.primaryBlue,
                            ),
                            if (!isTablet) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Universal Global Corp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Screen Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final bool isDark;

  const _SidebarContent({
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return Column(
      children: [
        // Brand Header
        Container(
          height: FactorySpacing.topNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.md),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FactoryColors.primaryBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: FactoryColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: FactorySpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'FactoryOS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: FactoryColors.primaryBlue,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Industrial Automation',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        // Navigation Links
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: FactorySpacing.md),
            children: [
              _SidebarNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Command Center',
                route: '/command-center',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.precision_manufacturing_outlined,
                activeIcon: Icons.precision_manufacturing,
                label: 'Production Lines',
                route: '/lines',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.domain_outlined,
                activeIcon: Icons.domain,
                label: 'Facility Overview',
                route: '/details',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.business_outlined,
                activeIcon: Icons.business,
                label: 'Companies & Plants',
                route: '/companies',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: 'Onboard Factory',
                route: '/onboarding',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (!isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'PROCESS ENGINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Divider(height: 1),
                ),
              _SidebarNavItem(
                icon: Icons.account_tree_outlined,
                activeIcon: Icons.account_tree,
                label: 'Process Workflows',
                route: '/processes',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'Work Orders',
                route: '/work-orders',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_circle_filled,
                label: 'Live Execution',
                route: '/production-execution',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.sync_alt_outlined,
                activeIcon: Icons.sync_alt,
                label: 'Material Flow',
                route: '/material-flow',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              _SidebarNavItem(
                icon: Icons.science_outlined,
                activeIcon: Icons.science,
                label: 'Simulation Console',
                route: '/simulation',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (!isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'AI AGENTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Divider(height: 1),
                ),
              _SidebarNavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'Agent Automation',
                route: '/agent-automation',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (!isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Divider(height: 1),
                ),
              _SidebarNavItem(
                icon: Icons.monitor_heart_outlined,
                activeIcon: Icons.monitor_heart,
                label: 'System Health',
                route: '/health',
                isCollapsed: isCollapsed,
                isDark: isDark,
              ),
            ],
          ),
        ),
        // Footer: Collapse Toggle
        const Divider(height: 1),
        InkWell(
          onTap: onToggleCollapse,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.md),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  size: 20,
                  color: textSecondary,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: FactorySpacing.sm),
                  Text(
                    'Collapse Sidebar',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isCollapsed;
  final bool isDark;

  const _SidebarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isCollapsed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == route || (route == '/command-center' && currentRoute == '/');

    final activeBg = isDark
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
        : FactoryColors.primaryBlueTint;
    final activeFg = FactoryColors.primaryBlue;
    final inactiveFg = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return Tooltip(
      message: isCollapsed ? label : '',
      waitDuration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(FactoryRadius.sm),
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(FactoryRadius.sm),
              border: isActive
                  ? Border.all(
                      color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.4) : FactoryColors.primaryBlueBorder,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 18,
                  color: isActive ? activeFg : inactiveFg,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? activeFg : (isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackendStatusIndicator extends ConsumerWidget {
  const _BackendStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factoryControllerProvider);
    final status = state.connectionStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color dotColor;
    String label;
    switch (status) {
      case ConnectionStatus.connected:
        dotColor = FactoryColors.statusRunning;
        label = 'Backend Connected';
        break;
      case ConnectionStatus.degraded:
        dotColor = FactoryColors.statusIdle;
        label = 'Backend Degraded';
        break;
      case ConnectionStatus.disconnected:
        dotColor = FactoryColors.statusOffline;
        label = 'Backend Offline';
        break;
    }

    return Tooltip(
      message: 'Django REST API: $label\nPostgreSQL Storage: Connected\nEndpoint: http://127.0.0.1:8000',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(FactoryRadius.pill),
          border: Border.all(
            color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
