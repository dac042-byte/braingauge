from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.models.database import get_db, User, Baseline, WeeklyAssessment
from app.models.schemas import (
    BaselineCreate, BaselineResponse,
    WeeklyAssessmentCreate, WeeklyAssessmentResponse,
    NeuroLoadScoreResponse, TrendResponse, TrendData
)
from app.services.speech_analyzer import SpeechAnalyzer
from app.services.cognitive_analyzer import CognitiveAnalyzer
from app.services.visual_motor_analyzer import VisualMotorAnalyzer
from app.services.scoring_engine import ScoringEngine

router = APIRouter()

speech_analyzer = SpeechAnalyzer()
cognitive_analyzer = CognitiveAnalyzer()
visual_motor_analyzer = VisualMotorAnalyzer()
scoring_engine = ScoringEngine()

@router.post("/baseline", response_model=BaselineResponse)
async def create_baseline(
    baseline_data: BaselineCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Create a new baseline for the user

    This deactivates any existing baselines and creates a new active one
    """
    # Deactivate existing baselines
    existing_baselines = db.query(Baseline).filter(
        Baseline.user_id == user_id,
        Baseline.is_active == True
    ).all()

    for baseline in existing_baselines:
        baseline.is_active = False

    # Create new baseline
    new_baseline = Baseline(
        user_id=user_id,
        is_active=True,
        # Speech metrics
        speech_wpm=baseline_data.speech.wpm,
        speech_filler_count=baseline_data.speech.filler_count,
        speech_avg_pause=baseline_data.speech.avg_pause,
        speech_rate=baseline_data.speech.speech_rate,
        # Cognitive metrics
        reaction_time_avg=cognitive_analyzer.analyze_cognitive_tests(
            baseline_data.cognitive.reaction_time.trials,
            baseline_data.cognitive.reaction_time.accuracy,
            baseline_data.cognitive.working_memory.correct_responses,
            baseline_data.cognitive.working_memory.total_trials,
            baseline_data.cognitive.working_memory.avg_response_time
        )["reaction_time_avg"],
        reaction_time_std=cognitive_analyzer.analyze_cognitive_tests(
            baseline_data.cognitive.reaction_time.trials,
            baseline_data.cognitive.reaction_time.accuracy,
            baseline_data.cognitive.working_memory.correct_responses,
            baseline_data.cognitive.working_memory.total_trials,
            baseline_data.cognitive.working_memory.avg_response_time
        )["reaction_time_std"],
        memory_accuracy=cognitive_analyzer.analyze_cognitive_tests(
            baseline_data.cognitive.reaction_time.trials,
            baseline_data.cognitive.reaction_time.accuracy,
            baseline_data.cognitive.working_memory.correct_responses,
            baseline_data.cognitive.working_memory.total_trials,
            baseline_data.cognitive.working_memory.avg_response_time
        )["memory_accuracy"],
        memory_response_time=cognitive_analyzer.analyze_cognitive_tests(
            baseline_data.cognitive.reaction_time.trials,
            baseline_data.cognitive.reaction_time.accuracy,
            baseline_data.cognitive.working_memory.correct_responses,
            baseline_data.cognitive.working_memory.total_trials,
            baseline_data.cognitive.working_memory.avg_response_time
        )["memory_response_time"],
        # Visual-motor metrics
        blink_frequency=visual_motor_analyzer.analyze_eye_tracking(
            baseline_data.visual_motor.eye_tracking.blink_count,
            baseline_data.visual_motor.eye_tracking.duration,
            baseline_data.visual_motor.eye_tracking.tracking_points,
            baseline_data.visual_motor.eye_tracking.target_positions
        )["blink_frequency"],
        smooth_pursuit_accuracy=visual_motor_analyzer.analyze_eye_tracking(
            baseline_data.visual_motor.eye_tracking.blink_count,
            baseline_data.visual_motor.eye_tracking.duration,
            baseline_data.visual_motor.eye_tracking.tracking_points,
            baseline_data.visual_motor.eye_tracking.target_positions
        )["smooth_pursuit_accuracy"],
        tracking_variance=visual_motor_analyzer.analyze_eye_tracking(
            baseline_data.visual_motor.eye_tracking.blink_count,
            baseline_data.visual_motor.eye_tracking.duration,
            baseline_data.visual_motor.eye_tracking.tracking_points,
            baseline_data.visual_motor.eye_tracking.target_positions
        )["tracking_variance"]
    )

    db.add(new_baseline)
    db.commit()
    db.refresh(new_baseline)

    return new_baseline

@router.get("/baseline", response_model=BaselineResponse)
async def get_active_baseline(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get user's active baseline"""
    baseline = db.query(Baseline).filter(
        Baseline.user_id == user_id,
        Baseline.is_active == True
    ).first()

    if not baseline:
        raise HTTPException(status_code=404, detail="No active baseline found")

    return baseline

@router.post("/weekly-assessment", response_model=WeeklyAssessmentResponse)
async def create_weekly_assessment(
    assessment_data: WeeklyAssessmentCreate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Create a new weekly assessment and calculate Neuro Load Score

    Requires an active baseline to compare against
    """
    # Get active baseline
    baseline = db.query(Baseline).filter(
        Baseline.user_id == user_id,
        Baseline.is_active == True
    ).first()

    if not baseline:
        raise HTTPException(
            status_code=400,
            detail="No active baseline found. Please create a baseline first."
        )

    # Calculate cognitive metrics
    cognitive_metrics = cognitive_analyzer.analyze_cognitive_tests(
        assessment_data.cognitive.reaction_time.trials,
        assessment_data.cognitive.reaction_time.accuracy,
        assessment_data.cognitive.working_memory.correct_responses,
        assessment_data.cognitive.working_memory.total_trials,
        assessment_data.cognitive.working_memory.avg_response_time
    )

    # Calculate visual-motor metrics
    visual_motor_metrics = visual_motor_analyzer.analyze_eye_tracking(
        assessment_data.visual_motor.eye_tracking.blink_count,
        assessment_data.visual_motor.eye_tracking.duration,
        assessment_data.visual_motor.eye_tracking.tracking_points,
        assessment_data.visual_motor.eye_tracking.target_positions
    )

    # Calculate drift scores
    speech_drift, _ = speech_analyzer.calculate_drift_score(
        {
            "wpm": assessment_data.speech.wpm,
            "filler_count": assessment_data.speech.filler_count,
            "avg_pause": assessment_data.speech.avg_pause,
            "speech_rate": assessment_data.speech.speech_rate
        },
        {
            "wpm": baseline.speech_wpm,
            "filler_count": baseline.speech_filler_count,
            "avg_pause": baseline.speech_avg_pause,
            "speech_rate": baseline.speech_rate
        }
    )

    cognitive_drift, _ = cognitive_analyzer.calculate_drift_score(
        cognitive_metrics,
        {
            "reaction_time_avg": baseline.reaction_time_avg,
            "reaction_time_std": baseline.reaction_time_std,
            "memory_accuracy": baseline.memory_accuracy,
            "memory_response_time": baseline.memory_response_time
        }
    )

    visual_motor_drift, _ = visual_motor_analyzer.calculate_drift_score(
        visual_motor_metrics,
        {
            "blink_frequency": baseline.blink_frequency,
            "smooth_pursuit_accuracy": baseline.smooth_pursuit_accuracy,
            "tracking_variance": baseline.tracking_variance
        }
    )

    # Calculate Neuro Load Score
    neuro_load_score, status, insights = scoring_engine.calculate_neuro_load_score(
        speech_drift, cognitive_drift, visual_motor_drift
    )

    # Create weekly assessment record
    assessment = WeeklyAssessment(
        user_id=user_id,
        baseline_id=baseline.id,
        week_number=assessment_data.week_number,
        # Speech
        speech_wpm=assessment_data.speech.wpm,
        speech_filler_count=assessment_data.speech.filler_count,
        speech_avg_pause=assessment_data.speech.avg_pause,
        speech_rate=assessment_data.speech.speech_rate,
        speech_drift_score=speech_drift,
        # Cognitive
        reaction_time_avg=cognitive_metrics["reaction_time_avg"],
        reaction_time_std=cognitive_metrics["reaction_time_std"],
        memory_accuracy=cognitive_metrics["memory_accuracy"],
        memory_response_time=cognitive_metrics["memory_response_time"],
        cognitive_drift_score=cognitive_drift,
        # Visual-motor
        blink_frequency=visual_motor_metrics["blink_frequency"],
        smooth_pursuit_accuracy=visual_motor_metrics["smooth_pursuit_accuracy"],
        tracking_variance=visual_motor_metrics["tracking_variance"],
        visual_motor_drift_score=visual_motor_drift,
        # Combined
        neuro_load_score=neuro_load_score,
        notes=assessment_data.notes
    )

    db.add(assessment)
    db.commit()
    db.refresh(assessment)

    return WeeklyAssessmentResponse(
        id=assessment.id,
        user_id=assessment.user_id,
        week_number=assessment.week_number,
        created_at=assessment.created_at,
        speech_drift_score=speech_drift,
        cognitive_drift_score=cognitive_drift,
        visual_motor_drift_score=visual_motor_drift,
        neuro_load_score=neuro_load_score,
        comparison_text="\n".join(insights)
    )

@router.get("/neuro-load/{week_number}", response_model=NeuroLoadScoreResponse)
async def get_neuro_load_score(
    week_number: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get Neuro Load Score for a specific week"""
    assessment = db.query(WeeklyAssessment).filter(
        WeeklyAssessment.user_id == user_id,
        WeeklyAssessment.week_number == week_number
    ).first()

    if not assessment:
        raise HTTPException(status_code=404, detail="Assessment not found")

    # Determine status
    if assessment.neuro_load_score < 15:
        status = "stable"
    elif assessment.neuro_load_score < 30:
        status = "minor_change"
    else:
        status = "significant_change"

    # Generate insights
    _, _, insights = scoring_engine.calculate_neuro_load_score(
        assessment.speech_drift_score,
        assessment.cognitive_drift_score,
        assessment.visual_motor_drift_score
    )

    return NeuroLoadScoreResponse(
        neuro_load_score=assessment.neuro_load_score,
        speech_drift_score=assessment.speech_drift_score,
        cognitive_drift_score=assessment.cognitive_drift_score,
        visual_motor_drift_score=assessment.visual_motor_drift_score,
        status=status,
        insights=insights,
        week_number=week_number
    )

@router.get("/trends", response_model=TrendResponse)
async def get_trends(
    user_id: int,
    limit: int = 12,
    db: Session = Depends(get_db)
):
    """Get trend analysis across multiple weeks"""
    assessments = db.query(WeeklyAssessment).filter(
        WeeklyAssessment.user_id == user_id
    ).order_by(WeeklyAssessment.week_number).limit(limit).all()

    if len(assessments) < 2:
        raise HTTPException(
            status_code=400,
            detail="At least 2 assessments required for trend analysis"
        )

    # Build trend data
    trends = [
        TrendData(
            week=a.week_number,
            date=a.created_at,
            neuro_load_score=a.neuro_load_score,
            speech_drift=a.speech_drift_score,
            cognitive_drift=a.cognitive_drift_score,
            visual_motor_drift=a.visual_motor_drift_score
        )
        for a in assessments
    ]

    # Analyze trends
    weekly_scores = [
        {"week_number": a.week_number, "neuro_load_score": a.neuro_load_score}
        for a in assessments
    ]

    trend_direction, avg_score, insights = scoring_engine.analyze_trend(weekly_scores)

    return TrendResponse(
        trends=trends,
        avg_score=avg_score,
        trend_direction=trend_direction,
        insights=insights
    )
