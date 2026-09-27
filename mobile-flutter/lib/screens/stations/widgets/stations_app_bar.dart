import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class StationsAppBar extends StatefulWidget {
  final TextEditingController searchController;
  final bool showClear;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Set<String> activeFilters;
  final ValueChanged<String> onFilterToggle;

  const StationsAppBar({
    super.key,
    required this.searchController,
    required this.showClear,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.activeFilters,
    required this.onFilterToggle,
  });

  @override
  State<StationsAppBar> createState() => _StationsAppBarState();
}

class _StationsAppBarState extends State<StationsAppBar> {

  @override
  void dispose() {
    super.dispose();
  }

  static const _filters = [
    _FilterChipData('compatible', Icons.check_circle_rounded, 'Model Y Compatible'),
    _FilterChipData('available', Icons.electric_bolt_rounded, 'Available Now'),
    _FilterChipData('speed', Icons.speed_rounded, 'Fast (150kW+)'),
    _FilterChipData('dist', null, '< 3 mi'),
    _FilterChipData('nacs', null, 'NACS / CCS'),
    _FilterChipData('price', null, '< \$0.35/kWh'),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.surface.withValues(alpha: 0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 52), // space for status bar + back btn



          // Search row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded,
                            color: AppColors.outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
                            onChanged: widget.onSearchChanged,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search charging stations, routes…',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.outline,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (widget.showClear)
                          GestureDetector(
                            onTap: widget.onClearSearch,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.cancel_rounded,
                                  color: AppColors.outline, size: 18),
                            ),
                          ),
                        GestureDetector(
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.mic_rounded,
                                color: AppColors.outline, size: 20),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${widget.activeFilters.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter chips row
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final isActive = widget.activeFilters.contains(f.key);
                return GestureDetector(
                  onTap: () => widget.onFilterToggle(f.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryContainer.withValues(alpha: 0.2)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: isActive
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (f.icon != null) ...[
                          Icon(f.icon,
                              size: 14,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          f.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FilterChipData {
  final String key;
  final IconData? icon;
  final String label;
  const _FilterChipData(this.key, this.icon, this.label);
}
