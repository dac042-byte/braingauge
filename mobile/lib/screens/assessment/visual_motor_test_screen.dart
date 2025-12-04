import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class VisualMotorTestScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const VisualMotorTestScreen({super.key, required this.onComplete});

  @override
  State<VisualMotorTestScreen> createState() => _VisualMotorTestScreenState();
}

class _VisualMotorTestScreenState extends State<VisualMotorTestScreen>
    with SingleTickerProviderStateMixin {
  bool _isTestRunning = false;
  bool _isComplete = false;
  late AnimationController _animationController;
  final List<Map<String, double>> _trackingPoints = [];
  final List<Map<String, double>> _targetPositions = [];
  Timer? _trackingTimer;
  int _blinkCount = 0;
  final double _testDuration = 15.0; // seconds

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _trackingPoints.clear();
      _targetPositions.clear();
      _blinkCount = 0;
    });

    _animationController.reset();
    _animationController.forward();

    // Simulate tracking data collection
    _trackingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isTestRunning) {
        timer.cancel();
        return;
      }

      final random = Random();
      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // Target position (circular movement)
      final angle = _animationController.value * 2 * pi;
      final targetX = 0.5 + 0.3 * cos(angle);
      final targetY = 0.5 + 0.3 * sin(angle);

      _targetPositions.add({
        'x': targetX,
        'y': targetY,
        'timestamp': timestamp,
      });

      // Simulated eye tracking (with some error/noise)
      final trackingX = targetX + (random.nextDouble() - 0.5) * 0.05;
      final trackingY = targetY + (random.nextDouble() - 0.5) * 0.05;

      _trackingPoints.add({
        'x': trackingX,
        'y': trackingY,
        'timestamp': timestamp,
      });

      // Simulate occasional blinks
      if (random.nextInt(100) < 2) {
        // 2% chance each tick
        setState(() {
          _blinkCount++;
        });
      }
    });

    // Stop test after duration
    Future.delayed(Duration(seconds: _testDuration.toInt()), () {
      if (mounted) {
        _stopTest();
      }
    });
  }

  void _stopTest() {
    _trackingTimer?.cancel();
    _animationController.stop();

    setState(() {
      _isTestRunning = false;
      _isComplete = true;
    });
  }

  void _submitResults() {
    final data = {
      'eye_tracking': {
        'blink_count': _blinkCount,
        'duration': _testDuration,
        'tracking_points': _trackingPoints,
        'target_positions': _targetPositions,
      },
    };

    widget.onComplete(data);
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return _buildCompletionScreen();
    }

    if (!_isTestRunning) {
      return _buildInstructions();
    }

    return _buildTestScreen();
  }

  Widget _buildInstructions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.visibility,
            size: 80,
            color: Colors.teal,
          ),
          const SizedBox(height: 24),
          Text(
            'Eye Tracking Test',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Follow the moving dot with your eyes while keeping your head still.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Hold your phone at arm\'s length'),
                  const SizedBox(height: 4),
                  const Text('2. Keep your head still'),
                  const SizedBox(height: 4),
                  const Text('3. Follow the dot with your eyes only'),
                  const SizedBox(height: 4),
                  const Text('4. Try to blink naturally'),
                  const SizedBox(height: 4),
                  const Text('5. Test duration: 15 seconds'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _startTest,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Start Test'),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Note: This demo uses simulated eye tracking. In production, this would use the device camera and face detection.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestScreen() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final angle = _animationController.value * 2 * pi;
        final x = 0.5 + 0.3 * cos(angle);
        final y = 0.5 + 0.3 * sin(angle);

        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width * x - 15,
                top: MediaQuery.of(context).size.height * y - 15,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_testDuration * (1 - _animationController.value)).toInt()}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Test Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildStat('Duration', '${_testDuration.toInt()}s'),
                  const Divider(),
                  _buildStat('Tracking Points', '${_trackingPoints.length}'),
                  const Divider(),
                  _buildStat('Blinks Detected', '$_blinkCount'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _submitResults,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Complete Assessment'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isComplete = false;
                _isTestRunning = false;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Retry Test'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
