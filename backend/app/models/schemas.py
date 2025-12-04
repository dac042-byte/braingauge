from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

# User schemas
class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True

# Speech Analysis schemas
class SpeechFeatures(BaseModel):
    wpm: float
    filler_count: int
    avg_pause: float
    speech_rate: float

class SpeechAnalysisRequest(BaseModel):
    transcript: str
    duration: float
    word_timestamps: Optional[List[Dict[str, Any]]] = None

class SpeechAnalysisResponse(BaseModel):
    features: SpeechFeatures
    drift_score: Optional[float] = None
    comparison_text: Optional[str] = None

# Cognitive Test schemas
class ReactionTimeData(BaseModel):
    trials: List[float]  # Reaction times in milliseconds
    accuracy: float  # Percentage of correct responses

class WorkingMemoryData(BaseModel):
    correct_responses: int
    total_trials: int
    avg_response_time: float
    accuracy: float

class CognitiveTestRequest(BaseModel):
    reaction_time: ReactionTimeData
    working_memory: WorkingMemoryData

class CognitiveTestResponse(BaseModel):
    reaction_time_avg: float
    reaction_time_std: float
    memory_accuracy: float
    memory_response_time: float
    drift_score: Optional[float] = None
    comparison_text: Optional[str] = None

# Visual-Motor schemas
class EyeTrackingData(BaseModel):
    blink_count: int
    duration: float
    tracking_points: List[Dict[str, float]]  # [{x, y, timestamp}, ...]
    target_positions: List[Dict[str, float]]  # [{x, y, timestamp}, ...]

class VisualMotorRequest(BaseModel):
    eye_tracking: EyeTrackingData

class VisualMotorResponse(BaseModel):
    blink_frequency: float
    smooth_pursuit_accuracy: float
    tracking_variance: float
    drift_score: Optional[float] = None
    comparison_text: Optional[str] = None

# Baseline schemas
class BaselineCreate(BaseModel):
    speech: SpeechFeatures
    cognitive: CognitiveTestRequest
    visual_motor: VisualMotorRequest

class BaselineResponse(BaseModel):
    id: int
    user_id: int
    created_at: datetime
    is_active: bool
    speech_wpm: float
    speech_filler_count: int
    speech_avg_pause: float
    speech_rate: float
    reaction_time_avg: float
    reaction_time_std: float
    memory_accuracy: float
    memory_response_time: float
    blink_frequency: float
    smooth_pursuit_accuracy: float
    tracking_variance: float

    class Config:
        from_attributes = True

# Weekly Assessment schemas
class WeeklyAssessmentCreate(BaseModel):
    week_number: int
    speech: SpeechFeatures
    cognitive: CognitiveTestRequest
    visual_motor: VisualMotorRequest
    notes: Optional[str] = None

class WeeklyAssessmentResponse(BaseModel):
    id: int
    user_id: int
    week_number: int
    created_at: datetime
    speech_drift_score: float
    cognitive_drift_score: float
    visual_motor_drift_score: float
    neuro_load_score: float
    comparison_text: str

    class Config:
        from_attributes = True

# Neuro Load Score schemas
class NeuroLoadScoreResponse(BaseModel):
    neuro_load_score: float
    speech_drift_score: float
    cognitive_drift_score: float
    visual_motor_drift_score: float
    status: str  # "stable", "minor_change", "significant_change"
    insights: List[str]
    week_number: int

class TrendData(BaseModel):
    week: int
    date: datetime
    neuro_load_score: float
    speech_drift: float
    cognitive_drift: float
    visual_motor_drift: float

class TrendResponse(BaseModel):
    trends: List[TrendData]
    avg_score: float
    trend_direction: str  # "improving", "stable", "declining"
    insights: List[str]
