import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

const _actions = [
  _QuickAction(
    icon: Icons.ev_station_rounded,
    label: 'Find Hub',
    color: AppColors.primary,
  ),
  _QuickAction(
    icon: Icons.alt_route_rounded,
    label: 'Plan Route',
    color: AppColors.secondary,
  ),
  _QuickAction(
    icon: Icons.event_seat_rounded,
    label: 'Bookings',
    color: AppColors.tertiary,
  ),
];

class QuickActionsRow extends StatelessWidget {
  final VoidCallback? onFindHub;
  final VoidCallback? onPlanRoute;
  final VoidCallback? onBookings;

  const QuickActionsRow({
    super.key,
    this.onFindHub,
    this.onPlanRoute,
    this.onBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionItem(action: _actions[0], onTap: onFindHub),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionItem(action: _actions[1], onTap: onPlanRoute),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionItem(action: _actions[2], onTap: onBookings),
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({required this.action, this.onTap});
  final _QuickAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
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
                child: Icon(action.icon, size: 22, color: action.color),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: 0.06,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
