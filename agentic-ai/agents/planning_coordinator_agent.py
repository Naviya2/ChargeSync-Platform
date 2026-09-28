import uuid
from typing import List
from datetime import datetime, timedelta
from models.planning_models import PlanningRequest, PlanningResponse, ItineraryStep
from langchain_ollama import ChatOllama
from langchain_core.prompts import PromptTemplate
from config import settings
import traceback

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

    def generate_plan(self, request: PlanningRequest) -> PlanningResponse:
        """
        Uses Langchain and an LLM to dynamically generate charging itineraries
        based on the user's constraints.
        """
        now = datetime.now(request.deadline.tzinfo) if request.deadline.tzinfo else datetime.now()
        is_urgent = (request.deadline - now) < timedelta(minutes=60)
        
        system_prompt = f"""
        You are an intelligent EV Charging Route Planner Agent for the ChargeSync Platform in Sri Lanka.
        You need to generate 2 ranked charging itineraries for a driver based on their preferences.
        
        Current Time: {now.isoformat()}
        Driver Deadline: {request.deadline.isoformat()}
        Price Preference: {request.price_preference}
        Max Distance: {request.max_distance_km} km
        Is Urgent: {is_urgent}
        
        Constraints:
        - If 'Is Urgent' is True, you MUST set 'requires_approval' to True, because the driver needs to jump the waitlist.
        - Prices must be realistic for Sri Lanka (LKR), usually between 1000 and 5000 LKR.
        - Use UUIDs for station_id and charger_id.
        - Return 2 itineraries.
        - The agent_reasoning should clearly explain why you picked these based on their Price Preference and Deadline.
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
