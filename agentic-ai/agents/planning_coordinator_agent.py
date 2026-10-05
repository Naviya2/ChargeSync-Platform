import uuid
from typing import List
from datetime import datetime, timedelta, timezone
from models.planning_models import PlanningRequest, PlanningResponse, ItineraryStep
from models.compatibility_models import VehicleInput, StationInput, ChargerInput
from models.station_analysis_models import StationAnalysisRequest, StationDataInput, PricingHistory, ChargerStatus, TimeWindow
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
        busy_chargers = len([c for c in station.chargers if (c.status or "UNKNOWN").upper() not in ["AVAILABLE", "UNKNOWN"]])
        total_chargers = len(station.chargers)
        real_utilization = (busy_chargers / total_chargers * 100.0) if total_chargers > 0 else 0.0
        
        return StationAnalysisRequest(
            station_id=station.station_id,
            time_window=TimeWindow(start_time=datetime.utcnow(), end_time=datetime.utcnow() + timedelta(hours=1)),
            station_data=StationDataInput(
                station_id=station.station_id,
                historical_utilization_percent=real_utilization,
                live_chargers=[ChargerStatus(charger_id=c.charger_id, status=c.status or "UNKNOWN") for c in station.chargers],
                pricing=PricingHistory(
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
        sri_lanka_tz = timezone(timedelta(hours=5, minutes=30))
        deadline = request.deadline
        if deadline.tzinfo:
            deadline = deadline.astimezone(sri_lanka_tz)
        else:
            deadline = deadline.replace(tzinfo=timezone.utc).astimezone(sri_lanka_tz)
            
        now = datetime.now(sri_lanka_tz)
        is_urgent = (deadline - now) < timedelta(minutes=60)
        
        # 1. Fetch Candidate Data from request
        vehicle = request.vehicle
        candidate_stations = request.candidate_stations or []
        
        reason = ""
        
        if not vehicle:
            reason = "No registered vehicle found for your account. Please add an EV to your profile."
        elif not candidate_stations:
            reason = "No available charging stations found within your selected search radius."
            
        if not vehicle or not candidate_stations:
            return PlanningResponse(
                plan_id=str(uuid.uuid4()),
                ranked_itineraries=[],
                requires_approval=False,
                agent_reasoning=reason
            )
        
        # 2. Orchestration: Filter by Compatibility
        compatible_stations = []
        for st in candidate_stations:
            is_comp, score, best_id, best_power, best_mins, best_fmt, evaluated, warnings = self.compatibility_agent.evaluate_station(vehicle, st)
            if is_comp:
                st_dict = st.dict()
                if st_dict.get("maintenance_window_start"):
                    try:
                        maint_raw = st_dict["maintenance_window_start"]
                        maint_dt = datetime.fromisoformat(maint_raw.replace('Z', '+00:00'))
                        # Always convert to Sri Lanka local time (UTC+05:30)
                        if maint_dt.tzinfo is None:
                            maint_dt = maint_dt.replace(tzinfo=timezone.utc)
                        maint_dt = maint_dt.astimezone(sri_lanka_tz)
                        st_dict["maintenance_window_start"] = maint_dt.strftime("%Y-%m-%d %I:%M %p")
                    except Exception as e:
                        print(f"maintenance_window_start conversion error: {e}")
                st_dict['best_power'] = best_power
                # Compute deterministic charge duration from vehicle+charger specs (same formula as post-processing override)
                # This is what the LLM should use in its reasoning text
                if best_power and best_power > 0:
                    actual_rate = min(best_power, vehicle.max_charge_rate_kw)
                    deterministic_mins = round((vehicle.battery_capacity_kwh / actual_rate) * 60)
                    st_dict['estimated_charge_duration_mins'] = deterministic_mins
                else:
                    st_dict['estimated_charge_duration_mins'] = best_mins
                st_dict['estimated_mins'] = st_dict['estimated_charge_duration_mins']
                compatible_stations.append(st_dict)
                
        # 3. Orchestration: Filter by Station Analysis (Congestion)
        viable_stations = []
        for st in compatible_stations:
            analysis_req = self._get_station_analysis_data(StationInput(**st))
            analysis_res = self.station_agent.analyze(analysis_req)
            
            # Filter out completely congested stations if urgent
            if analysis_res.availability_score < 20.0 and is_urgent:
                continue
                
            st['availability_score'] = analysis_res.availability_score
            st['price_competitiveness'] = analysis_res.price_competitiveness
            viable_stations.append(st)
            
        viable_stations_context = str(viable_stations) if viable_stations else "No compatible/available stations found. Suggest an alternative date/time."
        
        system_prompt = f"""
        You are an intelligent EV Charging Route Planner Agent for the ChargeSync Platform in Sri Lanka.
        You need to generate 2 ranked charging itineraries for a driver based on their preferences.
        
        Current Time: {now.strftime('%Y-%m-%d %I:%M %p')}
        Driver Deadline: {deadline.strftime('%Y-%m-%d %I:%M %p')}
        Price Preference: {request.price_preference}
        Max Distance: {request.max_distance_km} km
        Is Urgent: {is_urgent}
        User Current Location: {request.current_lat}, {request.current_lon}
        
        AVAILABLE VETTED STATIONS (Filtered by Compatibility & Congestion Agents):
        {viable_stations_context}
        
        Constraints:
        - Only use the vetted stations provided above.
        - Prices must be realistic for Sri Lanka (LKR), usually between 1000 and 5000 LKR.
        - Use UUIDs for station_id and charger_id if not provided in the vetted list.
        - Return up to 2 distinct itineraries, each for a DIFFERENT station. Do not generate multiple itineraries for the same station. If only 1 station is available, return just 1 itinerary.
        - Do NOT schedule `estimated_arrival_time` such that the charging session overlaps with `maintenance_window_start` or falls outside of operating hours (after `closing_time`).
        - IMPORTANT: Use the `estimated_charge_duration_mins` field from the station data as the charge duration for each itinerary. Do NOT estimate or calculate your own charge duration. The value in `estimated_charge_duration_mins` is computed from real vehicle and charger specs and is authoritative.
        - The agent_reasoning should clearly explain why you picked these based on their Price Preference, Deadline, Distance (distance_km), and the pre-computed availability/compatibility scores. When mentioning charge time, use the `estimated_charge_duration_mins` value from the station data.
        - Rank the closest stations higher if Price Preference is not heavily skewed towards 'Budget', otherwise balance distance and cost.
        """
        
        try:
            response = self.llm.invoke(system_prompt)
            # Ensure plan_id is populated safely and normalize to PlanningResponse
            plan = None
            if isinstance(response, dict):
                if not response.get("plan_id"):
                    response["plan_id"] = str(uuid.uuid4())
                plan = PlanningResponse(**response)
            else:
                if not getattr(response, "plan_id", None):
                    setattr(response, "plan_id", str(uuid.uuid4()))
                
                if isinstance(response, PlanningResponse):
                    plan = response
                elif hasattr(response, "model_dump"):
                    plan = PlanningResponse(**response.model_dump())
                elif hasattr(response, "dict"):
                    plan = PlanningResponse(**response.dict())
                else:
                    from typing import cast
                    plan = cast(PlanningResponse, response)
            
            BUFFER_THRESHOLD_MINUTES = 15
            for itinerary in getattr(plan, "ranked_itineraries", []):
                station = next((s for s in candidate_stations if s.station_id == itinerary.station_id), None)
                if station:
                    # Fix cost estimate deterministically instead of trusting LLM
                    charger = next((c for c in station.chargers if c.charger_id == itinerary.charger_id), None)
                    if charger:
                        actual_charge_rate_kw = min(charger.power_kw, vehicle.max_charge_rate_kw)
                        # Deterministically override LLM-generated charge duration to match frontend calculation
                        # Uses the same formula: battery_capacity_kwh / actual_charge_rate_kw * 60
                        actual_duration_mins = round((vehicle.battery_capacity_kwh / actual_charge_rate_kw) * 60)
                        itinerary.estimated_charge_duration_mins = actual_duration_mins
                        energy_kwh = actual_charge_rate_kw * (actual_duration_mins / 60.0)
                        itinerary.cost_estimate = round(energy_kwh * charger.tariff, 2) if charger.tariff is not None else None
                        
                    # Use a fresh end_time for each check to avoid cross-check mutation
                    base_end_time = itinerary.estimated_arrival_time + timedelta(minutes=itinerary.estimated_charge_duration_mins)
                    conflict = False
                    reason = None
                    
                    if getattr(station, "maintenance_window_start", None):
                        try:
                            end_time = base_end_time
                            maint_start_raw = station.maintenance_window_start
                            # maintenance_window_start may already be a pre-formatted local string from the compatibility loop
                            try:
                                maint_start = datetime.fromisoformat(maint_start_raw.replace('Z', '+00:00'))
                                # Convert to Sri Lanka TZ for an apples-to-apples comparison
                                maint_start = maint_start.astimezone(sri_lanka_tz)
                            except ValueError:
                                # Already formatted as local string — parse it back
                                maint_start = datetime.strptime(maint_start_raw, "%Y-%m-%d %I:%M %p").replace(tzinfo=sri_lanka_tz)
                            if end_time.tzinfo is None:
                                end_time = end_time.replace(tzinfo=sri_lanka_tz)
                            time_diff = (maint_start - end_time).total_seconds() / 60
                            if time_diff <= BUFFER_THRESHOLD_MINUTES:
                                conflict = True
                                reason = f"Finishes within {BUFFER_THRESHOLD_MINUTES}m of maintenance window or after"
                        except Exception as e:
                            print(f"Maintenance window parsing error: {e}")
                            
                    if getattr(station, "closing_time", None) and not conflict:
                        try:
                            end_time = base_end_time
                            hour, minute = map(int, station.closing_time.split(':'))
                            # Anchor close_time to the arrival time's day in Sri Lanka local time
                            arrival = itinerary.estimated_arrival_time
                            if arrival.tzinfo is None:
                                arrival = arrival.replace(tzinfo=sri_lanka_tz)
                            else:
                                arrival = arrival.astimezone(sri_lanka_tz)
                            close_time = arrival.replace(hour=hour, minute=minute, second=0, microsecond=0)
                            
                            # If closing time is earlier than arrival by more than 12 hours, it's likely next day (e.g. arrive 23:00, close 02:00)
                            if (arrival - close_time).total_seconds() > 12 * 3600:
                                close_time += timedelta(days=1)
                            
                            if end_time.tzinfo is None:
                                end_time = end_time.replace(tzinfo=sri_lanka_tz)
                            else:
                                end_time = end_time.astimezone(sri_lanka_tz)
                                
                            time_diff = (close_time - end_time).total_seconds() / 60
                            print(f"[DEBUG] Closing check — end_time: {end_time.strftime('%H:%M')}, close_time: {close_time.strftime('%H:%M')}, gap: {time_diff:.1f} mins")
                            # If time_diff is negative (finishes after close) OR within buffer, it's a conflict
                            if time_diff <= BUFFER_THRESHOLD_MINUTES:
                                conflict = True
                                reason = f"Finishes within {BUFFER_THRESHOLD_MINUTES}m of station closing time or after"
                        except Exception as e:
                            print(f"Closing time parsing error: {e}")
                    
                    if conflict:
                        itinerary.maintenance_buffer_conflict = True
                        itinerary.conflict_reason = reason
                        plan.requires_approval = True
            
            return plan
        except Exception as e:
            # Fallback in case the LLM fails to parse structured output
            print(f"LLM Error: {e}")
            traceback.print_exc()
            requires_approval = False
            itineraries: List[ItineraryStep] = []
            
            itineraries.append(ItineraryStep(
                station_id=str(uuid.uuid4()),
                station_name="Downtown FastHub (Fallback)",
                charger_id=str(uuid.uuid4()),
                estimated_arrival_time=now + timedelta(minutes=15),
                estimated_charge_duration_mins=30,
                waitlist_override_required=False,
                cost_estimate=3500.00,
                match_score=95 if request.price_preference != 'Budget' else 75
            ))
            
            return PlanningResponse(
                plan_id=str(uuid.uuid4()),
                ranked_itineraries=itineraries,
                requires_approval=requires_approval,
                agent_reasoning=f"Fallback plan due to LLM error. Evaluated based on deadline ({request.deadline})."
            )
