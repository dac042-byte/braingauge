import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_state.dart';
import 'speech_test_screen.dart';
import 'cognitive_test_screen.dart';
import 'visual_motor_test_screen.dart';
import 'results_screen.dart';

class AssessmentFlow extends StatefulWidget {
  final bool isBaseline;

  const AssessmentFlow({super.key, this.isBaseline = false});

  @override
  State<AssessmentFlow> createState() => _AssessmentFlowState();
}

class _AssessmentFlowState extends State<AssessmentFlow> {
  int _currentStep = 0;
  Map<String, dynamic>? _speechData;
  Map<String, dynamic>? _cognitiveData;
  Map<String, dynamic>? _visualMotorData;
  bool _isSubmitting = false;

  final List<String> _stepTitles = [
    'Speech Recording',
    'Cognitive Tests',
    'Eye Tracking',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBaseline ? 'Baseline Assessment' : 'Weekly Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 2) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of 3: ${_stepTitles[_currentStep]}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return SpeechTestScreen(
          onComplete: (data) {
            setState(() {
              _speechData = data;
              _currentStep = 1;
            });
          },
        );
      case 1:
        return CognitiveTestScreen(
          onComplete: (data) {
            setState(() {
              _cognitiveData = data;
              _currentStep = 2;
            });
          },
        );
      case 2:
        return VisualMotorTestScreen(
          onComplete: (data) async {
            setState(() {
              _visualMotorData = data;
              _isSubmitting = true;
            });
            await _submitAssessment();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _submitAssessment() async {
    if (_speechData == null ||
        _cognitiveData == null ||
        _visualMotorData == null) {
      return;
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (widget.isBaseline) {
        await appState.createBaseline(
          _speechData!,
          _cognitiveData!,
          _visualMotorData!,
        );
      } else {
        final assessment = await appState.createWeeklyAssessment(
          _speechData!,
          _cognitiveData!,
          _visualMotorData!,
          null,
        );

        // Navigate to results screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(assessment: assessment),
            ),
          );
        }
      }

      if (mounted && widget.isBaseline) {
        // Show success dialog for baseline
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Baseline Created!'),
            content: const Text(
              'Your baseline has been successfully established. You can now start your weekly check-ins to track changes over time.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close assessment flow
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Assessment?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close assessment flow
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
