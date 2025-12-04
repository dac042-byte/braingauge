import numpy as np
from typing import Dict, List, Tuple
from scipy.spatial.distance import euclidean

class VisualMotorAnalyzer:
    """Analyzes eye tracking and visual-motor coordination metrics"""

    def analyze_eye_tracking(
        self,
        blink_count: int,
        duration: float,
        tracking_points: List[Dict[str, float]],
        target_positions: List[Dict[str, float]]
    ) -> Dict[str, float]:
        """
        Extract visual-motor metrics from eye tracking data

        Args:
            blink_count: Number of blinks during test
            duration: Test duration in seconds
            tracking_points: List of {x, y, timestamp} eye positions
            target_positions: List of {x, y, timestamp} target positions

        Returns:
            Dictionary with extracted metrics
        """
        # Calculate blink frequency (blinks per minute)
        blink_frequency = (blink_count / duration) * 60 if duration > 0 else 0

        # Calculate smooth pursuit accuracy
        smooth_pursuit_accuracy = self._calculate_pursuit_accuracy(
            tracking_points, target_positions
        )

        # Calculate tracking variance (how stable the tracking is)
        tracking_variance = self._calculate_tracking_variance(
            tracking_points, target_positions
        )

        return {
            "blink_frequency": round(blink_frequency, 2),
            "smooth_pursuit_accuracy": round(smooth_pursuit_accuracy, 2),
            "tracking_variance": round(tracking_variance, 3)
        }

    def _calculate_pursuit_accuracy(
        self,
        tracking_points: List[Dict[str, float]],
        target_positions: List[Dict[str, float]]
    ) -> float:
        """
        Calculate how accurately eyes followed the target

        Returns accuracy as percentage (0-100)
        """
        if not tracking_points or not target_positions:
            return 0.0

        # Match tracking points to nearest target positions by timestamp
        distances = []

        for track_point in tracking_points:
            # Find closest target by timestamp
            closest_target = min(
                target_positions,
                key=lambda t: abs(t['timestamp'] - track_point['timestamp'])
            )

            # Calculate Euclidean distance
            distance = euclidean(
                [track_point['x'], track_point['y']],
                [closest_target['x'], closest_target['y']]
            )
            distances.append(distance)

        # Convert average distance to accuracy percentage
        # Assuming screen is normalized 0-1, distance >0.1 is considered poor
        avg_distance = np.mean(distances)
        accuracy = max(0, (1 - (avg_distance / 0.2)) * 100)  # 0.2 is max acceptable distance

        return accuracy

    def _calculate_tracking_variance(
        self,
        tracking_points: List[Dict[str, float]],
        target_positions: List[Dict[str, float]]
    ) -> float:
        """
        Calculate variance in tracking error (stability measure)

        Lower variance = more stable tracking
        """
        if not tracking_points or not target_positions:
            return 0.0

        distances = []

        for track_point in tracking_points:
            closest_target = min(
                target_positions,
                key=lambda t: abs(t['timestamp'] - track_point['timestamp'])
            )

            distance = euclidean(
                [track_point['x'], track_point['y']],
                [closest_target['x'], closest_target['y']]
            )
            distances.append(distance)

        return np.var(distances)

    def calculate_drift_score(
        self,
        current_metrics: Dict[str, float],
        baseline_metrics: Dict[str, float]
    ) -> Tuple[float, str]:
        """
        Calculate visual-motor drift score

        Returns:
            (drift_score, comparison_text) tuple
            drift_score: 0-100 where 0 is identical, 100 is maximum drift
        """
        # Abnormal blink frequency change (weight: 30%)
        # Both too few and too many blinks can indicate issues
        blink_change = abs(current_metrics['blink_frequency'] - baseline_metrics['blink_frequency']) / baseline_metrics['blink_frequency']
        blink_score = blink_change * 100 * 0.30

        # Lower pursuit accuracy = potential decline (weight: 45%)
        pursuit_change = (baseline_metrics['smooth_pursuit_accuracy'] - current_metrics['smooth_pursuit_accuracy']) / baseline_metrics['smooth_pursuit_accuracy']
        pursuit_score = max(pursuit_change, 0) * 100 * 0.45

        # Higher tracking variance = less stable, potential decline (weight: 25%)
        variance_change = (current_metrics['tracking_variance'] - baseline_metrics['tracking_variance']) / max(baseline_metrics['tracking_variance'], 0.001)
        variance_score = max(variance_change, 0) * 100 * 0.25

        # Combined drift score
        drift_score = min(blink_score + pursuit_score + variance_score, 100)

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

        # Blink frequency changes
        blink_diff = current['blink_frequency'] - baseline['blink_frequency']
        if abs(blink_diff) > baseline['blink_frequency'] * 0.20:  # >20% change
            direction = "increased" if blink_diff > 0 else "decreased"
            changes.append(f"Blink rate {direction} by {abs(blink_diff):.1f} blinks/min")

        # Pursuit accuracy changes
        pursuit_diff = current['smooth_pursuit_accuracy'] - baseline['smooth_pursuit_accuracy']
        if abs(pursuit_diff) > 5:  # >5% change
            direction = "decreased" if pursuit_diff < 0 else "improved"
            changes.append(f"Eye tracking accuracy {direction} by {abs(pursuit_diff):.1f}%")

        # Tracking variance changes
        variance_diff = current['tracking_variance'] - baseline['tracking_variance']
        if abs(variance_diff) > baseline['tracking_variance'] * 0.25:  # >25% change
            if variance_diff > 0:
                changes.append("Eye movement stability decreased")
            else:
                changes.append("Eye movement stability improved")

        if not changes:
            return "Visual-motor coordination remains consistent with baseline"

        status = "stable" if drift_score < 15 else "showing changes"
        return f"Visual-motor function is {status}: {', '.join(changes)}"
