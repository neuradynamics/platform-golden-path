import logging
import os
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# from app.auth.routers import router as auth_router
# from app.core.routers import router as core_router
from app.config.settings import settings

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(application: FastAPI):
    """Application lifespan manager - runs on startup and shutdown."""
    try:
        logger.info("Application starting up")
        
        # Initialize any startup services here
        
        logger.info("Application startup complete")
        yield
        # Cleanup code here (if needed)
        logger.info("Application shutting down")
    except Exception as e:
        logger.error("Startup error: %s", str(e), exc_info=True)
        yield


def create_application() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Backend API",
        description="Backend API for the application",
        version="0.1.0",
        lifespan=lifespan,
    )
    
    # Configure CORS
    origins = [
        settings.ALLOWED_ORIGIN_1,
    ]
    
    if settings.ALLOWED_ORIGIN_2:
        origins.append(settings.ALLOWED_ORIGIN_2)
    
    if settings.ALLOWED_ORIGIN_3:
        origins.append(settings.ALLOWED_ORIGIN_3)
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include routers
    # app.include_router(auth_router, prefix="/v1/auth", tags=["auth"])
    # app.include_router(core_router, prefix="/v1/core", tags=["core"])
    
    # Health check endpoint
    @app.get("/healthz", tags=["health"])
    async def health_check():
        return {"status": "healthy"}
    
    return app


app = create_application()

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)