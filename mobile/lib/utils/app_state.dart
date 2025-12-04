import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/assessment.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<TrendData> _trends = [];
  NeuroLoadScore? _latestScore;
  bool _hasBaseline = false;
  int _currentWeek = 1;

  User? get currentUser => _currentUser;
  List<TrendData> get trends => _trends;
  NeuroLoadScore? get latestScore => _latestScore;
  bool get hasBaseline => _hasBaseline;
  int get currentWeek => _currentWeek;

  final ApiService _apiService = ApiService();

  AppState() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('token');

    if (userJson != null && token != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      _apiService.setToken(token);
      await checkBaseline();
      await loadTrends();
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _currentUser = User.fromJson({
        ...response['user'],
        'token': response['access_token'],
      });

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(response['user']));
      await prefs.setString('token', response['access_token']);

      _apiService.setToken(response['access_token']);

      await checkBaseline();
      await loadTrends();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final user = await _apiService.register(username, email, password);
      // After registration, log in
      await login(username, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _trends = [];
    _latestScore = null;
    _hasBaseline = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> checkBaseline() async {
    if (_currentUser == null) return;

    try {
      await _apiService.getActiveBaseline(_currentUser!.id);
      _hasBaseline = true;
    } catch (e) {
      _hasBaseline = false;
    }
    notifyListeners();
  }

  Future<void> loadTrends() async {
    if (_currentUser == null) return;

    try {
      final response = await _apiService.getTrends(_currentUser!.id);
      final trendsJson = response['trends'] as List;
      _trends = trendsJson.map((t) => TrendData.fromJson(t)).toList();

      if (_trends.isNotEmpty) {
        _currentWeek = _trends.last.week + 1;
        _latestScore = NeuroLoadScore(
          neuroLoadScore: _trends.last.neuroLoadScore,
          speechDriftScore: _trends.last.speechDrift,
          cognitiveDriftScore: _trends.last.cognitiveDrift,
          visualMotorDriftScore: _trends.last.visualMotorDrift,
          status: _trends.last.neuroLoadScore < 15
              ? 'stable'
              : _trends.last.neuroLoadScore < 30
                  ? 'minor_change'
                  : 'significant_change',
          insights: [],
          weekNumber: _trends.last.week,
        );
      }

      notifyListeners();
    } catch (e) {
      // No trends yet
      _trends = [];
      _currentWeek = 1;
    }
  }

  Future<void> createBaseline(
    Map<String, dynamic> speechData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> visualMotorData,
  ) async {
    if (_currentUser == null) return;

    await _apiService.createBaseline(
      _currentUser!.id,
      speechData,
      cognitiveData,
      visualMotorData,
    );

    _hasBaseline = true;
    notifyListeners();
  }

  Future<WeeklyAssessment> createWeeklyAssessment(
    Map<String, dynamic> speechData,
    Map<String, dynamic> cognitiveData,
    Map<String, dynamic> visualMotorData,
    String? notes,
  ) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    final assessment = await _apiService.createWeeklyAssessment(
      _currentUser!.id,
      _currentWeek,
      speechData,
      cognitiveData,
      visualMotorData,
      notes,
    );

    // Reload trends
    await loadTrends();

    return assessment;
  }
}
