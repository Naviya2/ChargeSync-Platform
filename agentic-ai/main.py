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

vehicle_agent = VehicleCompatibilityAgent()
station_agent = StationAnalysisAgent()
planning_agent = PlanningCoordinatorAgent()

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "description": "Agentic AI Subsystem (Compatibility, Station Analysis, and Planning Coordinators)",
    }

@app.post("/api/compatibility/evaluate", response_model=CompatibilityResponse, tags=["Compatibility Agent"])
async def evaluate_compatibility(request: CompatibilityRequest):
    """
    Evaluates hardware compatibility between a vehicle and a target charging station.
    Calculates effective power, estimated 10%->80% charge duration, compatibility score (0-100),
    detects power bottlenecks, and returns alternative station suggestions if needed.
    """
    try:
        response = vehicle_agent.evaluate(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Compatibility evaluation failed: {str(e)}")

@app.post("/api/compatibility/batch-evaluate", response_model=BatchCompatibilityResponse, tags=["Compatibility Agent"])
async def batch_evaluate_compatibility(request: BatchCompatibilityRequest):
    """
    Evaluates a vehicle against a list of candidate stations, scoring and ranking each for smart map discovery.
    """
    try:
        response = vehicle_agent.batch_evaluate(request)
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

@app.post("/api/charging-plan/generate", response_model=PlanningResponse, tags=["Planning Agent"])
async def generate_charging_plan(request: PlanningRequest):
    """
    Synthesizes driver objectives, coordinates Compatibility and Station agents, and generates ranked itineraries.
    Must handle records with null DriverId without failing availability models.
    """
    try:
        response = planning_agent.generate_plan(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Charging plan generation failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
