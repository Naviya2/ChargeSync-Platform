from datetime import datetime, timedelta, timezone
import uuid
import pytest
from models.planning_models import PlanningRequest, PlanningResponse, ItineraryStep
from models.compatibility_models import VehicleInput, StationInput, ChargerInput
from agents.planning_coordinator_agent import PlanningCoordinatorAgent

class FakeStructuredLLM:
    def __init__(self, result):
        self.result = result
    def invoke(self, messages):
        return self.result

class FakeLLM:
    def __init__(self, result):
        self.result = result
    def with_structured_output(self, schema):
        return FakeStructuredLLM(self.result)

def mock_vehicle():
    return VehicleInput(
        vehicle_id="vehicle-123",
        make="Tesla",
        model="Model 3",
        connector="CCS2",
        battery_capacity_kwh=50.0,
        max_charge_rate_kw=100.0
    )

def mock_station():
    return StationInput(
        station_id="station-123",
        name="Test Station",
        latitude=0.0,
        longitude=0.0,
        distance_km=5.0,
        chargers=[
            ChargerInput(
                charger_id="charger-1",
                identifier="Bay-01",
                power_kw=50.0,
                connector="CCS2",
                status="AVAILABLE",
                tariff=150.0
            )
        ]
    )

def mock_response(requires_approval=False, cost=1500.0, reasoning="tight deadline"):
    return PlanningResponse(
        plan_id=str(uuid.uuid4()),
        requires_approval=requires_approval,
        agent_reasoning=reasoning,
        ranked_itineraries=[
            ItineraryStep(
                station_id="station-123",
                station_name="Test Station",
                charger_id="charger-1",
                estimated_arrival_time=datetime.now(timezone.utc),
                estimated_charge_duration_mins=30,
                cost_estimate=cost,
                match_score=95
            )
        ]
    )


def test_generate_plan_requires_approval_when_urgent():
    agent = PlanningCoordinatorAgent(llm=FakeLLM(mock_response(requires_approval=True, reasoning="tight deadline")))
    urgent_deadline = datetime.now(timezone.utc) + timedelta(minutes=30)
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=urgent_deadline,
        max_distance_km=10.0,
        price_preference="Speed",
        vehicle_id="vehicle-123",
        vehicle=mock_vehicle(),
        candidate_stations=[mock_station()]
    )
    
    response = agent.generate_plan(request)
    
    assert response is not None
    assert response.requires_approval is True
    assert len(response.ranked_itineraries) > 0
    assert "tight deadline" in response.agent_reasoning

def test_generate_plan_does_not_require_approval_when_not_urgent():
    agent = PlanningCoordinatorAgent(llm=FakeLLM(mock_response(requires_approval=False)))
    relaxed_deadline = datetime.now(timezone.utc) + timedelta(hours=3)
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=relaxed_deadline,
        max_distance_km=10.0,
        price_preference="Budget",
        vehicle_id="vehicle-123",
        vehicle=mock_vehicle(),
        candidate_stations=[mock_station()]
    )
    
    response = agent.generate_plan(request)
    
    assert response is not None
    assert response.requires_approval is False
    assert len(response.ranked_itineraries) > 0

@pytest.mark.parametrize(
    "tariff,vehicle_max_kw,expected_minutes,expected_cost",
    [
        (150.0, 100.0, 60, 7500.0),
        (30.0, 100.0, 60, 1500.0),
        (150.0, 25.0, 120, 7500.0),
    ],
)
def test_generate_plan_recalculates_cost_from_vehicle_and_tariff(
    tariff, vehicle_max_kw, expected_minutes, expected_cost
):
    # Intentionally incorrect AI estimates must not override real charging data.
    agent = PlanningCoordinatorAgent(llm=FakeLLM(mock_response(cost=1000.0)))
    deadline = datetime.now(timezone.utc) + timedelta(hours=3)
    vehicle = mock_vehicle()
    vehicle.max_charge_rate_kw = vehicle_max_kw
    station = mock_station()
    station.chargers[0].tariff = tariff
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=deadline,
        max_distance_km=20.0,
        price_preference="Budget",
        vehicle_id="vehicle-123",
        vehicle=vehicle,
        candidate_stations=[station]
    )
    
    response = agent.generate_plan(request)
    assert len(response.ranked_itineraries) == 1
    top_itinerary = response.ranked_itineraries[0]
    assert top_itinerary.station_id == station.station_id
    assert top_itinerary.charger_id == station.chargers[0].charger_id
    assert top_itinerary.estimated_charge_duration_mins == expected_minutes
    assert top_itinerary.cost_estimate == pytest.approx(expected_cost)

def test_generate_plan_buffer_conflict_requires_approval():
    now = datetime.now(timezone.utc)
    resp = PlanningResponse(
        plan_id=str(uuid.uuid4()),
        requires_approval=False,
        agent_reasoning="Normal plan",
        ranked_itineraries=[
            ItineraryStep(
                station_id="station-123",
                station_name="Test Station",
                charger_id="charger-1",
                estimated_arrival_time=now,
                estimated_charge_duration_mins=30,
                cost_estimate=1500.0,
                match_score=95
            )
        ]
    )
    agent = PlanningCoordinatorAgent(llm=FakeLLM(resp))
    
    # Station has maintenance starting 40 mins from now (10 mins after charge finishes)
    maint_time = (now + timedelta(minutes=40)).isoformat()
    station = mock_station()
    station.maintenance_window_start = maint_time
    
    request = PlanningRequest(
        driver_id="driver-123",
        deadline=now + timedelta(hours=2),
        max_distance_km=20.0,
        price_preference="Speed",
        vehicle_id="vehicle-123",
        vehicle=mock_vehicle(),
        candidate_stations=[station]
    )
    
    plan = agent.generate_plan(request)
    assert plan.requires_approval is True
    assert plan.ranked_itineraries[0].maintenance_buffer_conflict is True
    assert plan.ranked_itineraries[0].conflict_reason is not None
    assert "Finishes within 15m of maintenance window" in plan.ranked_itineraries[0].conflict_reason

