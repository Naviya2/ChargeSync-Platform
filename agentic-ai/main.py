from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from models.compatibility_models import (
    CompatibilityRequest,
    CompatibilityResponse,
    BatchCompatibilityRequest,
    BatchCompatibilityResponse,
)
from agents.compatibility_agent import VehicleCompatibilityAgent

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Intelligent Agentic AI service for ChargeSync EV Platform (Function 1: Vehicle & AI Compatibility Discovery)",
)

# Enable CORS for local testing and ASP.NET Core backend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

agent = VehicleCompatibilityAgent()

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
