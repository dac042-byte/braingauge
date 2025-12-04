from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
import json
import aiofiles
import os
from datetime import datetime

from app.models.database import get_db, User, Baseline, SpeechRecording
from app.models.schemas import SpeechAnalysisRequest, SpeechAnalysisResponse, SpeechFeatures
from app.services.speech_analyzer import SpeechAnalyzer
from app.routes.auth import get_current_user

router = APIRouter()
speech_analyzer = SpeechAnalyzer()

UPLOAD_DIR = "uploads/speech"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/analyze", response_model=SpeechAnalysisResponse)
async def analyze_speech(
    request: SpeechAnalysisRequest,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Analyze speech transcript and extract features

    If user has a baseline, also calculate drift score
    """
    # Extract features
    features_dict = speech_analyzer.analyze_transcript(
        transcript=request.transcript,
        duration=request.duration,
        word_timestamps=request.word_timestamps
    )

    features = SpeechFeatures(**features_dict)

    # Get user's active baseline if exists
    baseline = db.query(Baseline).filter(
        Baseline.user_id == user_id,
        Baseline.is_active == True
    ).first()

    drift_score = None
    comparison_text = None

    if baseline:
        # Calculate drift score
        baseline_features = {
            "wpm": baseline.speech_wpm,
            "filler_count": baseline.speech_filler_count,
            "avg_pause": baseline.speech_avg_pause,
            "speech_rate": baseline.speech_rate
        }

        drift_score, comparison_text = speech_analyzer.calculate_drift_score(
            features_dict, baseline_features
        )

    return SpeechAnalysisResponse(
        features=features,
        drift_score=drift_score,
        comparison_text=comparison_text
    )

@router.post("/upload")
async def upload_speech_audio(
    file: UploadFile = File(...),
    user_id: int = Form(...),
    db: Session = Depends(get_db)
):
    """
    Upload speech audio file

    Note: This endpoint accepts the audio file but does not perform
    speech-to-text conversion. In production, you would:
    1. Save the file
    2. Send it to a speech-to-text API (Whisper, Google, AssemblyAI)
    3. Return the transcript

    For now, it just saves the file and returns a placeholder response.
    """
    # Generate unique filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{user_id}_{timestamp}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # Save file
    async with aiofiles.open(file_path, 'wb') as out_file:
        content = await file.read()
        await out_file.write(content)

    # Create database record
    speech_recording = SpeechRecording(
        user_id=user_id,
        file_path=file_path,
        transcript="",  # Will be filled after speech-to-text
        duration=0.0,
        features={}
    )

    db.add(speech_recording)
    db.commit()

    return {
        "message": "Audio file uploaded successfully",
        "file_path": file_path,
        "recording_id": speech_recording.id,
        "note": "In production, this would trigger speech-to-text processing. For testing, use the /analyze endpoint directly with a transcript."
    }

@router.get("/passages")
async def get_speech_passages():
    """
    Get standardized speech passages for recording

    These passages are designed to elicit natural speech patterns
    and provide consistent material for baseline comparison
    """
    passages = [
        {
            "id": 1,
            "title": "The Rainbow Passage",
            "text": "When the sunlight strikes raindrops in the air, they act as a prism and form a rainbow. The rainbow is a division of white light into many beautiful colors. These take the shape of a long round arch, with its path high above, and its two ends apparently beyond the horizon. There is, according to legend, a boiling pot of gold at one end. People look, but no one ever finds it. When a man looks for something beyond his reach, his friends say he is looking for the pot of gold at the end of the rainbow.",
            "estimated_duration": "30-40 seconds",
            "difficulty": "medium"
        },
        {
            "id": 2,
            "title": "Grandfather Passage",
            "text": "You wish to know all about my grandfather. Well, he is nearly ninety-three years old. He dresses himself in an ancient black frock coat, usually minus several buttons; yet he still thinks as swiftly as ever. A long, flowing beard clings to his chin, giving those who observe him a pronounced feeling of the utmost respect. When he speaks, his voice is just a bit cracked and quivers a trifle. Twice each day he plays skillfully and with zest upon our small organ. Except in the winter when the ooze or snow or ice prevents, he slowly takes a short walk in the open air each day. We have often urged him to walk more and smoke less, but he always answers, 'Banana oil!' Grandfather likes to be modern in his language.",
            "estimated_duration": "45-60 seconds",
            "difficulty": "medium"
        },
        {
            "id": 3,
            "title": "Simple Description",
            "text": "Today I'm going to describe my typical training routine. I usually start with a warm-up that includes light cardio and stretching. Then I move on to technique work, focusing on precision and form. After that, I do sparring or pad work with a partner. I finish with conditioning exercises and a cool-down. The entire session typically lasts between one to two hours. Proper recovery is just as important as the training itself, so I make sure to get adequate rest and nutrition.",
            "estimated_duration": "30-40 seconds",
            "difficulty": "easy"
        }
    ]

    return {
        "passages": passages,
        "instructions": "Choose one passage and read it at your natural speaking pace. Try to be as fluent and conversational as possible. Record for 20-60 seconds."
    }
