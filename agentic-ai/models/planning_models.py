import uuid
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from models.compatibility_models import VehicleInput, StationInput

class PlanningRequest(BaseModel):
    driver_id: Optional[str] = Field(None, description="Driver ID (null for walk-in)")
    deadline: datetime = Field(..., description="Target arrival time or deadline")
    max_distance_km: Optional[float] = Field(None, description="Max search radius in km")
    price_preference: Optional[str] = Field(None, description="Budget or speed priority (e.g., 'Budget', 'Speed')")
    vehicle_id: Optional[str] = Field(None, description="Vehicle ID")
    current_lat: Optional[float] = Field(None, description="Current latitude of the user")
    current_lon: Optional[float] = Field(None, description="Current longitude of the user")
    vehicle: Optional[VehicleInput] = Field(None, description="Vehicle data")
    candidate_stations: Optional[List[StationInput]] = Field(None, description="Candidate stations")

class ItineraryStep(BaseModel):
    station_id: str = Field(..., description="Target station ID")
    station_name: str = Field(..., description="Target station Name")
    charger_id: str = Field(..., description="Target charger ID")
    estimated_arrival_time: datetime = Field(..., description="Expected arrival time")
    estimated_charge_duration_mins: int = Field(..., description="Time to charge")
    waitlist_override_required: bool = Field(False, description="If this implies jumping waitlist")
    cost_estimate: float = Field(0.0, description="Estimated cost for charging")
    match_score: int = Field(0, description="Score out of 100")
    maintenance_buffer_conflict: bool = Field(False, description="True if charge finishes near maintenance/closing")
    conflict_reason: Optional[str] = Field(None, description="Reason for the buffer conflict")

class PlanningResponse(BaseModel):
    plan_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Unique generated plan ID")
    ranked_itineraries: List[ItineraryStep] = Field(..., description="List of options")
    requires_approval: bool = Field(False, description="If an itinerary requires waitlist override approval")
    agent_reasoning: str = Field(..., description="Explanation of the generated plan")
