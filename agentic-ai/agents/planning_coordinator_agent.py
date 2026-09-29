import uuid
from typing import List
from datetime import datetime, timedelta
from models.planning_models import PlanningRequest, PlanningResponse, ItineraryStep
from models.compatibility_models import VehicleInput, StationInput, ChargerInput
from models.station_analysis_models import StationAnalysisRequest, StationData, PricingData, ChargerStatus
from langchain_core.prompts import PromptTemplate
from config import settings
import traceback

from agents.compatibility_agent import VehicleCompatibilityAgent
from agents.station_analysis_agent import StationAnalysisAgent

class PlanningCoordinatorAgent:
    def __init__(self, llm=None):
        if llm:
            self.llm = llm.with_structured_output(PlanningResponse)
        else:
            # Fallback to standard ollama if no provider passed
            from langchain_ollama import ChatOllama
            self.llm = ChatOllama(
                base_url=settings.OLLAMA_BASE_URL,
                model=settings.OLLAMA_MODEL,
                temperature=0.2,
            ).with_structured_output(PlanningResponse)
            
        # Instantiate sub-agents for orchestration
        self.compatibility_agent = VehicleCompatibilityAgent()
        self.station_agent = StationAnalysisAgent()

    def _get_station_analysis_data(self, station: StationInput) -> StationAnalysisRequest:
        """Converts real station data to analysis request format"""
        # Calculate average tariff
        avg_tariff = 100.0
        if station.chargers:
            tariffs = [c.tariff for c in station.chargers if c.tariff is not None]
            if tariffs:
                avg_tariff = sum(tariffs) / len(tariffs)
                
        # Calculate real utilization metric (placeholder based on current real status)
        busy_chargers = len([c for c in station.chargers if c.status.upper() not in ["AVAILABLE", "UNKNOWN"]])
        total_chargers = len(station.chargers)
        real_utilization = (busy_chargers / total_chargers * 100.0) if total_chargers > 0 else 0.0
        
        return StationAnalysisRequest(
            station_id=station.station_id,
            station_data=StationData(
                historical_utilization_percent=real_utilization,
                live_chargers=[ChargerStatus(charger_id=c.charger_id, status=c.status) for c in station.chargers],
                pricing=PricingData(
                    current_price_per_kwh=avg_tariff, 
                    average_price_per_kwh=100.0, 
                    competitor_average_price=110.0
                )
            )
        )

    def generate_plan(self, request: PlanningRequest) -> PlanningResponse:
        """
        Uses Langchain and an LLM to dynamically generate charging itineraries
        based on the user's constraints.
        """
        now = datetime.now(request.deadline.tzinfo) if request.deadline.tzinfo else datetime.now()
        is_urgent = (request.deadline - now) < timedelta(minutes=60)
        
        # 1. Fetch Candidate Data from request
        vehicle = request.vehicle
        candidate_stations = request.candidate_stations or []
        
        if not vehicle or not candidate_stations:
            return PlanningResponse(
                plan_id=str(uuid.uuid4()),
                ranked_itineraries=[],
                requires_approval=is_urgent,
                agent_reasoning="Missing vehicle or candidate stations data from backend."
            )
        
        # 2. Orchestration: Filter by Compatibility
        compatible_stations = []
        for st in candidate_stations:
            is_comp, score, best_id, best_power, best_mins, best_fmt, evaluated, warnings = self.compatibility_agent.evaluate_station(vehicle, st)
            if is_comp:
                st_dict = st.dict()
                st_dict['best_power'] = best_power
                st_dict['estimated_mins'] = best_mins
                compatible_stations.append(st_dict)
                
        # 3. Orchestration: Filter by Station Analysis (Congestion)
        viable_stations = []
        for st in compatible_stations:
            analysis_req = self._get_station_analysis_data(StationInput(**st))
            analysis_res = self.station_agent.analyze(analysis_req)
            
            # Filter out completely congested stations if not urgent
            if analysis_res.availability_score < 20.0 and not is_urgent:
                continue
                
            st['availability_score'] = analysis_res.availability_score
            st['price_competitiveness'] = analysis_res.price_competitiveness
            viable_stations.append(st)
            
        viable_stations_context = str(viable_stations) if viable_stations else "No compatible/available stations found. Suggest an alternative date/time."
        
        system_prompt = f"""
        You are an intelligent EV Charging Route Planner Agent for the ChargeSync Platform in Sri Lanka.
        You need to generate 2 ranked charging itineraries for a driver based on their preferences.
        
        Current Time: {now.isoformat()}
        Driver Deadline: {request.deadline.isoformat()}
        Price Preference: {request.price_preference}
        Max Distance: {request.max_distance_km} km
        Is Urgent: {is_urgent}
        
        AVAILABLE VETTED STATIONS (Filtered by Compatibility & Congestion Agents):
        {viable_stations_context}
        
        Constraints:
        - Only use the vetted stations provided above.
        - If 'Is Urgent' is True, you MUST set 'requires_approval' to True, because the driver needs to jump the waitlist.
        - Prices must be realistic for Sri Lanka (LKR), usually between 1000 and 5000 LKR.
        - Use UUIDs for station_id and charger_id if not provided in the vetted list.
        - Return 2 itineraries if possible.
        - The agent_reasoning should clearly explain why you picked these based on their Price Preference, Deadline, and the pre-computed availability/compatibility scores.
        """
        
        try:
            response = self.llm.invoke(system_prompt)
            # Ensure plan_id is populated
            if not response.plan_id:
                response.plan_id = str(uuid.uuid4())
            return response
        except Exception as e:
            # Fallback in case the LLM fails to parse structured output
            print(f"LLM Error: {e}")
            traceback.print_exc()
            requires_approval = is_urgent
            itineraries: List[ItineraryStep] = []
            
            itineraries.append(ItineraryStep(
                station_id=str(uuid.uuid4()),
                station_name="Downtown FastHub (Fallback)",
                charger_id=str(uuid.uuid4()),
                estimated_arrival_time=now + timedelta(minutes=15),
                estimated_charge_duration_mins=30,
                waitlist_override_required=requires_approval,
                cost_estimate=3500.00,
                match_score=95 if request.price_preference != 'Budget' else 75
            ))
            
            return PlanningResponse(
                plan_id=str(uuid.uuid4()),
                ranked_itineraries=itineraries,
                requires_approval=requires_approval,
                agent_reasoning=f"Fallback plan due to LLM error. Evaluated based on deadline ({request.deadline})."
            )
