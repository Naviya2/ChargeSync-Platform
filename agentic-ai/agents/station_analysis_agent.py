from typing import List
from models.station_analysis_models import (
    StationAnalysisRequest,
    StationAnalysisResponse,
    ChargerStatus
)

class StationAnalysisAgent:
    """
    Station Analysis Agent
    
    Evaluates live charger status, pricing history and utilization 
    to supply candidate station scores.
    """

    def __init__(self):
        pass

    def evaluate_availability(self, live_chargers: List[ChargerStatus], historical_utilization: float) -> float:
        """
        Calculates an availability score based on the current number of free chargers 
        and historical utilization trends.
        """
        if not live_chargers:
            return 0.0
            
        available_chargers = [c for c in live_chargers if c.status.upper() == "AVAILABLE"]
        
        # Base score on raw availability percentage
        availability_ratio = len(available_chargers) / len(live_chargers)
        base_score = availability_ratio * 100.0
        
        history_penalty = (historical_utilization / 100.0) * 10.0
        
        score = max(0.0, base_score - history_penalty)
        return round(score, 1)

    def evaluate_pricing(self, current_price: float, avg_price: float, comp_price: float = None) -> float:
        """
        Calculates price competitiveness. A score of 50 means price is average.
        Scores > 50 indicate cheaper/better pricing, < 50 indicate more expensive pricing.
        """
        if current_price <= 0:
            return 100.0  
            
        baseline = comp_price if comp_price is not None else avg_price
        if baseline <= 0:
            return 50.0 
            
        ratio = baseline / current_price
        score = 50.0 * ratio
        return min(100.0, round(score, 1))

    def generate_flags(self, availability_score: float, price_score: float, live_chargers: List[ChargerStatus]) -> List[str]:
        """
        Generates categorical flags for edge conditions based on calculated scores and raw data.
        """
        flags = []
        if availability_score < 20.0:
            flags.append("HIGH_DEMAND")
            
        if price_score < 30.0:
            flags.append("SURGE_PRICING")
        elif price_score > 80.0:
            flags.append("GREAT_VALUE")
            
        faulted = [c for c in live_chargers if c.status.upper() in ["FAULTED", "OFFLINE"]]
        if live_chargers and (len(faulted) / len(live_chargers)) >= 0.3:
            flags.append("PARTIAL_OUTAGE")
            
        return flags

    def generate_insight(self, availability_score: float, price_score: float, flags: List[str]) -> str:
        """
        Synthesizes the scores and flags into a human-readable insight.
        """
        insight_parts = []
        
        if availability_score > 75:
            insight_parts.append("High likelihood of finding an available charger.")
        elif availability_score > 40:
            insight_parts.append("Moderate availability, you may experience a short wait.")
        else:
            insight_parts.append("Station is currently very busy; expect wait times.")
            
        if "GREAT_VALUE" in flags:
            insight_parts.append("Pricing is currently highly competitive.")
        elif "SURGE_PRICING" in flags:
            insight_parts.append("Prices are higher than average right now.")
            
        if "PARTIAL_OUTAGE" in flags:
            insight_parts.append("Warning: Several chargers are currently offline or faulted.")
            
        return " ".join(insight_parts)

    def analyze(self, request: StationAnalysisRequest) -> StationAnalysisResponse:
        """
        Main entry point for the agent. Orchestrates the evaluation of a station.
        """
        avail_score = self.evaluate_availability(
            request.station_data.live_chargers,
            request.station_data.historical_utilization_percent
        )
        
        price_score = self.evaluate_pricing(
            request.station_data.pricing.current_price_per_kwh,
            request.station_data.pricing.average_price_per_kwh,
            request.station_data.pricing.competitor_average_price
        )
        
        flags = self.generate_flags(avail_score, price_score, request.station_data.live_chargers)
        insight = self.generate_insight(avail_score, price_score, flags)
        
        return StationAnalysisResponse(
            station_id=request.station_id,
            availability_score=avail_score,
            price_competitiveness=price_score,
            utilization_insight=insight,
            flags=flags
        )
