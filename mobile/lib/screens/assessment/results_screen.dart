import 'package:flutter/material.dart';
import '../../models/assessment.dart';

class ResultsScreen extends StatelessWidget {
  final WeeklyAssessment assessment;

  const ResultsScreen({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    String statusText;
    IconData statusIcon;
    String statusDescription;

    if (assessment.neuroLoadScore < 15) {
      scoreColor = Colors.green;
      statusText = 'Stable';
      statusIcon = Icons.check_circle;
      statusDescription =
          'Your cognitive performance is consistent with your baseline. Keep up your current training and recovery routine.';
    } else if (assessment.neuroLoadScore < 30) {
      scoreColor = Colors.orange;
      statusText = 'Minor Changes';
      statusIcon = Icons.warning;
      statusDescription =
          'You\'re showing some changes from baseline. This could be normal variation or indicate training fatigue. Monitor your recovery.';
    } else {
      scoreColor = Colors.red;
      statusText = 'Significant Changes';
      statusIcon = Icons.error;
      statusDescription =
          'Significant changes detected from your baseline. Consider extra rest and recovery. If changes persist, consult a healthcare professional.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main score card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      statusIcon,
                      size: 80,
                      color: scoreColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Neuro Load Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment.neuroLoadScore.toStringAsFixed(1),
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 72,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Week ${assessment.weekNumber}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status description
            Card(
              color: scoreColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: scoreColor),
                        const SizedBox(width: 8),
                        Text(
                          'What This Means',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(statusDescription),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Score breakdown
            Text(
              'Score Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              context,
              'Speech Analysis',
              assessment.speechDriftScore,
              Icons.record_voice_over,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildMetricCard(
              context,
              'Cognitive Function',
              assessment.cognitiveDriftScore,
              Icons.psychology,
              Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildMetricCard(
              context,
              'Visual-Motor Coordination',
              assessment.visualMotorDriftScore,
              Icons.remove_red_eye,
              Colors.teal,
            ),
            const SizedBox(height: 24),

            // Insights
            if (assessment.comparisonText.isNotEmpty) ...[
              Text(
                'Detailed Insights',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(assessment.comparisonText),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Important disclaimer
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This app is a performance tracking tool, not a medical diagnostic device. '
                      'If you have health concerns, please consult a healthcare professional.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            FilledButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Return to Dashboard'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    double score,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
