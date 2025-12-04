from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth, speech, cognitive, visual, score
from app.models.database import init_db

app = FastAPI(
    title="NeuroLoad API",
    description="Backend API for NeuroLoad - AI-powered neurological performance tracking for combat athletes",
    version="1.0.0"
)

# CORS middleware for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
@app.on_event("startup")
async def startup_event():
    init_db()

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(speech.router, prefix="/api/speech", tags=["Speech Analysis"])
app.include_router(cognitive.router, prefix="/api/cognitive", tags=["Cognitive Tests"])
app.include_router(visual.router, prefix="/api/visual", tags=["Visual-Motor Tracking"])
app.include_router(score.router, prefix="/api/score", tags=["Neuro Load Score"])

@app.get("/")
async def root():
    return {
        "message": "NeuroLoad API",
        "status": "operational",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
