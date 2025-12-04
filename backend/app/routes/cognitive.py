from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models.database import get_db, User, Baseline
from app.models.schemas import CognitiveTestRequest, CognitiveTestResponse
from app.services.cognitive_analyzer import CognitiveAnalyzer

router = APIRouter()
cognitive_analyzer = CognitiveAnalyzer()

@router.post("/analyze", response_model=CognitiveTestResponse)
async def analyze_cognitive_tests(
    request: CognitiveTestRequest,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Analyze cognitive test results (reaction time + working memory)

    If user has a baseline, also calculate drift score
    """
    # Extract metrics from test data
    metrics = cognitive_analyzer.analyze_cognitive_tests(
        reaction_trials=request.reaction_time.trials,
        reaction_accuracy=request.reaction_time.accuracy,
        memory_correct=request.working_memory.correct_responses,
        memory_total=request.working_memory.total_trials,
        memory_avg_time=request.working_memory.avg_response_time
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
            "reaction_time_avg": baseline.reaction_time_avg,
            "reaction_time_std": baseline.reaction_time_std,
            "memory_accuracy": baseline.memory_accuracy,
            "memory_response_time": baseline.memory_response_time
        }

        drift_score, comparison_text = cognitive_analyzer.calculate_drift_score(
            metrics, baseline_metrics
        )

    return CognitiveTestResponse(
        reaction_time_avg=metrics["reaction_time_avg"],
        reaction_time_std=metrics["reaction_time_std"],
        memory_accuracy=metrics["memory_accuracy"],
        memory_response_time=metrics["memory_response_time"],
        drift_score=drift_score,
        comparison_text=comparison_text
    )

@router.get("/reaction-time-config")
async def get_reaction_time_config():
    """
    Get configuration for reaction time test

    Returns parameters for the mobile app to use
    """
    return {
        "test_name": "Reaction Time Test",
        "description": "Tap the screen as quickly as possible when the target appears",
        "num_trials": 10,
        "min_delay_ms": 1000,
        "max_delay_ms": 3000,
        "target_duration_ms": 2000,
        "instructions": [
            "A target will appear on the screen at random intervals",
            "Tap the target as quickly as possible",
            "Complete 10 trials",
            "Try to be both fast and accurate"
        ]
    }

@router.get("/working-memory-config")
async def get_working_memory_config():
    """
    Get configuration for working memory (N-back) test

    Returns parameters for the mobile app to use
    """
    return {
        "test_name": "Working Memory Test",
        "description": "2-back test: Tap when the current item matches the item from 2 steps ago",
        "test_type": "2-back",
        "num_trials": 20,
        "stimulus_duration_ms": 500,
        "inter_stimulus_interval_ms": 2000,
        "stimuli": ["A", "B", "C", "D", "E", "F", "G", "H"],
        "instructions": [
            "You will see a sequence of letters",
            "Tap when the current letter matches the letter from 2 steps ago",
            "For example: A-B-A (tap on second A)",
            "Complete 20 trials"
        ],
        "example_sequence": [
            {"letter": "A", "should_respond": False},
            {"letter": "B", "should_respond": False},
            {"letter": "A", "should_respond": True},
            {"letter": "C", "should_respond": False},
            {"letter": "B", "should_respond": True}
        ]
    }
