from datetime import datetime, timedelta, timezone
from models.planning_models import PlanningRequest
from agents.planning_coordinator_agent import PlanningCoordinatorAgent

def test_generate_plan_requires_approval_when_urgent():
    agent = PlanningCoordinatorAgent()
    urgent_deadline = datetime.now(timezone.utc) + timedelta(minutes=30)
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=urgent_deadline,
        max_distance_km=10.0,
        price_preference="Speed",
        vehicle_id="vehicle-123"
    )
    
    response = agent.generate_plan(request)
    
    assert response is not None
    assert response.requires_approval is True
    assert len(response.ranked_itineraries) > 0
    assert "tight deadline" in response.agent_reasoning

def test_generate_plan_does_not_require_approval_when_not_urgent():
    agent = PlanningCoordinatorAgent()
    relaxed_deadline = datetime.now(timezone.utc) + timedelta(hours=3)
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=relaxed_deadline,
        max_distance_km=10.0,
        price_preference="Budget",
        vehicle_id="vehicle-123"
    )
    
    response = agent.generate_plan(request)
    
    assert response is not None
    assert response.requires_approval is False
    assert len(response.ranked_itineraries) > 0

def test_generate_plan_budget_preference():
    agent = PlanningCoordinatorAgent()
    deadline = datetime.now(timezone.utc) + timedelta(hours=3)
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=deadline,
        max_distance_km=20.0,
        price_preference="Budget",
        vehicle_id="vehicle-123"
    )
    
    response = agent.generate_plan(request)
    # The budget option should be ranked higher
    top_itinerary = response.ranked_itineraries[0]
    assert top_itinerary.cost_estimate < 2000.0
