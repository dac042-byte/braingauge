import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_state.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user?.username[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.username ?? 'Unknown User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Your Statistics'),
                subtitle: Text(
                  '${appState.trends.length} assessments completed',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show detailed statistics
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset Baseline'),
                subtitle: const Text('Start a new baseline period'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showResetBaselineDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                subtitle: const Text('Download your assessment history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data export feature coming soon'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show help screen
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About NeuroLoad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => _showLogoutDialog(context, appState),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Log Out'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showResetBaselineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Baseline?'),
        content: const Text(
          'Resetting your baseline will create a new comparison point for future assessments. '
          'Your historical data will be preserved but will use the old baseline.\n\n'
          'Are you sure you want to reset your baseline?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to baseline creation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Complete the assessment flow to create a new baseline'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About NeuroLoad'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NeuroLoad is a performance tracking tool designed for combat athletes to monitor cognitive function changes over time.',
              ),
              SizedBox(height: 16),
              Text(
                'Important Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This app is NOT a medical diagnostic tool. It is designed for wellness, '
                'self-monitoring, and training awareness only. If you have concerns about '
                'your health, please consult a medical professional.',
              ),
              SizedBox(height: 16),
              Text('Version 1.0.0'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              appState.logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
