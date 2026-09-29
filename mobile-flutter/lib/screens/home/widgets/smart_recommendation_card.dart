import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/api/planning_api_client.dart';
import '../../../core/api/planning_models.dart';
import '../../../features/reservations/screens/ai_planning_screen.dart';

class SmartRecommendationCard extends StatefulWidget {
  const SmartRecommendationCard({super.key});

  @override
  State<SmartRecommendationCard> createState() => _SmartRecommendationCardState();
}

class _SmartRecommendationCardState extends State<SmartRecommendationCard> {
  Future<PlanningResponse>? _planFuture;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  void _fetchRecommendation() {
    final req = PlanningRequest(
      deadline: DateTime.now().add(const Duration(hours: 2)),
      maxDistanceKm: 15.0,
      pricePreference: 'Balanced',
    );
    _planFuture = PlanningApiClient.instance.generateChargingPlan(req);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanningResponse>(
      future: _planFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.rankedItineraries.isEmpty) {
          return const SizedBox.shrink(); // Hide if error or no data
        }

        final response = snapshot.data!;
        final topItinerary = response.rankedItineraries.first;
        final durationMins = topItinerary.estimatedChargeDurationMins;
        final estCost = topItinerary.costEstimate;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ambient glow
              Positioned(
                left: -48,
                bottom: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.tertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI Smart Recommendation',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tertiary,
                              letterSpacing: 0.02,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(
                            alpha: 0.20,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Score: ${topItinerary.matchScore}/100',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiary,
                            letterSpacing: 0.06,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topItinerary.stationName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Key metrics grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const _MetricItem(
                          label: 'Arrival',
                          value: 'Soon',
                          valueColor: AppColors.onSurface,
                        ),
                        const SizedBox(width: 8),
                        _MetricItem(
                          label: 'Duration',
                          value: '$durationMins mins',
                          valueColor: AppColors.onSurface,
                        ),
                        const SizedBox(width: 8),
                        _MetricItem(
                          label: 'Est. Cost',
                          value: 'LKR ${estCost.toStringAsFixed(2)}',
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    response.agentReasoning,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiPlanningScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Open AI Route Planner',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                                letterSpacing: 0.01,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.tertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
              letterSpacing: -0.005,
            ),
          ),
        ],
      ),
    );
  }
}
