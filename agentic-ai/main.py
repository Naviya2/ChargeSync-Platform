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
from agents.compatibility_agent import VehicleCompatibilityAgent
from agents.station_analysis_agent import StationAnalysisAgent

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Intelligent Agentic AI service for ChargeSync EV Platform (Function 1: Vehicle & AI Compatibility Discovery)",
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

agent = VehicleCompatibilityAgent()
station_agent = StationAnalysisAgent()

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "function": "Function 1: Vehicle & AI Compatibility Discovery",
    }

@app.post("/api/compatibility/evaluate", response_model=CompatibilityResponse, tags=["Compatibility Agent"])
async def evaluate_compatibility(request: CompatibilityRequest):
    """
    Evaluates hardware compatibility between a vehicle and a target charging station.
    Calculates effective power, estimated 10%->80% charge duration, compatibility score (0-100),
    detects power bottlenecks, and returns alternative station suggestions if needed.
    """
    try:
        response = agent.evaluate(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Compatibility evaluation failed: {str(e)}")

@app.post("/api/compatibility/batch-evaluate", response_model=BatchCompatibilityResponse, tags=["Compatibility Agent"])
async def batch_evaluate_compatibility(request: BatchCompatibilityRequest):
    """
    Evaluates a vehicle against a list of candidate stations, scoring and ranking each for smart map discovery.
    """
    try:
        response = agent.batch_evaluate(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch evaluation failed: {str(e)}")

@app.post("/api/station-analysis/evaluate", response_model=StationAnalysisResponse, tags=["Station Analysis Agent"])
async def analyze_station(request: StationAnalysisRequest):
    """
    Evaluates live charger status, pricing history, and utilization to supply candidate station scores.
    """
    try:
        response = station_agent.analyze(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Station analysis failed: {str(e)}")



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
