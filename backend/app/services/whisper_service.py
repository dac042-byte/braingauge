import openai
import os
from typing import Dict, List

class WhisperService:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY environment variable not set")
        openai.api_key = self.api_key

    def transcribe_audio(self, audio_file_path: str) -> Dict:
        """
        Transcribe audio file using OpenAI Whisper
        Returns transcript with word-level timestamps
        """
        try:
            with open(audio_file_path, 'rb') as audio_file:
                transcript = openai.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                    response_format="verbose_json",
                    timestamp_granularities=["word"]
                )
            
            # Extract word timestamps
            word_timestamps = []
            if hasattr(transcript, 'words') and transcript.words:
                word_timestamps = [
                    {
                        "word": word.word,
                        "start": word.start,
                        "end": word.end
                    }
                    for word in transcript.words
                ]
            
            return {
                "text": transcript.text,
                "duration": getattr(transcript, 'duration', 0),
                "word_timestamps": word_timestamps
            }
        except Exception as e:
            raise Exception(f"Whisper transcription failed: {str(e)}")