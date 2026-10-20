import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/theme/factory_tokens.dart';
import '../../data/models/factory_model.dart';
import '../controllers/factory_controller.dart';


class FactorySelectorDropdown extends ConsumerStatefulWidget {
  const FactorySelectorDropdown({super.key});

  @override
  ConsumerState<FactorySelectorDropdown> createState() => _FactorySelectorDropdownState();
}

class _FactorySelectorDropdownState extends ConsumerState<FactorySelectorDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss backdrop
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
            ),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: Consumer(
                  builder: (context, ref, _) {
                    final factoryState = ref.watch(factoryControllerProvider);
                    final factories = factoryState.factories;
                    final selected = factoryState.selectedFactory;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? FactoryColors.darkSurface : FactoryColors.lightSurface,
                        borderRadius: BorderRadius.circular(FactoryRadius.md),
                        border: Border.all(
                          color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder,
                          width: 1,
                        ),
                        boxShadow: FactoryShadows.floating,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: FactorySpacing.md,
                              vertical: FactorySpacing.sm,
                            ),
                            color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF8FAFC),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SELECT OPERATIONAL FACTORY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? FactoryColors.darkTextMuted : FactoryColors.lightTextMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${factories.length} ONLINE',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: FactoryColors.statusRunning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: factories.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder,
                              ),
                              itemBuilder: (context, index) {
                                final factory = factories[index];
                                final isSelected = selected?.id == factory.id;
                                return _DropdownItemTile(
                                  factory: factory,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  onTap: () {
                                    ref.read(factoryControllerProvider.notifier).selectFactory(factory);
                                    _closeDropdown();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final factoryState = ref.watch(factoryControllerProvider);
    final selectedFactory = factoryState.selectedFactory;
    final isLoading = factoryState.isLoading;

    final bgColor = isDark ? FactoryColors.darkSurfaceSubtle : FactoryColors.lightSurfaceSubtle;
    final borderColor = isDark ? FactoryColors.darkBorder : FactoryColors.lightBorder;
    final textPrimary = isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary;
    final textSecondary = isDark ? FactoryColors.darkTextSecondary : FactoryColors.lightTextSecondary;

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(FactoryRadius.sm),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(FactoryRadius.sm),
            border: Border.all(
              color: _isOpen ? FactoryColors.primaryBlue : borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: FactoryColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.factory_outlined,
                  size: 14,
                  color: FactoryColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              if (selectedFactory != null) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFactory.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${selectedFactory.code} • ${selectedFactory.industryTypeDisplay}',
                      style: TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  isLoading ? 'Loading factories...' : 'Select Factory',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: AppAnimations.fast,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownItemTile extends StatefulWidget {
  final FactoryItem factory;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DropdownItemTile({
    required this.factory,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DropdownItemTile> createState() => _DropdownItemTileState();
}

class _DropdownItemTileState extends State<_DropdownItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.factory;
    final hoverBg = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final activeBg = widget.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : FactoryColors.primaryBlueTint;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: widget.isSelected ? activeBg : (_isHovered ? hoverBg : Colors.transparent),
          padding: const EdgeInsets.symmetric(
            horizontal: FactorySpacing.md,
            vertical: FactorySpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          f.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: widget.isSelected
                                ? FactoryColors.primaryBlue
                                : (widget.isDark ? FactoryColors.darkTextPrimary : FactoryColors.lightTextPrimary),
                          ),
                        ),
                        if (widget.isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: FactoryColors.primaryBlue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f.code} • ${f.industryTypeDisplay} • ${f.location}',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isDark ? FactoryColors.darkTextMuted : FactoryColors.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: FactoryColors.statusRunning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${f.activeLines}/${f.totalProductionLines} Lines',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FactoryColors.statusRunning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
