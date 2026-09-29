from fastapi import FastAPI, HTTPException
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

# Enable CORS for local testing and ASP.NET Core backend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from fastapi import Request, Depends
from llm_provider import get_gemini_provider

def get_vehicle_agent(request: Request):
    api_key = request.headers.get("x-gemini-api-key")
    model = request.headers.get("x-gemini-model")
    llm = get_gemini_provider(api_key, model) if api_key else None
    return VehicleCompatibilityAgent(llm)

def get_station_agent(request: Request):
    api_key = request.headers.get("x-gemini-api-key")
    model = request.headers.get("x-gemini-model")
    llm = get_gemini_provider(api_key, model) if api_key else None
    return StationAnalysisAgent(llm)

def get_planning_agent(request: Request):
    api_key = request.headers.get("x-gemini-api-key")
    model = request.headers.get("x-gemini-model")
    llm = get_gemini_provider(api_key, model) if api_key else None
    return PlanningCoordinatorAgent(llm)

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
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
        raise HTTPException(status_code=500, detail=f"Charging plan generation failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
