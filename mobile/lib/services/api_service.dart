import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/assessment.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8000/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth endpoints
  Future<User> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Speech endpoints
  Future<Map<String, dynamic>> analyzeSpeech(
    int userId,
    String transcript,
    double duration,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/speech/analyze?user_id=$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'transcript': transcript,
        'duration': duration,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze speech: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSpeechPassages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/speech/passages'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get passages: ${response.body}');
    }
  }

  // Cognitive test endpoints
  Future<Map<String, dynamic>> analyzeCognitiveTests(
    int userId,
    List<double> reactionTrials,
    double reactionAccuracy,
    int memoryCorrect,
    int memoryTotal,
    double memoryAvgTime,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cognitive/analyze?user_id=$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'reaction_time': {
          'trials': reactionTrials,
          'accuracy': reactionAccuracy,
        },
        'working_memory': {
          'correct_responses': memoryCorrect,
          'total_trials': memoryTotal,
          'avg_response_time': memoryAvgTime,
          'accuracy': (memoryCorrect / memoryTotal) * 100,
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze cognitive tests: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getReactionTimeConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cognitive/reaction-time-config'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get reaction time config');
    }
  }

  Future<Map<String, dynamic>> getWorkingMemoryConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cognitive/working-memory-config'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get working memory config');
    }
  }

  // Visual-motor endpoints
  Future<Map<String, dynamic>> analyzeVisualMotor(
    int userId,
    int blinkCount,
    double duration,
    List<Map<String, double>> trackingPoints,
    List<Map<String, double>> targetPositions,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/visual/analyze?user_id=$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'eye_tracking': {
          'blink_count': blinkCount,
          'duration': duration,
          'tracking_points': trackingPoints,
          'target_positions': targetPositions,
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze visual-motor: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTrackingConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/visual/tracking-config'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get tracking config');
    }
  }

  // Score endpoints
  Future<void> createBaseline(
    int userId,
    Map<String, dynamic> speechData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> visualMotorData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/score/baseline?user_id=$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'speech': speechData,
        'cognitive': cognitiveData,
        'visual_motor': visualMotorData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create baseline: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getActiveBaseline(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/score/baseline?user_id=$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get baseline: ${response.body}');
    }
  }

  Future<WeeklyAssessment> createWeeklyAssessment(
    int userId,
    int weekNumber,
    Map<String, dynamic> speechData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> visualMotorData,
    String? notes,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/score/weekly-assessment?user_id=$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        'week_number': weekNumber,
        'speech': speechData,
        'cognitive': cognitiveData,
        'visual_motor': visualMotorData,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return WeeklyAssessment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create assessment: ${response.body}');
    }
  }

  Future<NeuroLoadScore> getNeuroLoadScore(int userId, int weekNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/score/neuro-load/$weekNumber?user_id=$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return NeuroLoadScore.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get neuro load score: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTrends(int userId, {int limit = 12}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/score/trends?user_id=$userId&limit=$limit'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get trends: ${response.body}');
    }
  }
}
