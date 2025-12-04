from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import os

# SQLite database for simplicity - can be changed to PostgreSQL for production
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./neuroload.db")

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    baselines = relationship("Baseline", back_populates="user")
    weekly_assessments = relationship("WeeklyAssessment", back_populates="user")

class Baseline(Base):
    __tablename__ = "baselines"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    # Speech metrics
    speech_wpm = Column(Float)
    speech_filler_count = Column(Integer)
    speech_avg_pause = Column(Float)
    speech_rate = Column(Float)

    # Cognitive metrics
    reaction_time_avg = Column(Float)
    reaction_time_std = Column(Float)
    memory_accuracy = Column(Float)
    memory_response_time = Column(Float)

    # Visual-motor metrics
    blink_frequency = Column(Float)
    smooth_pursuit_accuracy = Column(Float)
    tracking_variance = Column(Float)

    user = relationship("User", back_populates="baselines")

class WeeklyAssessment(Base):
    __tablename__ = "weekly_assessments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    baseline_id = Column(Integer, ForeignKey("baselines.id"))
    week_number = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Speech metrics
    speech_wpm = Column(Float)
    speech_filler_count = Column(Integer)
    speech_avg_pause = Column(Float)
    speech_rate = Column(Float)
    speech_drift_score = Column(Float)

    # Cognitive metrics
    reaction_time_avg = Column(Float)
    reaction_time_std = Column(Float)
    memory_accuracy = Column(Float)
    memory_response_time = Column(Float)
    cognitive_drift_score = Column(Float)

    # Visual-motor metrics
    blink_frequency = Column(Float)
    smooth_pursuit_accuracy = Column(Float)
    tracking_variance = Column(Float)
    visual_motor_drift_score = Column(Float)

    # Combined score
    neuro_load_score = Column(Float)

    # Metadata
    notes = Column(String, nullable=True)
    raw_data = Column(JSON, nullable=True)

    user = relationship("User", back_populates="weekly_assessments")

class SpeechRecording(Base):
    __tablename__ = "speech_recordings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    assessment_id = Column(Integer, ForeignKey("weekly_assessments.id"), nullable=True)
    file_path = Column(String)
    transcript = Column(String)
    duration = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Extracted features
    features = Column(JSON)

def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)

def get_db():
    """Dependency for database sessions"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
