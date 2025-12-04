import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_state.dart';
import 'package:intl/intl.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.trends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Insights Yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Complete weekly check-ins to get personalized insights about your cognitive performance.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(context, appState),
        const SizedBox(height: 16),
        _buildWeeklyHistory(context, appState),
        const SizedBox(height: 16),
        _buildRecommendations(context),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppState appState) {
    final trends = appState.trends;
    final avgScore =
        trends.map((t) => t.neuroLoadScore).reduce((a, b) => a + b) /
            trends.length;

    // Calculate trend direction
    final recentAvg = trends
            .skip(trends.length > 3 ? trends.length - 3 : 0)
            .map((t) => t.neuroLoadScore)
            .reduce((a, b) => a + b) /
        (trends.length > 3 ? 3 : trends.length);

    String trendText;
    IconData trendIcon;
    Color trendColor;

    if (recentAvg < avgScore - 5) {
      trendText = 'Improving';
      trendIcon = Icons.trending_down;
      trendColor = Colors.green;
    } else if (recentAvg > avgScore + 5) {
      trendText = 'Increasing Drift';
      trendIcon = Icons.trending_up;
      trendColor = Colors.red;
    } else {
      trendText = 'Stable';
      trendIcon = Icons.trending_flat;
      trendColor = Colors.blue;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Score',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avgScore.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        trendText,
                        style: TextStyle(
                          color: trendColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              '${trends.length} week${trends.length == 1 ? '' : 's'} of data tracked',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHistory(BuildContext context, AppState appState) {
    final trends = appState.trends.reversed.toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Weekly History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trends.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trend = trends[index];
              final dateStr = DateFormat('MMM dd, yyyy').format(trend.date);

              Color scoreColor;
              if (trend.neuroLoadScore < 15) {
                scoreColor = Colors.green;
              } else if (trend.neuroLoadScore < 30) {
                scoreColor = Colors.orange;
              } else {
                scoreColor = Colors.red;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: scoreColor.withOpacity(0.2),
                  child: Text(
                    'W${trend.week}',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  'Neuro Load: ${trend.neuroLoadScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(dateStr),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  // TODO: Show detailed week view
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for Accurate Tracking',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip('Complete check-ins at the same time each week'),
            _buildTip('Ensure you\'re well-rested before assessments'),
            _buildTip('Minimize distractions during tests'),
            _buildTip('Use the same environment for consistency'),
            _buildTip('Track training intensity in notes'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 20)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
