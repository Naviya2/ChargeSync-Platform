import pytest
from fastapi.testclient import TestClient
from main import app
from models.compatibility_models import (
    VehicleInput,
    StationInput,
    ChargerInput,
    CompatibilityRequest,
    BatchCompatibilityRequest,
)
from agents.compatibility_agent import VehicleCompatibilityAgent

client = TestClient(app)

@pytest.fixture
def agent():
    return VehicleCompatibilityAgent()

@pytest.fixture
def tesla_model_3():
    return VehicleInput(
        vehicle_id="veh-tesla-3",
        make="Tesla",
        model="Model 3",
        connector="NACS",
        battery_capacity_kwh=75.0,
        max_charge_rate_kw=170.0,
        license_plate="CAB-4921",
    )

@pytest.fixture
def hyundai_ioniq_5():
    return VehicleInput(
        vehicle_id="veh-ioniq-5",
        make="Hyundai",
        model="Ioniq 5",
        connector="CCS2",
        battery_capacity_kwh=77.4,
        max_charge_rate_kw=233.0,
        license_plate="CAB-8821",
    )

@pytest.fixture
def downtown_station():
    return StationInput(
        station_id="st-downtown",
        name="Downtown Fast Hub",
        address="100 Main St",
        latitude=6.9271,
        longitude=79.8612,
        distance_km=2.5,
        chargers=[
            ChargerInput(charger_id="ch-1", identifier="BAY-01", connector="CCS2", power_kw=150.0),
            ChargerInput(charger_id="ch-2", identifier="BAY-02", connector="NACS", power_kw=250.0),
            ChargerInput(charger_id="ch-3", identifier="BAY-03", connector="Type2", power_kw=22.0),
        ],
    )

@pytest.fixture
def ccs2_only_station():
    return StationInput(
        station_id="st-ccs2-only",
        name="Metro Rapid Hub",
        address="45 Station Road",
        latitude=6.9300,
        longitude=79.8650,
        distance_km=3.0,
        chargers=[
            ChargerInput(charger_id="ch-4", identifier="BAY-A", connector="CCS2", power_kw=120.0),
        ],
    )

@pytest.fixture
def nacs_supercharger_station():
    return StationInput(
        station_id="st-supercharger",
        name="Tesla Supercharger Central",
        address="200 Express Way",
        latitude=6.9200,
        longitude=79.8500,
        distance_km=4.0,
        chargers=[
            ChargerInput(charger_id="ch-5", identifier="STALL-1", connector="NACS", power_kw=250.0),
        ],
    )

class TestVehicleCompatibilityAgent:
    def test_nacs_vehicle_matching_and_capping(self, agent, tesla_model_3, downtown_station):
        req = CompatibilityRequest(vehicle=tesla_model_3, target_station=downtown_station)
        res = agent.evaluate(req)

        assert res.is_compatible is True
        assert res.best_charger_id == "ch-2"
        # 170 kW vehicle on 250 kW charger caps at 170 kW
        assert res.effective_charging_power_kw == 170.0
        # 75 kWh * 0.70 / 170 kW * 60 = 18.5 mins
        assert res.estimated_charge_time_minutes == 18.5
        assert res.estimated_charge_time_formatted == "19 mins (10-80%)"
        assert res.compatibility_score >= 80

    def test_incompatible_connector_triggers_alternatives(
        self, agent, tesla_model_3, ccs2_only_station, nacs_supercharger_station
    ):
        req = CompatibilityRequest(
            vehicle=tesla_model_3,
            target_station=ccs2_only_station,
            candidate_alternative_stations=[nacs_supercharger_station],
        )
        res = agent.evaluate(req)

        assert res.is_compatible is False
        assert res.compatibility_score == 0
        assert len(res.suggested_alternatives) == 1
        alt = res.suggested_alternatives[0]
        assert alt.station_id == nacs_supercharger_station.station_id
        assert alt.compatibility_score > 0
        assert "NACS" in alt.reason

    def test_power_bottleneck_warning(self, agent, hyundai_ioniq_5):
        slow_station = StationInput(
            station_id="st-slow",
            name="City Slow Hub",
            latitude=6.9,
            longitude=79.8,
            distance_km=1.0,
            chargers=[
                ChargerInput(charger_id="ch-slow", identifier="BAY-1", connector="CCS2", power_kw=50.0),
            ],
        )
        req = CompatibilityRequest(vehicle=hyundai_ioniq_5, target_station=slow_station)
        res = agent.evaluate(req)

        assert res.is_compatible is True
        assert res.effective_charging_power_kw == 50.0
        # Check warning about bottleneck
        assert any("Power Bottleneck" in w for w in res.warnings)

    def test_batch_evaluation(self, agent, tesla_model_3, downtown_station, ccs2_only_station):
        req = BatchCompatibilityRequest(
            vehicle=tesla_model_3,
            stations=[ccs2_only_station, downtown_station],
        )
        res = agent.batch_evaluate(req)

        assert len(res.stations) == 2
        # Compatible station should rank first
        assert res.stations[0].station_id == downtown_station.station_id
        assert res.stations[0].is_compatible is True
        assert res.stations[1].station_id == ccs2_only_station.station_id
        assert res.stations[1].is_compatible is False

class TestFastApiEndpoints:
    def test_health_check(self):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "online"
        assert "Function 1" in data["function"]

    def test_evaluate_endpoint(self, tesla_model_3, downtown_station):
        payload = {
            "vehicle": tesla_model_3.model_dump(),
            "target_station": downtown_station.model_dump(),
            "candidate_alternative_stations": [],
        }
        response = client.post("/api/compatibility/evaluate", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["is_compatible"] is True
        assert data["effective_charging_power_kw"] == 170.0
        assert "19 mins" in data["estimated_charge_time_formatted"]
