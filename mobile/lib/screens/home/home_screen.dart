import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_state.dart';
import 'dashboard_tab.dart';
import 'insights_tab.dart';
import 'profile_tab.dart';
import '../assessment/assessment_flow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const InsightsTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroLoad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!appState.hasBaseline) {
            _showBaselineDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AssessmentFlow(),
              ),
            );
          }
        },
        icon: const Icon(Icons.add_task),
        label: Text(appState.hasBaseline ? 'Weekly Check-In' : 'Start Baseline'),
      ),
    );
  }

  void _showBaselineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Baseline'),
        content: const Text(
          'Before you can start weekly check-ins, you need to establish your baseline. '
          'This involves completing all three assessments (speech, cognitive, and visual-motor) '
          'to set your personal performance benchmarks.\n\n'
          'The baseline takes about 5-10 minutes to complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssessmentFlow(isBaseline: true),
                ),
              );
            },
            child: const Text('Start Baseline'),
          ),
        ],
      ),
    );
  }
}
