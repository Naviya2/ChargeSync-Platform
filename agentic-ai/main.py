from fastapi import FastAPI, HTTPException, Header, Depends
from secrets import compare_digest
import logging
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from models.compatibility_models import (
    CompatibilityRequest,
    CompatibilityResponse,
    BatchCompatibilityRequest,
    BatchCompatibilityResponse,
)
from models.station_analysis_models import (
    StationAnalysisRequest,
    StationAnalysisResponse,
)
from models.planning_models import PlanningRequest, PlanningResponse

from agents.compatibility_agent import VehicleCompatibilityAgent
from agents.station_analysis_agent import StationAnalysisAgent
from agents.planning_coordinator_agent import PlanningCoordinatorAgent

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Intelligent Agentic AI service for ChargeSync EV Platform",
)
logger = logging.getLogger(__name__)

# Enable CORS for local testing and ASP.NET Core backend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi import Request, Depends
from llm_provider import get_groq_provider

def get_vehicle_agent(request: Request):
    api_key = request.headers.get("x-groq-api-key")
    model = request.headers.get("x-groq-model")
    llm = get_groq_provider(api_key, model) if api_key else None
    return VehicleCompatibilityAgent(llm)

def get_station_agent(request: Request):
    api_key = request.headers.get("x-groq-api-key")
    model = request.headers.get("x-groq-model")
    llm = get_groq_provider(api_key, model) if api_key else None
    return StationAnalysisAgent(llm)

def get_planning_agent(request: Request):
    api_key = request.headers.get("x-groq-api-key")
    model = request.headers.get("x-groq-model")
    llm = get_groq_provider(api_key, model) if api_key else None
    return PlanningCoordinatorAgent(llm)

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "function": "Function 1 — Vehicle & AI Compatibility Discovery",
        "description": "Agentic AI Subsystem (Compatibility, Station Analysis, and Planning Coordinators)",
    }

@app.post("/api/compatibility/evaluate", response_model=CompatibilityResponse, tags=["Compatibility Agent"])
async def evaluate_compatibility(request: CompatibilityRequest, agent: VehicleCompatibilityAgent = Depends(get_vehicle_agent)):
    try:
        response = agent.evaluate(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Compatibility evaluation failed: {str(e)}")

@app.post("/api/compatibility/batch-evaluate", response_model=BatchCompatibilityResponse, tags=["Compatibility Agent"])
async def batch_evaluate_compatibility(request: BatchCompatibilityRequest, agent: VehicleCompatibilityAgent = Depends(get_vehicle_agent)):
    try:
        response = agent.batch_evaluate(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch evaluation failed: {str(e)}")

@app.post("/api/station-analysis/evaluate", response_model=StationAnalysisResponse, tags=["Station Analysis Agent"])
async def analyze_station(request: StationAnalysisRequest, agent: StationAnalysisAgent = Depends(get_station_agent)):
    try:
        response = agent.analyze(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Station analysis failed: {str(e)}")

@app.post("/api/charging-plan/generate", response_model=PlanningResponse, tags=["Planning Agent"])
async def generate_charging_plan(request: PlanningRequest, agent: PlanningCoordinatorAgent = Depends(get_planning_agent)):
    try:
        response = agent.generate_plan(request)
        return response
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Charging plan generation failed: {str(e)}")

from agents.support_agent import SupportAgent
from models.support_models import SupportRequest, SupportSuggestion

support_agent = SupportAgent()

def require_backend_key(x_agent_service_key: str = Header(default="")):
    if not settings.AGENT_SERVICE_API_KEY:
        raise HTTPException(status_code=503, detail="Internal agent authentication is not configured.")
    if not compare_digest(x_agent_service_key, settings.AGENT_SERVICE_API_KEY):
        raise HTTPException(status_code=401, detail="Invalid agent service credentials.")

@app.post("/api/support/analyze", response_model=SupportSuggestion, tags=["Validation & Support Agent"], dependencies=[Depends(require_backend_key)])
def analyze_support(request: SupportRequest):
    try:
        return support_agent.analyze(request)
    except Exception as error:
        logger.error("Support analysis failed: %s, provider status: %s",
                     type(error).__name__, getattr(error, "status_code", "none"))
        raise HTTPException(status_code=503, detail="Support analysis is temporarily unavailable.")

from agents.coordinator_agent import CoordinatorAgent
from models.workflow_models import WorkflowRequest, WorkflowResponse

coordinator = CoordinatorAgent(support_agent)

@app.post("/api/workflows/support", response_model=WorkflowResponse, dependencies=[Depends(require_backend_key)], tags=["Validation & Support Agent"])
def run_support_workflow(request: WorkflowRequest):
    try:
        return coordinator.run(request)
    except Exception as error:
        logger.error("Support workflow failed: %s, provider status: %s",
                     type(error).__name__, getattr(error, "status_code", "none"))
        raise HTTPException(status_code=503, detail="Support workflow is temporarily unavailable.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
