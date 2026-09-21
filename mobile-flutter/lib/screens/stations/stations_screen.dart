import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/map_canvas.dart';
import 'widgets/station_bottom_sheet.dart';
import 'widgets/stations_app_bar.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  int _activeStationId = 1;
  final TextEditingController _searchController = TextEditingController();
  bool _showClear = false;

  // Active filter chips
  final Set<String> _activeFilters = {'compatible', 'available'};

  void _onStationSelected(int id) {
    setState(() => _activeStationId = id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // App Bar (fixed)
              SliverToBoxAdapter(
                child: StationsAppBar(
                  searchController: _searchController,
                  showClear: _showClear,
                  onSearchChanged: (val) {
                    setState(() => _showClear = val.isNotEmpty);
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() => _showClear = false);
                  },
                  activeFilters: _activeFilters,
                  onFilterToggle: (filter) {
                    setState(() {
                      if (_activeFilters.contains(filter)) {
                        _activeFilters.remove(filter);
                      } else {
                        _activeFilters.add(filter);
                      }
                    });
                  },
                ),
              ),

              // Map Canvas
              SliverToBoxAdapter(
                child: MapCanvas(
                  activeStationId: _activeStationId,
                  onStationSelected: _onStationSelected,
                ),
              ),

              // Bottom Sheet Panel
              SliverToBoxAdapter(
                child: StationBottomSheet(
                  activeStationId: _activeStationId,
                  onStationSelected: (id) {
                    setState(() => _activeStationId = id);
                  },
                ),
              ),

              // Bottom nav padding
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _BackButton(),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
