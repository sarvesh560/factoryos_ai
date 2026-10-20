/// FactoryOS AI — Universal Onboarding Screen
/// Phase 2: Universal Manufacturing Onboarding
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../controllers/onboarding_controller.dart';
import '../../data/models/factory_model.dart';


class UniversalOnboardingScreen extends ConsumerWidget {
  const UniversalOnboardingScreen({super.key});

  static const List<String> stepTitles = [
    'Company Information',
    'Factory Information',
    'Products Manufactured',
    'Raw Materials',
    'Process Stages',
    'Machines & Lines',
    'Shifts & Capacity',
    'Review & Activate',
  ];


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(onboardingControllerProvider);
    final notifier = ref.read(onboardingControllerProvider.notifier);

    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;
    final cardBg = isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(FactorySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Action Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Universal Factory Onboarding',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Industry-independent configuration engine with AI-assisted topology proposals.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FactorySpacing.md),
                Row(
                  children: [
                    // Resume Draft Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: Text(
                        state.savedDrafts.isNotEmpty ? 'Resume Draft (${state.savedDrafts.length})' : 'Resume Draft',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _showDraftsDialog(context, ref),
                    ),
                    const SizedBox(width: FactorySpacing.sm),
                    // Save Draft Button
                    OutlinedButton.icon(
                      icon: state.isDraftSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(state.isDraftSaving ? 'Saving...' : 'Save Draft', style: const TextStyle(fontSize: 13)),
                      onPressed: state.isDraftSaving
                          ? null
                          : () => ref.read(onboardingControllerProvider.notifier).saveCurrentAsDraft(),
                    ),
                    const SizedBox(width: FactorySpacing.sm),
                    // Industry Templates Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.auto_stories_outlined, size: 16),
                      label: const Text('Industry Templates', style: TextStyle(fontSize: 13)),
                      onPressed: () => _showTemplatesDialog(context, ref),
                    ),
                    const SizedBox(width: FactorySpacing.sm),
                    // AI Advisor Assist Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FactoryColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.psychology_outlined, size: 18),
                      label: const Text('AI Advisor Assist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      onPressed: () => _showAiAdvisorDialog(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: FactorySpacing.md),

            // Active Draft Chip
            if (state.draftName != null)
              Container(
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_note, size: 18, color: FactoryColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Editing Saved Draft: ${state.draftName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FactoryColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => notifier.startNewDraft(),
                      child: const Text(
                        'Start Fresh',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),

            // Notification Banners
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusOfflineBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusOfflineBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: FactoryColors.statusOffline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.errorMessage!, style: const TextStyle(color: FactoryColors.statusOffline, fontSize: 13))),
                  ],
                ),
              ),

            if (state.successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: FactorySpacing.md),
                padding: const EdgeInsets.all(FactorySpacing.md),
                decoration: BoxDecoration(
                  color: FactoryColors.statusRunningBgLight,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                  border: Border.all(color: FactoryColors.statusRunningBorderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: FactoryColors.statusRunning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.successMessage!, style: const TextStyle(color: FactoryColors.statusRunning, fontSize: 13))),
                  ],
                ),
              ),

            // Stepper Header (8 Steps)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: FactorySpacing.lg, vertical: FactorySpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(FactoryRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(stepTitles.length, (idx) {
                    final stepNum = idx + 1;
                    final isActive = state.currentStep == stepNum;
                    final isDone = state.currentStep > stepNum;

                    Color circleBg;
                    Color circleText;
                    if (isActive) {
                      circleBg = FactoryColors.primaryBlue;
                      circleText = Colors.white;
                    } else if (isDone) {
                      circleBg = FactoryColors.statusRunningBgLight;
                      circleText = FactoryColors.statusRunning;
                    } else {
                      circleBg = isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle;
                      circleText = textSecondary;
                    }

                    return InkWell(
                      onTap: () {
                        if (stepNum > state.currentStep) {
                          final err = notifier.validateStep(state.currentStep);
                          if (err != null) {
                            return;
                          }
                        }
                        notifier.setStep(stepNum);
                      },
                      borderRadius: BorderRadius.circular(FactoryRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: circleBg,
                                shape: BoxShape.circle,
                              ),
                              child: isDone
                                  ? const Icon(Icons.check, size: 14, color: FactoryColors.statusRunning)
                                  : Text(
                                      '$stepNum',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: circleText,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stepTitles[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? FactoryColors.primaryBlue : (isDone ? textPrimary : textSecondary),
                              ),
                            ),
                            if (idx < stepTitles.length - 1) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.chevron_right, size: 16, color: borderColor),
                              const SizedBox(width: 4),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Step Content Canvas
            Container(
              padding: const EdgeInsets.all(FactorySpacing.xl),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(FactoryRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: _buildCurrentStep(context, ref, state),
            ),
            const SizedBox(height: FactorySpacing.lg),

            // Navigation Buttons (Prev / Next)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (state.currentStep > 1)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Previous Step'),
                    onPressed: notifier.previousStep,
                  )
                else
                  const SizedBox.shrink(),
                if (state.currentStep < 8)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FactoryColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text('Continue to ${stepTitles[state.currentStep]}'),
                    onPressed: notifier.nextStep,
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FactoryColors.statusRunning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    icon: state.isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch, size: 18),
                    label: Text(
                      state.isLoading ? 'Activating Factory...' : 'Activate Factory & Launch Command Center',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final factory = await notifier.activateFactory();
                            if (factory != null && context.mounted) {
                              context.go('/command-center');
                            }
                          },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCurrentStep(BuildContext context, WidgetRef ref, OnboardingState state) {
    switch (state.currentStep) {
      case 1:
        return _Step1Company(state: state);
      case 2:
        return _Step2Factory(state: state);
      case 3:
        return _Step3Products(state: state);
      case 4:
        return _Step4Materials(state: state);
      case 5:
        return _Step5Stages(state: state);
      case 6:
        return _Step6LinesAndMachines(state: state);
      case 7:
        return _Step7Shifts(state: state);
      case 8:
        return _Step8Review(state: state);
      default:
        return const SizedBox.shrink();
    }
  }


  // AI Advisor Dialog
  void _showAiAdvisorDialog(BuildContext context, WidgetRef ref) {
    final promptCtrl = TextEditingController(
      text: 'We manufacture precision automotive components using cutting, CNC machining, metrology inspection, and packaging.',
    );

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(onboardingControllerProvider);
          final isAiLoading = state.isAiLoading;
          final suggestion = state.aiSuggestion;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.psychology_rounded, color: FactoryColors.primaryBlue),
                SizedBox(width: 8),
                Text('AI Manufacturing Advisor'),
              ],
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Describe your manufacturing operation in natural language. The AI will propose products, raw materials, process stages, machines, and shifts:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: promptCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "e.g. 'We build industrial lithium battery packs using ultrasonic cell welding, thermal sealing, and automated testing.'",
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isAiLoading
                          ? null
                          : () {
                              ref.read(onboardingControllerProvider.notifier).requestAISuggestion(promptCtrl.text);
                            },
                      icon: isAiLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.bolt, size: 16),
                      label: Text(isAiLoading ? 'Analyzing Factory Architecture...' : 'Analyze & Propose Configuration'),
                    ),

                    if (suggestion != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Provider Badge & Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FactoryColors.statusIdleBgLight,
                          borderRadius: BorderRadius.circular(FactoryRadius.sm),
                          border: Border.all(color: FactoryColors.statusIdleBorderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 16, color: FactoryColors.statusIdle),
                                const SizedBox(width: 6),
                                Text(
                                  suggestion.providerName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: FactoryColors.statusIdle),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestion.disclaimer,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Summary preview of suggestion
                      Text(
                        'Proposed Factory: ${(suggestion.recommendedConfiguration['factory'] as Map?)?['name'] ?? "New Factory"}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Products: ${((suggestion.recommendedConfiguration['products'] as List?)?.length ?? 0)} items  •  '
                        'Stages: ${((suggestion.recommendedConfiguration['process_stages'] as List?)?.length ?? 0)} steps  •  '
                        'Lines: ${((suggestion.recommendedConfiguration['production_lines'] as List?)?.length ?? 0)} lines',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              if (suggestion != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: FactoryColors.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    ref.read(onboardingControllerProvider.notifier).confirmAndApplyAISuggestion();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirm & Apply to Wizard'),
                ),
            ],
          );
        },
      ),
    );
  }


  // Templates Dialog
  void _showTemplatesDialog(BuildContext context, WidgetRef ref) {
    final templates = ref.read(onboardingControllerProvider).templates;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Starting Industry Template'),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Start with a pre-configured architecture. Every process stage and field remains 100% customizable:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              ...templates.map((t) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FactoryColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing, color: FactoryColors.primaryBlue, size: 20),
                    ),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(t.description, style: const TextStyle(fontSize: 12), maxLines: 2),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      ref.read(onboardingControllerProvider.notifier).applyTemplate(t);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  // Saved Drafts Dialog
  void _showDraftsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(onboardingControllerProvider);
          final drafts = state.savedDrafts;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.folder_open, color: FactoryColors.primaryBlue),
                SizedBox(width: 8),
                Text('Saved Onboarding Sessions'),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume a previously saved manufacturing facility onboarding session:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (drafts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No saved drafts found. You can save your progress at any step using "Save Draft".',
                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: drafts.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final d = drafts[index];
                          final isCurrent = state.draftId == d.id;
                          return ListTile(
                            tileColor: isCurrent
                                ? FactoryColors.primaryBlue.withValues(alpha: 0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(FactoryRadius.sm),
                              side: BorderSide(
                                color: isCurrent ? FactoryColors.primaryBlue : Colors.transparent,
                              ),
                            ),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: FactoryColors.primaryBlue.withValues(alpha: 0.2),
                              child: Text(
                                '${d.currentStep}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: FactoryColors.primaryBlue),
                              ),
                            ),
                            title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('Step ${d.currentStep} of 8  •  Status: ${d.status}', style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FactoryColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () async {
                                    final ok = await ref.read(onboardingControllerProvider.notifier).loadSavedDraft(d.id);
                                    if (ok && context.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Resume', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: FactoryColors.statusOffline),
                                  onPressed: () => ref.read(onboardingControllerProvider.notifier).deleteSavedDraft(d.id),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
  
}

// ==========================================
// STEP 1: COMPANY INFORMATION
// ==========================================
class _Step1Company extends ConsumerWidget {
  final OnboardingState state;
  const _Step1Company({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Enterprise Company Holding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
        const SizedBox(height: 4),
        const Text('Select an existing enterprise holding or establish a new parent company for this manufacturing facility.', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 16),

        if (state.availableCompanies.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: state.selectedCompanyId,
            decoration: const InputDecoration(labelText: 'Parent Enterprise Company'),
            items: [
              const DropdownMenuItem(value: null, child: Text('+ Create New Company Holding')),
              ...state.availableCompanies.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.factoryCount} factories)'))),
            ],
            onChanged: (val) => notifier.selectCompany(val),
          ),
          const SizedBox(height: 16),
        ],

        TextFormField(
          initialValue: state.companyName,
          decoration: const InputDecoration(labelText: 'Company / Organization Name *', hintText: 'e.g. Apex Global Industries'),
          onChanged: (val) => notifier.updateCompanyInfo(name: val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.companyDescription,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Company Scope & Description', hintText: 'Global industrial automation holding'),
          onChanged: (val) => notifier.updateCompanyInfo(description: val),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.companyWebsite,
                decoration: const InputDecoration(labelText: 'Website', hintText: 'https://apexholdings.example.com'),
                onChanged: (val) => notifier.updateCompanyInfo(website: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.companyEmail,
                decoration: const InputDecoration(labelText: 'Operations Email', hintText: 'ops@apexholdings.example.com'),
                onChanged: (val) => notifier.updateCompanyInfo(email: val),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// STEP 2: FACTORY INFORMATION
// ==========================================
class _Step2Factory extends ConsumerWidget {
  final OnboardingState state;
  const _Step2Factory({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final cardBg = isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle;
    final capCtrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Manufacturing Facility Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
        const SizedBox(height: 4),
        const Text('Configure plant location, industry domain, operational factory type, manufacturing model, and sector compliance.', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: state.factoryName,
                decoration: const InputDecoration(labelText: 'Factory Name *', hintText: 'e.g. Apex Precision Propulsion Plant'),
                onChanged: (val) => notifier.updateFactoryInfo(name: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.factoryCode,
                decoration: const InputDecoration(labelText: 'Factory Code', hintText: 'e.g. FAC-AUTO-01'),
                onChanged: (val) => notifier.updateFactoryInfo(code: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: state.industryType,
                decoration: const InputDecoration(labelText: 'Industry Sector'),
                items: const [
                  DropdownMenuItem(value: 'AUTOMOTIVE', child: Text('Automotive & EV Parts')),
                  DropdownMenuItem(value: 'CNC_ENGINEERING', child: Text('CNC & Precision Machining')),
                  DropdownMenuItem(value: 'ELECTRONICS', child: Text('Electronics & High-Tech')),
                  DropdownMenuItem(value: 'PHARMACEUTICALS', child: Text('Pharmaceuticals & Biotech')),
                  DropdownMenuItem(value: 'FOOD_PROCESSING', child: Text('Food & Beverage')),
                  DropdownMenuItem(value: 'TEXTILE', child: Text('Textile & Technical Weaving')),
                  DropdownMenuItem(value: 'AEROSPACE', child: Text('Aerospace & Defense')),
                  DropdownMenuItem(value: 'HEAVY_MACHINERY', child: Text('Heavy Machinery')),
                  DropdownMenuItem(value: 'CHEMICALS', child: Text('Chemical Processing')),
                  DropdownMenuItem(value: 'CUSTOM', child: Text('Custom / Specialized')),
                ],
                onChanged: (val) => notifier.updateFactoryInfo(industryType: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.industryCustom,
                decoration: const InputDecoration(labelText: 'Custom Domain / Specialty', hintText: 'e.g. Robotic Sub-Assembly'),
                onChanged: (val) => notifier.updateFactoryInfo(industryCustom: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Factory Type & Manufacturing Model (Universal Industry Architecture)
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: state.factoryType,
                decoration: const InputDecoration(labelText: 'Operational Factory Type'),
                items: const [
                  DropdownMenuItem(value: 'PRIMARY_MANUFACTURING', child: Text('Primary Manufacturing Plant')),
                  DropdownMenuItem(value: 'SUB_ASSEMBLY', child: Text('Component & Sub-Assembly Facility')),
                  DropdownMenuItem(value: 'FINAL_ASSEMBLY', child: Text('Final Assembly & Integration')),
                  DropdownMenuItem(value: 'PACKAGING_DISTRIBUTION', child: Text('Packaging & Finishing Center')),
                  DropdownMenuItem(value: 'PILOT_PLANT', child: Text('Pilot Plant & Prototyping')),
                ],
                onChanged: (val) => notifier.updateFactoryInfo(factoryType: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: state.manufacturingModel,
                decoration: const InputDecoration(labelText: 'Manufacturing Operating Model'),
                items: const [
                  DropdownMenuItem(value: 'DISCRETE', child: Text('Discrete Manufacturing')),
                  DropdownMenuItem(value: 'BATCH', child: Text('Batch Processing')),
                  DropdownMenuItem(value: 'CONTINUOUS', child: Text('Continuous Process')),
                  DropdownMenuItem(value: 'JOB_SHOP', child: Text('Job Shop / Custom Machining')),
                  DropdownMenuItem(value: 'REPETITIVE', child: Text('Repetitive / High-Volume Assembly')),
                ],
                onChanged: (val) => notifier.updateFactoryInfo(manufacturingModel: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Conditional Sector Specifications Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: FactoryColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Sector Compliance & Environmental Standard (${state.industryType})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FactoryColors.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Adapt process validation, traceability criteria, and environmental cleanliness to industry regulations:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('compliance_${state.industryType}_${state.complianceStandard}'),
                      initialValue: state.complianceStandard,
                      decoration: const InputDecoration(
                        labelText: 'Quality / Regulatory Standard',
                        hintText: 'e.g. IATF 16949 / FDA cGMP / AS9100',
                      ),
                      onChanged: (val) => notifier.updateFactoryInfo(complianceStandard: val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('cleanroom_${state.industryType}_${state.cleanroomGrade}'),
                      initialValue: state.cleanroomGrade,
                      decoration: const InputDecoration(
                        labelText: 'Cleanroom / Hygiene Grade',
                        hintText: 'e.g. ISO Class 7 / Sanitation Zone 1',
                      ),
                      onChanged: (val) => notifier.updateFactoryInfo(cleanroomGrade: val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: state.location,
                decoration: const InputDecoration(labelText: 'Location / Park', hintText: 'e.g. High-Tech Industrial Park'),
                onChanged: (val) => notifier.updateFactoryInfo(location: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.country,
                decoration: const InputDecoration(labelText: 'Country', hintText: 'USA'),
                onChanged: (val) => notifier.updateFactoryInfo(country: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.timezone,
                decoration: const InputDecoration(labelText: 'Timezone', hintText: 'America/New_York'),
                onChanged: (val) => notifier.updateFactoryInfo(timezone: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.operatingHours,
                decoration: const InputDecoration(labelText: 'Operating Schedule', hintText: '06:00 - 22:00 (Two 8h Shifts)'),
                onChanged: (val) => notifier.updateFactoryInfo(operatingHours: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: state.targetDailyCapacity.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Daily Capacity (units)', hintText: '5000'),
                onChanged: (val) => notifier.updateFactoryInfo(targetDailyCapacity: int.tryParse(val) ?? 5000),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Capabilities Tagging
        const Text('Manufacturing Capabilities & Certifications:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...state.capabilities.map((cap) => Chip(
                  label: Text(cap, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => notifier.removeCapability(cap),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: capCtrl,
                decoration: const InputDecoration(hintText: 'Add capability (e.g. 5-Axis Milling)', isDense: true),
                onSubmitted: (val) {
                  notifier.addCapability(val);
                  capCtrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: FactoryColors.primaryBlue),
              onPressed: () {
                notifier.addCapability(capCtrl.text);
                capCtrl.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// STEP 3: PRODUCTS MANUFACTURED
// ==========================================
class _Step3Products extends ConsumerWidget {
  final OnboardingState state;
  const _Step3Products({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 3: Products Manufactured', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Define the finished goods, parts, and SKUs produced by this facility.', style: TextStyle(fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Product'),
              onPressed: () => _showAddProductDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No products defined yet. Click "Add Product" to add your first manufactured item.', style: TextStyle(fontStyle: FontStyle.italic))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.products.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = state.products[index];
              return ListTile(
                tileColor: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                leading: const Icon(Icons.inventory_2_outlined, color: FactoryColors.primaryBlue),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('SKU: ${p.sku}  •  Target: ${p.targetHourlyRate} ${p.unitOfMeasure}/hr', style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: FactoryColors.statusOffline),
                  onPressed: () => notifier.removeProduct(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final industry = ref.read(onboardingControllerProvider).industryType;
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final uomCtrl = TextEditingController(text: _defaultUnitForIndustry(industry));
    final rateCtrl = TextEditingController(text: '120');
    final suggestedUnits = _suggestedUnitsForIndustry(industry);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Manufactured Product'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. Turbine Rotor Housing')),
                const SizedBox(height: 10),
                TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU / Part Code', hintText: 'e.g. PART-TRB-01')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: uomCtrl, decoration: const InputDecoration(labelText: 'Unit of Measure', hintText: 'units, meters, kg'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Target Rate/hr', hintText: '120'))),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Suggested units for $industry:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: suggestedUnits.map((u) => ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(u, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        uomCtrl.text = u;
                      });
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(onboardingControllerProvider.notifier).addProduct(
                      ProductModel(
                        name: nameCtrl.text.trim(),
                        sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : 'SKU-${nameCtrl.text.trim().hashCode.abs().toString().substring(0, 4)}',
                        unitOfMeasure: uomCtrl.text.trim(),
                        targetHourlyRate: int.tryParse(rateCtrl.text) ?? 100,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  static String _defaultUnitForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'TEXTILE': return 'meters';
      case 'FOOD_BEVERAGE': return 'bottles';
      case 'PHARMACEUTICAL': return 'vials';
      case 'AUTOMOTIVE': return 'units';
      case 'CNC_MACHINING': return 'parts';
      case 'ELECTRONICS': return 'boards';
      case 'CHEMICAL': return 'liters';
      default: return 'units';
    }
  }

  static List<String> _suggestedUnitsForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'TEXTILE': return ['meters', 'yards', 'bolts', 'pieces', 'kg'];
      case 'FOOD_BEVERAGE': return ['bottles', 'pouches', 'cans', 'cases', 'kg', 'liters'];
      case 'PHARMACEUTICAL': return ['vials', 'blisters', 'tablets', 'bottles', 'doses'];
      case 'AUTOMOTIVE': return ['assemblies', 'units', 'chassis', 'sets'];
      case 'CNC_MACHINING': return ['parts', 'units', 'billets', 'components'];
      case 'ELECTRONICS': return ['boards', 'panels', 'units', 'reels'];
      case 'CHEMICAL': return ['liters', 'gallons', 'drums', 'barrels', 'kg'];
      default: return ['units', 'pieces', 'kg', 'batches'];
    }
  }
}

// ==========================================
// STEP 4: RAW MATERIALS
// ==========================================
class _Step4Materials extends ConsumerWidget {
  final OnboardingState state;
  const _Step4Materials({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 4: Raw Materials & Stock Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Specify the key materials, substrates, and components consumed in manufacturing.', style: TextStyle(fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Material'),
              onPressed: () => _showAddMaterialDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.rawMaterials.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No raw materials defined yet. Click "Add Material" to configure base stock.', style: TextStyle(fontStyle: FontStyle.italic))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.rawMaterials.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final m = state.rawMaterials[index];
              return ListTile(
                tileColor: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                leading: const Icon(Icons.layers_outlined, color: FactoryColors.statusIdle),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Code: ${m.code}  •  Category: ${m.category}  •  Safety Stock: ${m.safetyStock} ${m.unitOfMeasure}', style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: FactoryColors.statusOffline),
                  onPressed: () => notifier.removeRawMaterial(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddMaterialDialog(BuildContext context, WidgetRef ref) {
    final industry = ref.read(onboardingControllerProvider).industryType;
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: _defaultCategoryForIndustry(industry));
    final uomCtrl = TextEditingController(text: _defaultMaterialUnitForIndustry(industry));
    final stockCtrl = TextEditingController(text: '1000');
    final suggestedCats = _suggestedCategoriesForIndustry(industry);
    final suggestedUnits = _suggestedMaterialUnitsForIndustry(industry);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Raw Material / Stock Item'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Material Name *', hintText: 'e.g. Aluminum 6061 Billet')),
                  const SizedBox(height: 10),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Material Code', hintText: 'e.g. RAW-AL-6061')),
                  const SizedBox(height: 10),
                  TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', hintText: 'Metals, Polymers, Chemicals, Packaging')),
                  const SizedBox(height: 6),
                  Text('Industry categories ($industry):', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: suggestedCats.map((c) => ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(c, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          catCtrl.text = c;
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: uomCtrl, decoration: const InputDecoration(labelText: 'Unit of Measure', hintText: 'kg, liters, units'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Safety Stock', hintText: '500'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Industry units:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: suggestedUnits.map((u) => ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(u, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          uomCtrl.text = u;
                        });
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(onboardingControllerProvider.notifier).addRawMaterial(
                      RawMaterialModel(
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'RAW-${nameCtrl.text.trim().hashCode.abs().toString().substring(0, 4)}',
                        category: catCtrl.text.trim(),
                        unitOfMeasure: uomCtrl.text.trim(),
                        safetyStock: double.tryParse(stockCtrl.text) ?? 500.0,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add Material'),
            ),
          ],
        ),
      ),
    );
  }

  static String _defaultCategoryForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'AUTOMOTIVE': return 'Metals & Castings';
      case 'CNC_MACHINING': return 'Raw Billets';
      case 'TEXTILE': return 'Yarns & Fibers';
      case 'FOOD_BEVERAGE': return 'Ingredients';
      case 'PHARMACEUTICAL': return 'Active APIs';
      case 'ELECTRONICS': return 'Substrates & PCBA';
      case 'CHEMICAL': return 'Reagents';
      default: return 'General Stock';
    }
  }

  static List<String> _suggestedCategoriesForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'AUTOMOTIVE': return ['Sheet Metal', 'Castings', 'Fasteners', 'Wiring', 'Polymers'];
      case 'CNC_MACHINING': return ['Aluminum 6061', 'Stainless 316', 'Brass', 'Tooling', 'Coolant'];
      case 'TEXTILE': return ['Cotton Yarn', 'Polyester Thread', 'Dyes', 'Spun Silk', 'Zippers'];
      case 'FOOD_BEVERAGE': return ['Raw Grain', 'Milk Stock', 'Sugar', 'Flavorings', 'Packaging Film'];
      case 'PHARMACEUTICAL': return ['Active API', 'Excipients', 'Sterile Water', 'Glass Vials', 'Blister Foil'];
      case 'ELECTRONICS': return ['FR4 Substrates', 'Copper Foil', 'Solder Paste', 'IC Chips', 'Passives'];
      case 'CHEMICAL': return ['Solvents', 'Reactants', 'Catalysts', 'Acid Stock', 'Additives'];
      default: return ['Metals', 'Polymers', 'Chemicals', 'Raw Stock', 'Packaging'];
    }
  }

  static String _defaultMaterialUnitForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'CHEMICAL':
      case 'FOOD_BEVERAGE': return 'liters';
      case 'ELECTRONICS': return 'reels';
      case 'AUTOMOTIVE': return 'units';
      default: return 'kg';
    }
  }

  static List<String> _suggestedMaterialUnitsForIndustry(String industry) {
    switch (industry.toUpperCase()) {
      case 'TEXTILE': return ['kg', 'spools', 'meters', 'rolls'];
      case 'FOOD_BEVERAGE': return ['kg', 'liters', 'tons', 'bags'];
      case 'PHARMACEUTICAL': return ['kg', 'liters', 'grams', 'boxes'];
      case 'AUTOMOTIVE': return ['units', 'kg', 'sheets', 'coils'];
      case 'CNC_MACHINING': return ['bars', 'billets', 'kg', 'sheets'];
      case 'ELECTRONICS': return ['reels', 'units', 'tubes', 'trays'];
      case 'CHEMICAL': return ['liters', 'kg', 'drums', 'tons'];
      default: return ['kg', 'units', 'liters', 'meters'];
    }
  }
}

// ==========================================
// STEP 5: PROCESS STAGES
// ==========================================
class _Step5Stages extends ConsumerWidget {
  final OnboardingState state;
  const _Step5Stages({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 5: Manufacturing Process Stages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Ordered sequential workflow stages with cycle times and quality gates.', style: TextStyle(fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Process Stage'),
              onPressed: () => _showAddStageDialog(context, ref, state.processStages.length + 1),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.processStages.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No manufacturing stages defined yet.', style: TextStyle(fontStyle: FontStyle.italic))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.processStages.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = state.processStages[index];
              return ListTile(
                tileColor: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: FactoryColors.primaryBlue.withValues(alpha: 0.2),
                  child: Text('${s.sequence}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FactoryColors.primaryBlue)),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Cycle Time: ${s.cycleTimeSeconds}s  •  Quality Gate: ${s.qualityCheckRequired ? "Enforced QA Check" : "Standard"}  •  ${s.description}', style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: FactoryColors.statusOffline),
                  onPressed: () => notifier.removeProcessStage(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddStageDialog(BuildContext context, WidgetRef ref, int nextSeq) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final cycleCtrl = TextEditingController(text: '60');
    bool qaRequired = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Process Stage $nextSeq'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Stage Name *', hintText: 'e.g. 5-Axis Precision Contouring')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', hintText: 'Operations performed at this station')),
                const SizedBox(height: 10),
                TextField(controller: cycleCtrl, decoration: const InputDecoration(labelText: 'Target Cycle Time (seconds)', hintText: '60')),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enforce Quality Gate Inspection', style: TextStyle(fontSize: 13)),
                  value: qaRequired,
                  onChanged: (val) => setState(() => qaRequired = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(onboardingControllerProvider.notifier).addProcessStage(
                      ProcessStageModel(
                        name: nameCtrl.text.trim(),
                        sequence: nextSeq,
                        description: descCtrl.text.trim(),
                        cycleTimeSeconds: int.tryParse(cycleCtrl.text) ?? 60,
                        qualityCheckRequired: qaRequired,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// STEP 6: MACHINES & PRODUCTION LINES
// ==========================================
class _Step6LinesAndMachines extends ConsumerWidget {
  final OnboardingState state;
  const _Step6LinesAndMachines({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 6: Production Lines & Machines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Configure automated lines, cells, and specific equipment units.', style: TextStyle(fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Production Line'),
              onPressed: () => _showAddLineDialog(context, ref, state.productionLines.length + 1),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.productionLines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No production lines defined. Click "Add Production Line" to begin.', style: TextStyle(fontStyle: FontStyle.italic))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.productionLines.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, lineIdx) {
              final line = state.productionLines[lineIdx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(FactoryRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.precision_manufacturing, size: 20, color: FactoryColors.primaryBlue),
                            const SizedBox(width: 8),
                            Text(line.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('[${line.code}]', style: const TextStyle(fontSize: 12)),
                            if (line.department.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FactoryColors.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: FactoryColors.primaryBlue.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  line.department,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FactoryColors.primaryBlue),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add Machine', style: TextStyle(fontSize: 11)),
                              onPressed: () => _showAddMachineDialog(context, ref, lineIdx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: FactoryColors.statusOffline),
                              onPressed: () => notifier.removeProductionLine(lineIdx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Department: ${line.department}  •  Target Output: ${line.targetHourlyUnits} units/hr  •  Crew: ${line.operatorCount} operators', style: const TextStyle(fontSize: 12)),
                    if (line.machines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...line.machines.map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.settings_suggest_outlined, size: 14, color: FactoryColors.primaryBlue),
                                const SizedBox(width: 6),
                                Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 6),
                                Text('(${m.code}  •  ${m.machineType}  •  ${m.ratedPowerKw} kW)', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddLineDialog(BuildContext context, WidgetRef ref, int nextIdx) {
    final nameCtrl = TextEditingController(text: 'Automated Line $nextIdx');
    final codeCtrl = TextEditingController(text: 'LINE-$nextIdx');
    final deptCtrl = TextEditingController(text: 'Production Area $nextIdx');
    final rateCtrl = TextEditingController(text: '150');
    final opsCtrl = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Production Line / Cell'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Line Name *')),
              const SizedBox(height: 10),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Line Code *')),
              const SizedBox(height: 10),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department / Production Area',
                  hintText: 'e.g. Machining Hall A / Cleanroom Cell 2',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Target Rate/hr'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: opsCtrl, decoration: const InputDecoration(labelText: 'Crew Size'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ref.read(onboardingControllerProvider.notifier).addProductionLine(
                    ProductionLineItem(
                      id: '',
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim(),
                      department: deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : 'General Production',
                      status: 'RUNNING',
                      statusDisplay: 'Running',
                      currentProduct: '',
                      efficiencyRate: 92.0,
                      targetHourlyUnits: int.tryParse(rateCtrl.text) ?? 150,
                      actualHourlyUnits: int.tryParse(rateCtrl.text) ?? 140,
                      operatorCount: int.tryParse(opsCtrl.text) ?? 2,
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Line'),
          ),
        ],
      ),
    );
  }

  void _showAddMachineDialog(BuildContext context, WidgetRef ref, int lineIdx) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'CNC Milling Center');
    final powerCtrl = TextEditingController(text: '25.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Machine to Line'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Machine Name *', hintText: 'e.g. 5-Axis High Torque Mill')),
              const SizedBox(height: 10),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Machine Code', hintText: 'e.g. M-CNC-01')),
              const SizedBox(height: 10),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Machine Type', hintText: 'Mill, Lathe, Sorter, Welder')),
              const SizedBox(height: 10),
              TextField(controller: powerCtrl, decoration: const InputDecoration(labelText: 'Rated Power (kW)', hintText: '25.0')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ref.read(onboardingControllerProvider.notifier).addMachineToLine(
                    lineIdx,
                    MachineModel(
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'M-${nameCtrl.text.trim().hashCode.abs().toString().substring(0, 3)}',
                      machineType: typeCtrl.text.trim(),
                      ratedPowerKw: double.tryParse(powerCtrl.text) ?? 15.0,
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Machine'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// STEP 7: SHIFTS & CAPACITY
// ==========================================
class _Step7Shifts extends ConsumerWidget {
  final OnboardingState state;
  const _Step7Shifts({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 7: Operating Shifts & Production Capacity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Establish work shifts, schedule windows, and aggregate output targets.', style: TextStyle(fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Shift'),
              onPressed: () => _showAddShiftDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (state.shifts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No shifts configured.', style: TextStyle(fontStyle: FontStyle.italic))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.shifts.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = state.shifts[index];
              return ListTile(
                tileColor: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FactoryRadius.sm)),
                leading: const Icon(Icons.schedule, color: FactoryColors.primaryBlue),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Hours: ${s.startTime} - ${s.endTime}  •  Days: ${s.operatingDays.join(", ")}  •  Target: ${s.plannedCapacityUnits} units', style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: FactoryColors.statusOffline),
                  onPressed: () => notifier.removeShift(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddShiftDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: 'Day Shift');
    final startCtrl = TextEditingController(text: '06:00');
    final endCtrl = TextEditingController(text: '14:00');
    final capCtrl = TextEditingController(text: '1500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Operating Shift'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shift Name *', hintText: 'Morning Shift A')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: '06:00'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: '14:00'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Target Capacity (units)', hintText: '1500')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ref.read(onboardingControllerProvider.notifier).addShift(
                    ShiftModel(
                      name: nameCtrl.text.trim(),
                      startTime: startCtrl.text.trim(),
                      endTime: endCtrl.text.trim(),
                      plannedCapacityUnits: int.tryParse(capCtrl.text) ?? 1000,
                    ),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Shift'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// STEP 8: REVIEW & ACTIVATE
// ==========================================
class _Step8Review extends StatelessWidget {
  final OnboardingState state;
  const _Step8Review({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    final totalMachines = state.productionLines.fold<int>(0, (acc, l) => acc + l.machines.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified, color: FactoryColors.statusRunning, size: 24),
            const SizedBox(width: 8),
            Text('Step 8: Review & Activate Production Plant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Verify your comprehensive manufacturing topology before activating the facility into live production.', style: TextStyle(fontSize: 13, color: textSecondary)),
        const SizedBox(height: 20),

        // Summary Grid
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard('Enterprise Company', state.companyName.isNotEmpty ? state.companyName : "Apex Holdings", Icons.business, isDark),
            _summaryCard('Factory Name', state.factoryName.isNotEmpty ? state.factoryName : "New Plant", Icons.factory, isDark),
            _summaryCard('Industry Domain', state.industryType, Icons.category, isDark),
            _summaryCard('Factory Type', state.factoryType.replaceAll('_', ' '), Icons.account_tree, isDark),
            _summaryCard('Operating Model', state.manufacturingModel.replaceAll('_', ' '), Icons.settings_applications, isDark),
            _summaryCard('Quality Standard', state.complianceStandard.isNotEmpty ? state.complianceStandard : 'ISO 9001 / Standard', Icons.verified_user, isDark),
            _summaryCard('Cleanroom / Hygiene', state.cleanroomGrade.isNotEmpty ? state.cleanroomGrade : 'Standard Controlled', Icons.cleaning_services, isDark),
            _summaryCard('Location', '${state.location}, ${state.country}', Icons.place, isDark),
            _summaryCard('Manufactured Products', '${state.products.length} Products Defined', Icons.inventory_2, isDark),
            _summaryCard('Raw Materials', '${state.rawMaterials.length} Base Materials', Icons.layers, isDark),
            _summaryCard('Process Stages', '${state.processStages.length} Sequence Steps', Icons.alt_route, isDark),
            _summaryCard('Lines & Machines', '${state.productionLines.length} Lines ($totalMachines Machines)', Icons.precision_manufacturing, isDark),
            _summaryCard('Operating Shifts', '${state.shifts.length} Configured Shifts', Icons.schedule, isDark),
            _summaryCard('Daily Target Capacity', '${state.targetDailyCapacity} units/day', Icons.speed, isDark),
            _summaryCard('Session Mode', state.draftId != null ? 'Draft #${state.draftId.toString().length > 8 ? state.draftId.toString().substring(0, 8) : state.draftId}' : 'New Facility Creation', Icons.save, isDark),
          ],
        ),
        const SizedBox(height: 24),

        // Activation Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FactoryColors.statusRunningBgLight,
            borderRadius: BorderRadius.circular(FactoryRadius.md),
            border: Border.all(color: FactoryColors.statusRunningBorderLight),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: FactoryColors.statusRunning, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transactional Atomicity Guaranteed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: FactoryColors.statusRunning)),
                    SizedBox(height: 2),
                    Text(
                      'Activating creates company records, physical factory entities, lines, machines, and initial telemetry snapshots in a single atomic transaction. The facility will be available immediately in the Command Center.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _summaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(FactoryRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FactoryColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
