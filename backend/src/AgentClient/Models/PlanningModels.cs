using System.Text.Json.Serialization;

namespace AgentClient.Models;

public record PlanningRequest(
    [property: JsonPropertyName("driver_id")] string? DriverId,
    [property: JsonPropertyName("deadline")] DateTime Deadline,
    [property: JsonPropertyName("max_distance_km")] double? MaxDistanceKm,
    [property: JsonPropertyName("price_preference")] string? PricePreference,
    [property: JsonPropertyName("vehicle_id")] string? VehicleId,
    [property: JsonPropertyName("current_lat")] double? CurrentLat,
    [property: JsonPropertyName("current_lon")] double? CurrentLon,
    [property: JsonPropertyName("vehicle")] AgentVehicleInput? Vehicle,
    [property: JsonPropertyName("candidate_stations")] List<AgentStationInput>? CandidateStations
);

public record ItineraryStep(
    [property: JsonPropertyName("station_id")] string StationId,
    [property: JsonPropertyName("station_name")] string StationName,
    [property: JsonPropertyName("charger_id")] string ChargerId,
    [property: JsonPropertyName("estimated_arrival_time")] DateTime EstimatedArrivalTime,
    [property: JsonPropertyName("estimated_charge_duration_mins")] int EstimatedChargeDurationMins,
    [property: JsonPropertyName("waitlist_override_required")] bool WaitlistOverrideRequired,
    [property: JsonPropertyName("cost_estimate")] decimal CostEstimate,
    [property: JsonPropertyName("match_score")] int MatchScore
);

public record PlanningResponse(
    [property: JsonPropertyName("plan_id")] string PlanId,
    [property: JsonPropertyName("ranked_itineraries")] List<ItineraryStep> RankedItineraries,
    [property: JsonPropertyName("requires_approval")] bool RequiresApproval,
    [property: JsonPropertyName("agent_reasoning")] string AgentReasoning
);
