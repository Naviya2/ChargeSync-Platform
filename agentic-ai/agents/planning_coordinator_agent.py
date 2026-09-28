import uuid
from typing import List
from datetime import datetime, timedelta
from models.planning_models import PlanningRequest, PlanningResponse, ItineraryStep

class PlanningCoordinatorAgent:
    def __init__(self):
        # We could inject the other agents (Compatibility, Station) here if needed
        pass

    def generate_plan(self, request: PlanningRequest) -> PlanningResponse:
        """
        Synthesizes driver constraints and generates a ranked itinerary.
        In a full LangGraph implementation, this would orchestrate other agents.
        For now, we generate a robust simulated plan based on constraints.
        """
        # Determine if this is an urgent or emergency request that might need a waitlist override
        # e.g., if deadline is within 30 minutes
        now = datetime.now(request.deadline.tzinfo) if request.deadline.tzinfo else datetime.now()
        is_urgent = (request.deadline - now) < timedelta(minutes=60)
        
        # Simulate waitlist override logic
        # If it's very urgent, we flag it for approval
        requires_approval = is_urgent

        # Generate some mock itineraries
        itineraries: List[ItineraryStep] = []
        
        # Option 1: Nearest station (prioritizes distance)
        itineraries.append(ItineraryStep(
            station_id="11111111-1111-1111-1111-111111111111",
            station_name="Downtown FastHub",
            charger_id="c1111111-1111-1111-1111-111111111111",
            estimated_arrival_time=now + timedelta(minutes=15),
            estimated_charge_duration_mins=30,
            waitlist_override_required=requires_approval,
            cost_estimate=3500.00,
            match_score=95 if request.price_preference != 'Budget' else 75
        ))
        
        # Option 2: Cheaper but further (prioritizes budget)
        itineraries.append(ItineraryStep(
            station_id="22222222-2222-2222-2222-222222222222",
            station_name="Suburban Eco Charge",
            charger_id="c2222222-2222-2222-2222-222222222222",
            estimated_arrival_time=now + timedelta(minutes=45),
            estimated_charge_duration_mins=40,
            waitlist_override_required=False,
            cost_estimate=1800.00,
            match_score=90 if request.price_preference == 'Budget' else 60
        ))
        
        # Sort by match score
        itineraries.sort(key=lambda x: x.match_score, reverse=True)
        
        reasoning = (
            f"Evaluated options based on deadline ({request.deadline}), "
            f"max distance ({request.max_distance_km}km), and price preference ({request.price_preference}). "
        )
        if requires_approval:
            reasoning += "Due to the tight deadline, the top recommendation requires a waitlist override and needs Admin approval."

        return PlanningResponse(
            plan_id=str(uuid.uuid4()),
            ranked_itineraries=itineraries,
            requires_approval=requires_approval,
            agent_reasoning=reasoning
        )
