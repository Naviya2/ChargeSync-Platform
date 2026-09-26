import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/find_charger_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/smart_recommendation_card.dart';
import 'widgets/upcoming_reservation_card.dart';
import 'widgets/rewards_card.dart';
import '../../features/station_search/screens/station_map_screen.dart';
import '../auth/sign_in_screen.dart';
import '../../features/reservations/screens/reservation_list_screen.dart';
import '../../core/api/auth_service.dart';
import '../profile/profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ---------- Main scrollable content ----------
          _currentTab == 1
              ? Positioned.fill(child: const StationMapScreen())
              : _currentTab == 2
                  ? Positioned.fill(child: Padding(padding: EdgeInsets.only(top: topPadding + 72, bottom: 80), child: const ReservationListScreen()))
                  : _currentTab == 4
                      ? Positioned.fill(child: Padding(padding: EdgeInsets.only(top: topPadding + 72, bottom: 80), child: const ProfileScreen()))
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Top offset for app bar
                            SliverToBoxAdapter(
                              child: SizedBox(height: topPadding + 72),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _buildGreetingSection(),
                                  const SizedBox(height: 16),
                                  const VehicleCard(),
                                  const SizedBox(height: 16),
                                  const FindChargerCard(),
                                  const SizedBox(height: 16),
                                  QuickActionsRow(
                                    onFindHub: () => setState(() => _currentTab = 1),
                                    onBookings: () => setState(() => _currentTab = 2),
                                    onPlanRoute: () => setState(() => _currentTab = 1), // Usually plan route goes to map
                                  ),
                                  const SizedBox(height: 16),
                                  const SmartRecommendationCard(),
                                  const SizedBox(height: 16),
                                  const UpcomingReservationCard(),
                                  const SizedBox(height: 16),
                                  const RewardsCard(),
                                  const SizedBox(height: 32),
                                ]),
                              ),
                            ),
                            // Bottom offset for nav bar
                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ],
                        ),
          // ---------- Fixed App Bar ----------
          _buildAppBar(topPadding),
          // ---------- Fixed Bottom Nav ----------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  // ---- Greeting Section ----
  Widget _buildGreetingSection() {
    final user = AuthService.instance.currentUser;
    final name = user?.fullName.split(' ').first ?? 'Driver';

    return Text(
      'Good morning, $name',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.01,
      ),
    );
  }

  // ---- App Bar ----
  Widget _buildAppBar(double topPadding) {
    final user = AuthService.instance.currentUser;
    final name = user?.fullName.split(' ').first ?? 'Driver';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topPadding),
            // App logo + identity row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Logo placeholder (lightning bolt icon)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ChargeSync',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.005,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification bell
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, _) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() => _currentTab = 4);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              color: AppColors.primaryContainer,
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onPrimaryContainer,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Bottom Navigation Bar ----
  Widget _buildBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentTab == 0,
                onTap: () => setState(() => _currentTab = 0),
              ),
              _NavItem(
                icon: Icons.ev_station_rounded,
                label: 'Stations',
                isActive: _currentTab == 1,
                onTap: () => setState(() => _currentTab = 1),
              ),
              _NavItem(
                icon: Icons.confirmation_number_rounded,
                label: 'Reservations',
                isActive: _currentTab == 2,
                onTap: () => setState(() => _currentTab = 2),
              ),
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Rewards',
                isActive: _currentTab == 3,
                onTap: () => setState(() => _currentTab = 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentTab == 4,
                onTap: () {
                  setState(() => _currentTab = 4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.06,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
