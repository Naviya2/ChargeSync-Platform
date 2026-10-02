import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/station_api_client.dart';
import '../../core/api/station_models.dart';
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
  int _activeStationIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _showClear = false;

  final Set<String> _activeFilters = {'compatible', 'available'};

  // API state
  List<StationDto> _stations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = AuthService.instance;
      List<StationDto> stations;

      if (auth.isStaff) {
        // Station owner: fetch ONLY their own stations
        stations = await StationApiClient.instance.getMyStations();
      } else {
        // EV Driver / public: fetch all approved stations
        stations = await StationApiClient.instance.getAllStations();
      }

      setState(() {
        _stations = stations;
        _activeStationIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onStationSelected(int index) {
    setState(() => _activeStationIndex = index);
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
          if (_isLoading)
            _LoadingView()
          else if (_error != null)
            _ErrorView(error: _error!, onRetry: _loadStations)
          else if (_stations.isEmpty)
            _EmptyView()
          else
            CustomScrollView(
              slivers: [
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
                SliverToBoxAdapter(
                  child: MapCanvas(
                    stations: _stations,
                    activeStationIndex: _activeStationIndex,
                    onStationSelected: _onStationSelected,
                  ),
                ),
                SliverToBoxAdapter(
                  child: StationBottomSheet(
                    stations: _stations,
                    activeStationIndex: _activeStationIndex,
                    onStationSelected: _onStationSelected,
                  ),
                ),
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

// ─── Loading view ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading stations…',
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load stations',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty view ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ev_station_rounded,
              color: AppColors.onSurfaceVariant, size: 64),
          const SizedBox(height: 16),
          Text(
            'No stations found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your registered stations will appear here\nonce approved.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
