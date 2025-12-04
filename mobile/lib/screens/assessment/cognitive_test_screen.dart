import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class CognitiveTestScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const CognitiveTestScreen({super.key, required this.onComplete});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  int _currentTest = 0; // 0 = intro, 1 = reaction time, 2 = working memory
  bool _showTarget = false;
  DateTime? _targetShowTime;
  final List<double> _reactionTimes = [];
  int _currentTrial = 0;
  final int _totalTrials = 10;

  // Working memory test
  final List<String> _letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  final List<String> _sequence = [];
  int _memoryTrial = 0;
  final int _memoryTrials = 20;
  int _correctResponses = 0;
  final List<double> _memoryResponseTimes = [];

  @override
  Widget build(BuildContext context) {
    switch (_currentTest) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildReactionTimeTest();
      case 2:
        return _buildWorkingMemoryTest();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.psychology,
            size: 80,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
          Text(
            'Cognitive Tests',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'You will complete two quick cognitive tests:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildTestCard(
            icon: Icons.touch_app,
            title: 'Reaction Time',
            description:
                'Tap the screen as quickly as possible when you see the target appear.',
            duration: '~1 minute',
          ),
          const SizedBox(height: 16),
          _buildTestCard(
            icon: Icons.memory,
            title: 'Working Memory',
            description:
                'Tap when the current letter matches the letter from 2 steps ago.',
            duration: '~2 minutes',
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              setState(() {
                _currentTest = 1;
              });
              _startReactionTimeTest();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Start Tests'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.purple, size: 32),
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
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionTimeTest() {
    return GestureDetector(
      onTap: _handleReactionTap,
      child: Container(
        color: _showTarget ? Colors.green : Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_showTarget)
                const Icon(
                  Icons.circle,
                  size: 100,
                  color: Colors.white,
                )
              else
                const Text(
                  'Wait...',
                  style: TextStyle(fontSize: 24),
                ),
              const SizedBox(height: 32),
              Text(
                'Trial ${_currentTrial + 1} of $_totalTrials',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startReactionTimeTest() {
    _scheduleNextTarget();
  }

  void _scheduleNextTarget() {
    final random = Random();
    final delay = 1000 + random.nextInt(2000); // 1-3 seconds

    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && _currentTest == 1) {
        setState(() {
          _showTarget = true;
          _targetShowTime = DateTime.now();
        });
      }
    });
  }

  void _handleReactionTap() {
    if (!_showTarget) return;

    final reactionTime =
        DateTime.now().difference(_targetShowTime!).inMilliseconds.toDouble();
    _reactionTimes.add(reactionTime);

    setState(() {
      _showTarget = false;
      _currentTrial++;
    });

    if (_currentTrial < _totalTrials) {
      _scheduleNextTarget();
    } else {
      // Move to working memory test
      setState(() {
        _currentTest = 2;
      });
      _startWorkingMemoryTest();
    }
  }

  Widget _buildWorkingMemoryTest() {
    if (_sequence.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Trial ${_memoryTrial + 1} of $_memoryTrials',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),
          Text(
            _sequence[_memoryTrial],
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tap if this matches the letter from 2 steps ago',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleMemoryResponse(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                  ),
                  child: const Text('No Match'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => _handleMemoryResponse(true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                  ),
                  child: const Text('Match!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startWorkingMemoryTest() {
    // Generate sequence
    final random = Random();
    for (int i = 0; i < _memoryTrials; i++) {
      _sequence.add(_letters[random.nextInt(_letters.length)]);
    }
    setState(() {});
  }

  void _handleMemoryResponse(bool userSaysMatch) {
    // Check if correct
    bool isActualMatch = false;
    if (_memoryTrial >= 2) {
      isActualMatch = _sequence[_memoryTrial] == _sequence[_memoryTrial - 2];
    }

    if (userSaysMatch == isActualMatch) {
      _correctResponses++;
    }

    _memoryResponseTimes.add(500 + Random().nextDouble() * 500); // Mock

    _memoryTrial++;

    if (_memoryTrial < _memoryTrials) {
      setState(() {});
    } else {
      _completeTests();
    }
  }

  void _completeTests() {
    final avgReactionTime =
        _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
    final stdReactionTime = _calculateStd(_reactionTimes);
    final memoryAccuracy = (_correctResponses / _memoryTrials) * 100;
    final avgMemoryTime =
        _memoryResponseTimes.reduce((a, b) => a + b) / _memoryResponseTimes.length;

    final data = {
      'reaction_time': {
        'trials': _reactionTimes,
        'accuracy': 100.0, // Simplified
      },
      'working_memory': {
        'correct_responses': _correctResponses,
        'total_trials': _memoryTrials,
        'avg_response_time': avgMemoryTime,
        'accuracy': memoryAccuracy,
      },
    };

    widget.onComplete(data);
  }

  double _calculateStd(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}
