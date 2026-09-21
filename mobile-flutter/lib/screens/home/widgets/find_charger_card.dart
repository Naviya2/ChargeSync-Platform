import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../stations/stations_screen.dart';

class FindChargerCard extends StatefulWidget {
  const FindChargerCard({super.key});

  @override
  State<FindChargerCard> createState() => _FindChargerCardState();
}

class _FindChargerCardState extends State<FindChargerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingController;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StationsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      size: 24,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find a Charger',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer,
                          letterSpacing: -0.008,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pingController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (1.0 - _pingController.value).clamp(0.0, 1.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimaryContainer
                                        .withOpacity(1.0 - _pingController.value),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.onPrimaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '4 bays ready nearby • 1.2 mi',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryContainer.withOpacity(0.90),
                              letterSpacing: 0.06,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.onPrimaryContainer.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
