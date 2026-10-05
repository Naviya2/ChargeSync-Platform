class PlanningRequest {
  final DateTime deadline;
  final double? maxDistanceKm;
  final String? pricePreference;
  final double? currentLat;
  final double? currentLon;

  PlanningRequest({
    required this.deadline,
    this.maxDistanceKm,
    this.pricePreference,
    this.currentLat,
    this.currentLon,
  });

  Map<String, dynamic> toJson() {
    return {
      'deadline': deadline.toUtc().toIso8601String(),
      'max_distance_km': maxDistanceKm,
      'price_preference': pricePreference,
      if (currentLat != null) 'current_lat': currentLat,
      if (currentLon != null) 'current_lon': currentLon,
    };
  }
}

class ItineraryStep {
  final String stationId;
  final String stationName;
  final String chargerId;
  final DateTime estimatedArrivalTime;
  final int estimatedChargeDurationMins;
  final bool waitlistOverrideRequired;
  final double costEstimate;
  final int matchScore;
  final bool maintenanceBufferConflict;
  final String? conflictReason;

  ItineraryStep({
    required this.stationId,
    required this.stationName,
    required this.chargerId,
    required this.estimatedArrivalTime,
    required this.estimatedChargeDurationMins,
    required this.waitlistOverrideRequired,
    required this.costEstimate,
    required this.matchScore,
    this.maintenanceBufferConflict = false,
    this.conflictReason,
  });

  factory ItineraryStep.fromJson(Map<String, dynamic> json) {
    return ItineraryStep(
      stationId: json['station_id'] as String,
      stationName: json['station_name'] as String,
      chargerId: json['charger_id'] as String,
      estimatedArrivalTime: DateTime.parse(json['estimated_arrival_time'] as String).toLocal(),
      estimatedChargeDurationMins: json['estimated_charge_duration_mins'] as int,
      waitlistOverrideRequired: json['waitlist_override_required'] as bool,
      costEstimate: (json['cost_estimate'] as num).toDouble(),
      matchScore: json['match_score'] as int,
      maintenanceBufferConflict: json['maintenance_buffer_conflict'] as bool? ?? false,
      conflictReason: json['conflict_reason'] as String?,
    );
  }
}

class PlanningResponse {
  final String planId;
  final List<ItineraryStep> rankedItineraries;
  final bool requiresApproval;
  final String agentReasoning;

  PlanningResponse({
    required this.planId,
    required this.rankedItineraries,
    required this.requiresApproval,
    required this.agentReasoning,
  });

  factory PlanningResponse.fromJson(Map<String, dynamic> json) {
    var list = json['ranked_itineraries'] as List;
    List<ItineraryStep> itinerariesList = list.map((i) => ItineraryStep.fromJson(i)).toList();

    return PlanningResponse(
      planId: json['plan_id'] as String,
      rankedItineraries: itinerariesList,
      requiresApproval: json['requires_approval'] as bool,
      agentReasoning: json['agent_reasoning'] as String,
    );
  }
}
