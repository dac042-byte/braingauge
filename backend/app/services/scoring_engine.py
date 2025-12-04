from typing import Dict, List, Tuple

class ScoringEngine:
    """
    Calculates the Neuro Load Score by combining drift scores from
    speech, cognitive, and visual-motor assessments
    """

    # Weight distribution for combined score
    WEIGHTS = {
        "speech": 0.30,      # 30% weight
        "cognitive": 0.45,   # 45% weight (most important)
        "visual_motor": 0.25  # 25% weight
    }

    # Thresholds for status classification
    THRESHOLDS = {
        "stable": 15,
        "minor_change": 30,
        "significant_change": 100
    }

    def calculate_neuro_load_score(
        self,
        speech_drift: float,
        cognitive_drift: float,
        visual_motor_drift: float
    ) -> Tuple[float, str, List[str]]:
        """
        Calculate combined Neuro Load Score

        Args:
            speech_drift: Speech drift score (0-100)
            cognitive_drift: Cognitive drift score (0-100)
            visual_motor_drift: Visual-motor drift score (0-100)

        Returns:
            (neuro_load_score, status, insights) tuple
        """
        # Calculate weighted combined score
        neuro_load_score = (
            speech_drift * self.WEIGHTS["speech"] +
            cognitive_drift * self.WEIGHTS["cognitive"] +
            visual_motor_drift * self.WEIGHTS["visual_motor"]
        )

        # Determine status
        status = self._classify_status(neuro_load_score)

        # Generate insights
        insights = self._generate_insights(
            neuro_load_score, speech_drift, cognitive_drift, visual_motor_drift
        )

        return round(neuro_load_score, 2), status, insights

    def _classify_status(self, score: float) -> str:
        """Classify the neuro load score into status categories"""
        if score < self.THRESHOLDS["stable"]:
            return "stable"
        elif score < self.THRESHOLDS["minor_change"]:
            return "minor_change"
        else:
            return "significant_change"

    def _generate_insights(
        self,
        neuro_load_score: float,
        speech_drift: float,
        cognitive_drift: float,
        visual_motor_drift: float
    ) -> List[str]:
        """Generate actionable insights based on scores"""
        insights = []

        # Overall status insight
        if neuro_load_score < 15:
            insights.append("Your neurological performance is stable and consistent with your baseline.")
        elif neuro_load_score < 30:
            insights.append("You're showing minor changes from baseline. This could be normal variation or training fatigue.")
        else:
            insights.append("You're showing significant changes from baseline. Consider rest and recovery.")

        # Identify primary area of change
        scores = {
            "cognitive": cognitive_drift,
            "speech": speech_drift,
            "visual_motor": visual_motor_drift
        }
        max_area = max(scores, key=scores.get)
        max_score = scores[max_area]

        if max_score > 20:
            area_names = {
                "cognitive": "cognitive performance",
                "speech": "speech patterns",
                "visual_motor": "visual-motor coordination"
            }
            insights.append(f"Primary change detected in {area_names[max_area]}.")

        # Specific recommendations
        if cognitive_drift > 25:
            insights.append("Consider reducing training intensity and prioritizing sleep.")
        elif cognitive_drift > 15:
            insights.append("Your reaction time and memory may benefit from extra rest.")

        if speech_drift > 20:
            insights.append("Speech changes may indicate fatigue. Ensure adequate recovery time.")

        if visual_motor_drift > 20:
            insights.append("Eye tracking changes detected. Consider visual rest and reduced screen time.")

        # Positive reinforcement for stability
        if all(score < 10 for score in scores.values()):
            insights.append("All metrics are stable. Your training load appears well-managed.")

        return insights

    def analyze_trend(
        self,
        weekly_scores: List[Dict]
    ) -> Tuple[str, float, List[str]]:
        """
        Analyze trend across multiple weeks

        Args:
            weekly_scores: List of dicts with week_number and neuro_load_score

        Returns:
            (trend_direction, avg_score, trend_insights) tuple
        """
        if len(weekly_scores) < 2:
            return "insufficient_data", 0.0, ["Need at least 2 weeks of data to analyze trends"]

        scores = [w['neuro_load_score'] for w in weekly_scores]
        avg_score = sum(scores) / len(scores)

        # Calculate trend using linear regression slope
        weeks = list(range(len(scores)))
        if len(weeks) > 1:
            # Simple linear regression
            mean_week = sum(weeks) / len(weeks)
            mean_score = sum(scores) / len(scores)

            numerator = sum((w - mean_week) * (s - mean_score) for w, s in zip(weeks, scores))
            denominator = sum((w - mean_week) ** 2 for w in weeks)

            slope = numerator / denominator if denominator != 0 else 0
        else:
            slope = 0

        # Classify trend
        if slope < -2:
            trend_direction = "improving"
        elif slope > 2:
            trend_direction = "declining"
        else:
            trend_direction = "stable"

        # Generate trend insights
        trend_insights = self._generate_trend_insights(
            trend_direction, avg_score, scores
        )

        return trend_direction, round(avg_score, 2), trend_insights

    def _generate_trend_insights(
        self,
        trend_direction: str,
        avg_score: float,
        scores: List[float]
    ) -> List[str]:
        """Generate insights about score trends over time"""
        insights = []

        if trend_direction == "improving":
            insights.append("Your scores are trending in a positive direction over time.")
            insights.append("Current training and recovery strategies appear effective.")
        elif trend_direction == "declining":
            insights.append("Your scores show an upward trend, indicating increasing drift from baseline.")
            insights.append("Consider reviewing your training load and recovery protocols.")
        else:
            insights.append("Your scores remain relatively stable over time.")

        # Variability analysis
        if len(scores) > 2:
            score_variance = sum((s - avg_score) ** 2 for s in scores) / len(scores)
            if score_variance > 100:
                insights.append("Your scores show high week-to-week variability. Consider more consistent training patterns.")
            elif score_variance < 25:
                insights.append("Your scores are consistent week-to-week, suggesting stable performance.")

        # Recent vs historical comparison
        if len(scores) >= 4:
            recent_avg = sum(scores[-2:]) / 2
            historical_avg = sum(scores[:-2]) / (len(scores) - 2)

            if recent_avg > historical_avg + 5:
                insights.append("Recent weeks show higher scores than your earlier weeks.")
            elif recent_avg < historical_avg - 5:
                insights.append("Recent weeks show improvement compared to earlier weeks.")

        return insights
