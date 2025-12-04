import re
from typing import List, Dict, Tuple, Optional
import numpy as np

class SpeechAnalyzer:
    """Analyzes speech transcripts and extracts cognitive performance features"""

    FILLER_WORDS = [
        "um", "uh", "like", "you know", "i mean", "kind of", "sort of",
        "actually", "basically", "literally", "right", "okay", "so"
    ]

    def __init__(self):
        self.filler_pattern = self._compile_filler_pattern()

    def _compile_filler_pattern(self) -> re.Pattern:
        """Compile regex pattern for detecting filler words"""
        pattern = r'\b(' + '|'.join(self.FILLER_WORDS) + r')\b'
        return re.compile(pattern, re.IGNORECASE)

    def analyze_transcript(
        self,
        transcript: str,
        duration: float,
        word_timestamps: Optional[List[Dict]] = None
    ) -> Dict[str, float]:
        """
        Extract speech features from transcript

        Args:
            transcript: Full transcript text
            duration: Recording duration in seconds
            word_timestamps: Optional list of {word, start, end} dicts

        Returns:
            Dictionary with extracted features
        """
        # Clean transcript
        cleaned_text = transcript.lower().strip()

        # Count filler words
        filler_count = len(self.filler_pattern.findall(cleaned_text))

        # Calculate words per minute (WPM)
        words = cleaned_text.split()
        word_count = len(words)
        wpm = (word_count / duration) * 60 if duration > 0 else 0

        # Calculate speech rate (words per second)
        speech_rate = word_count / duration if duration > 0 else 0

        # Calculate average pause length
        if word_timestamps:
            avg_pause = self._calculate_avg_pause(word_timestamps)
        else:
            # Estimate based on duration and word count
            # Assume 20% of time is pauses on average
            estimated_pause_time = duration * 0.2
            estimated_pause_count = max(word_count - 1, 1)
            avg_pause = estimated_pause_time / estimated_pause_count

        return {
            "wpm": round(wpm, 2),
            "filler_count": filler_count,
            "avg_pause": round(avg_pause, 3),
            "speech_rate": round(speech_rate, 3)
        }

    def _calculate_avg_pause(self, word_timestamps: List[Dict]) -> float:
        """Calculate average pause length between words"""
        if len(word_timestamps) < 2:
            return 0.0

        pauses = []
        for i in range(len(word_timestamps) - 1):
            current_end = word_timestamps[i].get('end', 0)
            next_start = word_timestamps[i + 1].get('start', 0)
            pause = next_start - current_end
            if pause > 0:  # Only count actual pauses
                pauses.append(pause)

        return np.mean(pauses) if pauses else 0.0

    def calculate_drift_score(
        self,
        current_features: Dict[str, float],
        baseline_features: Dict[str, float]
    ) -> Tuple[float, str]:
        """
        Calculate speech drift score by comparing current to baseline

        Returns:
            (drift_score, comparison_text) tuple
            drift_score: 0-100 where 0 is identical, 100 is maximum drift
        """
        # Calculate normalized differences for each metric
        # Lower WPM = potential cognitive decline (weight: 30%)
        wpm_change = (baseline_features['wpm'] - current_features['wpm']) / baseline_features['wpm']
        wpm_score = abs(wpm_change) * 100 * 0.30

        # More filler words = potential cognitive decline (weight: 25%)
        filler_change = (current_features['filler_count'] - baseline_features['filler_count']) / max(baseline_features['filler_count'], 1)
        filler_score = max(filler_change, 0) * 100 * 0.25

        # Longer pauses = potential cognitive decline (weight: 25%)
        pause_change = (current_features['avg_pause'] - baseline_features['avg_pause']) / baseline_features['avg_pause']
        pause_score = max(pause_change, 0) * 100 * 0.25

        # Lower speech rate = potential cognitive decline (weight: 20%)
        rate_change = (baseline_features['speech_rate'] - current_features['speech_rate']) / baseline_features['speech_rate']
        rate_score = abs(rate_change) * 100 * 0.20

        # Combined drift score
        drift_score = min(wpm_score + filler_score + pause_score + rate_score, 100)

        # Generate comparison text
        comparison_text = self._generate_comparison_text(
            current_features, baseline_features, drift_score
        )

        return round(drift_score, 2), comparison_text

    def _generate_comparison_text(
        self,
        current: Dict[str, float],
        baseline: Dict[str, float],
        drift_score: float
    ) -> str:
        """Generate human-readable comparison text"""
        changes = []

        wpm_diff = current['wpm'] - baseline['wpm']
        if abs(wpm_diff) > baseline['wpm'] * 0.10:  # >10% change
            direction = "decreased" if wpm_diff < 0 else "increased"
            changes.append(f"Speech speed {direction} by {abs(wpm_diff):.1f} WPM")

        filler_diff = current['filler_count'] - baseline['filler_count']
        if abs(filler_diff) >= 2:
            direction = "increased" if filler_diff > 0 else "decreased"
            changes.append(f"Filler words {direction} by {abs(filler_diff)}")

        pause_diff = current['avg_pause'] - baseline['avg_pause']
        if abs(pause_diff) > baseline['avg_pause'] * 0.15:  # >15% change
            direction = "longer" if pause_diff > 0 else "shorter"
            changes.append(f"Pauses are {direction}")

        if not changes:
            return "Speech patterns remain stable and consistent with baseline"

        status = "stable" if drift_score < 15 else "showing changes"
        return f"Speech is {status}: {', '.join(changes)}"
