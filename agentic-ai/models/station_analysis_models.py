from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class RequestContext(BaseModel):
    user_preference: Optional[str] = Field(None, description="e.g., 'cheapest', 'fastest', 'most_reliable'")
    vehicle_battery_level_percent: Optional[float] = None

class TimeWindow(BaseModel):
    start_time: datetime
    end_time: datetime

class ChargerStatus(BaseModel):
    charger_id: str
    status: str = Field(..., description="e.g., AVAILABLE, CHARGING, FAULTED, OFFLINE")
    current_power_output_kw: Optional[float] = None

class PricingHistory(BaseModel):
    average_price_per_kwh: float
    current_price_per_kwh: float
    competitor_average_price: Optional[float] = None

class StationDataInput(BaseModel):
    station_id: str
    live_chargers: List[ChargerStatus]
    historical_utilization_percent: float = Field(..., description="Historical utilization for the requested time window (0-100)")
    pricing: PricingHistory

class StationAnalysisRequest(BaseModel):
    station_id: str = Field(..., description="The ID of the station to analyze")
    time_window: TimeWindow = Field(..., description="The time window to evaluate pricing and utilization for")
    request_context: RequestContext = Field(default_factory=RequestContext, description="Contextual parameters for the request")
    station_data: StationDataInput = Field(..., description="Live and historical data used for evaluation")

class StationAnalysisResponse(BaseModel):
    station_id: str
    availability_score: float = Field(..., ge=0.0, le=100.0, description="Score based on live charger status and utilization (0-100)")
    price_competitiveness: float = Field(..., description="Metric comparing pricing against historical/regional baseline. Higher is more competitive.")
    utilization_insight: str = Field(..., description="AI-generated insight regarding station utilization")
    flags: List[str] = Field(default_factory=list, description="Array of condition flags (e.g., HIGH_DEMAND, SURGE_PRICING)")
