import pytest
from datetime import datetime, timedelta
from models.station_analysis_models import (
    StationAnalysisRequest,
    StationDataInput,
    ChargerStatus,
    PricingHistory,
    TimeWindow,
    RequestContext
)
from agents.station_analysis_agent import StationAnalysisAgent

@pytest.fixture
def agent():
    return StationAnalysisAgent()

def test_availability_scoring(agent):
    chargers = [
        ChargerStatus(charger_id="c1", status="AVAILABLE"),
        ChargerStatus(charger_id="c2", status="AVAILABLE"),
    ]
    score = agent.evaluate_availability(chargers, historical_utilization=0.0)
    assert score == 100.0
    
    chargers = [
        ChargerStatus(charger_id="c1", status="AVAILABLE"),
        ChargerStatus(charger_id="c2", status="CHARGING"),
    ]
    score = agent.evaluate_availability(chargers, historical_utilization=50.0)
    assert score == 45.0

    chargers = [
        ChargerStatus(charger_id="c1", status="CHARGING"),
        ChargerStatus(charger_id="c2", status="FAULTED"),
    ]
    score = agent.evaluate_availability(chargers, historical_utilization=80.0)
    assert score == 0.0

def test_pricing_scoring(agent):
    assert agent.evaluate_pricing(0.0, 0.45) == 100.0
    assert agent.evaluate_pricing(0.50, 0.50) == 50.0
    assert agent.evaluate_pricing(0.25, 0.50) == 100.0
    assert agent.evaluate_pricing(1.00, 0.50) == 25.0
    assert agent.evaluate_pricing(0.40, avg_price=0.50, comp_price=0.30) == 37.5

def test_flag_generation(agent):
    chargers = [
        ChargerStatus(charger_id="1", status="FAULTED"),
        ChargerStatus(charger_id="2", status="FAULTED"),
        ChargerStatus(charger_id="3", status="AVAILABLE")
    ]
    
    flags = agent.generate_flags(availability_score=15.0, price_score=20.0, live_chargers=chargers)
    assert "HIGH_DEMAND" in flags
    assert "SURGE_PRICING" in flags
    assert "PARTIAL_OUTAGE" in flags

    flags_good = agent.generate_flags(availability_score=90.0, price_score=85.0, live_chargers=[])
    assert "GREAT_VALUE" in flags_good
    assert "PARTIAL_OUTAGE" not in flags_good

def test_full_analysis_flow(agent):
    now = datetime.utcnow()
    request = StationAnalysisRequest(
        station_id="ST-123",
        time_window=TimeWindow(
            start_time=now,
            end_time=now + timedelta(hours=1)
        ),
        request_context=RequestContext(user_preference="cheapest"),
        station_data=StationDataInput(
            station_id="ST-123",
            live_chargers=[
                ChargerStatus(charger_id="bay-1", status="AVAILABLE"),
                ChargerStatus(charger_id="bay-2", status="CHARGING"),
                ChargerStatus(charger_id="bay-3", status="FAULTED"),
                ChargerStatus(charger_id="bay-4", status="AVAILABLE")
            ],
            historical_utilization_percent=60.0,
            pricing=PricingHistory(
                average_price_per_kwh=0.55,
                current_price_per_kwh=0.45,
                competitor_average_price=0.50
            )
        )
    )

    response = agent.analyze(request)
    
    assert response.station_id == "ST-123"
    assert response.availability_score == 44.0
    assert response.price_competitiveness == 55.6
    assert isinstance(response.utilization_insight, str)
    assert len(response.utilization_insight) > 0
    assert isinstance(response.flags, list)
    assert "HIGH_DEMAND" not in response.flags
    assert "SURGE_PRICING" not in response.flags
