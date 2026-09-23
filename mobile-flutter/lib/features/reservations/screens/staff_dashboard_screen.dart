import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import 'qr_scanner_screen.dart';
import 'walk_in_booking_screen.dart';
import 'kwh_override_screen.dart';
import '../../stations/screens/station_management_screen.dart';
import '../../../screens/auth/sign_in_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
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

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    // Navigate back to sign-in, clear stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Content ──────────────────────────────────────────────
          IndexedStack(
            index: _currentTab,
            children: const [
              _StaffHomeTab(),
              QrScannerScreen(),
              StationManagementScreen(),
              WalkInBookingScreen(),
              KwhOverrideScreen(),
            ],
          ),
          // ── App Bar ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: topPadding),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ChargeSync',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.005,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (_, __) => Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Staff Mode • ${user?.fullName ?? 'Staff'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurfaceVariant,
                                        letterSpacing: 0.06,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Logout button
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceContainer,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Bottom Nav ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.90),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
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
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isActive: _currentTab == 0,
                        onTap: () => setState(() => _currentTab = 0),
                      ),
                      _NavItem(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan QR',
                        isActive: _currentTab == 1,
                        onTap: () => setState(() => _currentTab = 1),
                      ),
                      _NavItem(
                        icon: Icons.ev_station_rounded,
                        label: 'Stations',
                        isActive: _currentTab == 2,
                        onTap: () => setState(() => _currentTab = 2),
                      ),
                      _NavItem(
                        icon: Icons.directions_walk_rounded,
                        label: 'Walk-In',
                        isActive: _currentTab == 3,
                        onTap: () => setState(() => _currentTab = 3),
                      ),
                      _NavItem(
                        icon: Icons.electric_meter_rounded,
                        label: 'kWh Override',
                        isActive: _currentTab == 4,
                        onTap: () => setState(() => _currentTab = 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Staff Home Tab ────────────────────────────────────────────────────────────
class _StaffHomeTab extends StatelessWidget {
  const _StaffHomeTab();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = AuthService.instance.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding + 80, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Welcome, ${user?.fullName ?? 'Staff'}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${user?.role ?? 'Staff'} • On-Site POS Mode',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick action cards
          _ActionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Check-in',
            subtitle: 'Scan a driver\'s reservation QR code to start their session.',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.directions_walk_rounded,
            title: 'Admit Walk-In',
            subtitle: 'Lock an available charger for an unregistered customer.',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Item (same pattern as Driver screen) ──────────────────────────────────
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
        width: 80,
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
