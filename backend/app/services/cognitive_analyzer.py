import numpy as np
from typing import Dict, List, Tuple

class CognitiveAnalyzer:
    """Analyzes cognitive test results (reaction time and working memory)"""

    def analyze_cognitive_tests(
        self,
        reaction_trials: List[float],
        reaction_accuracy: float,
        memory_correct: int,
        memory_total: int,
        memory_avg_time: float
    ) -> Dict[str, float]:
        """
        Extract cognitive performance metrics

        Args:
            reaction_trials: List of reaction times in milliseconds
            reaction_accuracy: Percentage of correct responses (0-100)
            memory_correct: Number of correct memory responses
            memory_total: Total number of memory trials
            memory_avg_time: Average response time for memory test (ms)

        Returns:
            Dictionary with extracted metrics
        """
        # Reaction time analysis
        reaction_avg = np.mean(reaction_trials) if reaction_trials else 0
        reaction_std = np.std(reaction_trials) if len(reaction_trials) > 1 else 0

        # Memory accuracy
        memory_accuracy = (memory_correct / memory_total * 100) if memory_total > 0 else 0

        return {
            "reaction_time_avg": round(reaction_avg, 2),
            "reaction_time_std": round(reaction_std, 2),
            "memory_accuracy": round(memory_accuracy, 2),
            "memory_response_time": round(memory_avg_time, 2)
        }

    def calculate_drift_score(
        self,
        current_metrics: Dict[str, float],
        baseline_metrics: Dict[str, float]
    ) -> Tuple[float, str]:
        """
        Calculate cognitive drift score

        Returns:
            (drift_score, comparison_text) tuple
            drift_score: 0-100 where 0 is identical, 100 is maximum drift
        """
        # Slower reaction time = potential decline (weight: 35%)
        rt_change = (current_metrics['reaction_time_avg'] - baseline_metrics['reaction_time_avg']) / baseline_metrics['reaction_time_avg']
        rt_score = max(rt_change, 0) * 100 * 0.35

        # Higher variability = potential decline (weight: 20%)
        std_change = (current_metrics['reaction_time_std'] - baseline_metrics['reaction_time_std']) / max(baseline_metrics['reaction_time_std'], 1)
        std_score = max(std_change, 0) * 100 * 0.20

        # Lower memory accuracy = potential decline (weight: 30%)
        mem_acc_change = (baseline_metrics['memory_accuracy'] - current_metrics['memory_accuracy']) / baseline_metrics['memory_accuracy']
        mem_acc_score = max(mem_acc_change, 0) * 100 * 0.30

        # Slower memory response = potential decline (weight: 15%)
        mem_time_change = (current_metrics['memory_response_time'] - baseline_metrics['memory_response_time']) / baseline_metrics['memory_response_time']
        mem_time_score = max(mem_time_change, 0) * 100 * 0.15

        # Combined drift score
        drift_score = min(rt_score + std_score + mem_acc_score + mem_time_score, 100)

        # Generate comparison text
        comparison_text = self._generate_comparison_text(
            current_metrics, baseline_metrics, drift_score
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

        # Reaction time changes
        rt_diff = current['reaction_time_avg'] - baseline['reaction_time_avg']
        if abs(rt_diff) > baseline['reaction_time_avg'] * 0.10:  # >10% change
            direction = "slower" if rt_diff > 0 else "faster"
            changes.append(f"Reaction time is {direction} by {abs(rt_diff):.0f}ms")

        # Variability changes
        std_diff = current['reaction_time_std'] - baseline['reaction_time_std']
        if abs(std_diff) > baseline['reaction_time_std'] * 0.20:  # >20% change
            if std_diff > 0:
                changes.append("Response consistency decreased")
            else:
                changes.append("Response consistency improved")

        # Memory accuracy changes
        mem_diff = current['memory_accuracy'] - baseline['memory_accuracy']
        if abs(mem_diff) > 5:  # >5% change
            direction = "decreased" if mem_diff < 0 else "improved"
            changes.append(f"Memory accuracy {direction} by {abs(mem_diff):.1f}%")

        # Memory response time changes
        time_diff = current['memory_response_time'] - baseline['memory_response_time']
        if abs(time_diff) > baseline['memory_response_time'] * 0.15:  # >15% change
            direction = "slower" if time_diff > 0 else "faster"
            changes.append(f"Memory response is {direction}")

        if not changes:
            return "Cognitive performance remains consistent with baseline"

        status = "stable" if drift_score < 15 else "showing changes"
        return f"Cognitive function is {status}: {', '.join(changes)}"
