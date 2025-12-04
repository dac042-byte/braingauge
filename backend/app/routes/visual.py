from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.database import get_db, User, Baseline
from app.models.schemas import VisualMotorRequest, VisualMotorResponse
from app.services.visual_motor_analyzer import VisualMotorAnalyzer

router = APIRouter()
visual_motor_analyzer = VisualMotorAnalyzer()

@router.post("/analyze", response_model=VisualMotorResponse)
async def analyze_visual_motor(
    request: VisualMotorRequest,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Analyze eye tracking and visual-motor coordination data

    If user has a baseline, also calculate drift score
    """
    # Extract metrics from eye tracking data
    metrics = visual_motor_analyzer.analyze_eye_tracking(
        blink_count=request.eye_tracking.blink_count,
        duration=request.eye_tracking.duration,
        tracking_points=request.eye_tracking.tracking_points,
        target_positions=request.eye_tracking.target_positions
    )

    # Get user's active baseline if exists
    baseline = db.query(Baseline).filter(
        Baseline.user_id == user_id,
        Baseline.is_active == True
    ).first()

    drift_score = None
    comparison_text = None

    if baseline:
        # Calculate drift score
        baseline_metrics = {
            "blink_frequency": baseline.blink_frequency,
            "smooth_pursuit_accuracy": baseline.smooth_pursuit_accuracy,
            "tracking_variance": baseline.tracking_variance
        }

        drift_score, comparison_text = visual_motor_analyzer.calculate_drift_score(
            metrics, baseline_metrics
        )

    return VisualMotorResponse(
        blink_frequency=metrics["blink_frequency"],
        smooth_pursuit_accuracy=metrics["smooth_pursuit_accuracy"],
        tracking_variance=metrics["tracking_variance"],
        drift_score=drift_score,
        comparison_text=comparison_text
    )

@router.get("/tracking-config")
async def get_tracking_config():
    """
    Get configuration for eye tracking test

    Returns parameters for the mobile app to use
    """
    return {
        "test_name": "Eye Tracking Test",
        "description": "Follow the moving dot with your eyes while keeping your head still",
        "duration_seconds": 15,
        "target_size": 20,  # pixels
        "movement_pattern": "smooth_pursuit",  # or "saccade"
        "pattern_details": {
            "type": "circular",
            "radius": 0.3,  # fraction of screen width
            "speed": "medium",  # slow, medium, fast
            "cycles": 3
        },
        "instructions": [
            "Hold your phone at arm's length",
            "Keep your head still",
            "Follow the moving dot with your eyes only",
            "Try to keep the dot in the center of your vision",
            "The test will last 15 seconds"
        ],
        "calibration_required": True,
        "camera_permission_required": True
    }

@router.get("/calibration-guide")
async def get_calibration_guide():
    """
    Get instructions for eye tracking calibration

    This helps ensure accurate eye tracking measurements
    """
    return {
        "calibration_steps": [
            {
                "step": 1,
                "title": "Position your device",
                "description": "Hold your phone at arm's length in portrait orientation",
                "image": "/assets/calibration_position.png"
            },
            {
                "step": 2,
                "title": "Find good lighting",
                "description": "Ensure your face is well-lit and avoid backlighting",
                "image": "/assets/calibration_lighting.png"
            },
            {
                "step": 3,
                "title": "Look at the dots",
                "description": "Look at each calibration point as it appears",
                "image": "/assets/calibration_points.png"
            }
        ],
        "calibration_points": [
            {"x": 0.5, "y": 0.3, "label": "center-top"},
            {"x": 0.5, "y": 0.5, "label": "center"},
            {"x": 0.5, "y": 0.7, "label": "center-bottom"},
            {"x": 0.3, "y": 0.5, "label": "left"},
            {"x": 0.7, "y": 0.5, "label": "right"}
        ]
    }
