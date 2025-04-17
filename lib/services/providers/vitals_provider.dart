import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../../services/api/health_service.dart';

class VitalsProvider extends ChangeNotifier {
  // Singleton instance
  static final VitalsProvider instance = VitalsProvider._internal();

  VitalsProvider._internal() {
    _initializeHealthConnection();
  }

  // Reference to the health service
  final HealthService _healthService = HealthService.instance;

  // Stream subscription for health data updates
  StreamSubscription<List<HealthDataPoint>>? _healthDataSubscription;

  // State for storing health data by type and timestamp
  final Map<HealthDataType, SplayTreeMap<DateTime, dynamic>> _healthDataByType = {
    HealthDataType.STEPS: SplayTreeMap<DateTime, int>(),
    HealthDataType.HEART_RATE: SplayTreeMap<DateTime, double>(),
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC: SplayTreeMap<DateTime, double>(),
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC: SplayTreeMap<DateTime, double>(),
    HealthDataType.BLOOD_OXYGEN: SplayTreeMap<DateTime, double>(),
  };

  // New: Maps for storing daily totals
  final Map<DateTime, int> _dailySteps = {};
  final Map<DateTime, double> _dailyCaloriesBurned = {};
  final Map<DateTime, double> _dailyDistanceWalked = {};
  final Map<DateTime, int> _dailyActiveMinutes = {};
  final Map<DateTime, int> _dailyWaterIntake = {};

  // Getters for the daily maps
  UnmodifiableMapView<DateTime, int> get dailySteps => UnmodifiableMapView(_dailySteps);
  UnmodifiableMapView<DateTime, double> get dailyCaloriesBurned => UnmodifiableMapView(_dailyCaloriesBurned);
  UnmodifiableMapView<DateTime, double> get dailyDistanceWalked => UnmodifiableMapView(_dailyDistanceWalked);
  UnmodifiableMapView<DateTime, int> get dailyActiveMinutes => UnmodifiableMapView(_dailyActiveMinutes);
  UnmodifiableMapView<DateTime, int> get dailyWaterIntake => UnmodifiableMapView(_dailyWaterIntake);

  // Getters for each health data type
  UnmodifiableMapView<DateTime, int> get steps =>
      UnmodifiableMapView(_healthDataByType[HealthDataType.STEPS] as SplayTreeMap<DateTime, int>);

  UnmodifiableMapView<DateTime, double> get heartRate =>
      UnmodifiableMapView(_healthDataByType[HealthDataType.HEART_RATE] as SplayTreeMap<DateTime, double>);

  UnmodifiableMapView<DateTime, double> get bloodPressureSystolic =>
      UnmodifiableMapView(_healthDataByType[HealthDataType.BLOOD_PRESSURE_SYSTOLIC] as SplayTreeMap<DateTime, double>);

  UnmodifiableMapView<DateTime, double> get bloodPressureDiastolic =>
      UnmodifiableMapView(_healthDataByType[HealthDataType.BLOOD_PRESSURE_DIASTOLIC] as SplayTreeMap<DateTime, double>);

  UnmodifiableMapView<DateTime, double> get spo2 =>
      UnmodifiableMapView(_healthDataByType[HealthDataType.BLOOD_OXYGEN] as SplayTreeMap<DateTime, double>);

  // Recent averages (last minute)
  int _averageSteps = 0;
  double _averageHeartRate = 0.0;
  double _averageSystolic = 0.0;
  double _averageDiastolic = 0.0;
  double _averageSpo2 = 0.0;

  // Getters for averages
  int get averageSteps => _averageSteps;
  double get averageHeartRate => _averageHeartRate;
  double get averageSystolic => _averageSystolic;
  double get averageDiastolic => _averageDiastolic;
  double get averageSpo2 => _averageSpo2;

  // Latest values
  int _latestSteps = 0;
  double _latestHeartRate = 0.0;
  double _latestSystolic = 0.0;
  double _latestDiastolic = 0.0;
  double _latestSpo2 = 0.0;

  // Getters for latest values
  int get latestSteps => _latestSteps;
  double get latestHeartRate => _latestHeartRate;
  double get latestSystolic => _latestSystolic;
  double get latestDiastolic => _latestDiastolic;
  double get latestSpo2 => _latestSpo2;

  // Keep total values for today's quick access
  int _totalSteps = 0;
  double _totalCaloriesBurned = 0.0;
  double _totalDistanceWalked = 0.0;
  int _totalActiveMinutes = 0;
  int _totalWaterIntake = 0; // in ml

  // Getters for today's total values
  int get totalSteps => _totalSteps;
  double get totalCaloriesBurned => _totalCaloriesBurned;
  double get totalDistanceWalked => _totalDistanceWalked;
  int get totalActiveMinutes => _totalActiveMinutes;
  int get totalWaterIntake => _totalWaterIntake;

  // Initialize connection to health service
  Future<void> _initializeHealthConnection() async {
    // Initialize health service if not already done
    final initialized = await _healthService.initialize();

    if (!initialized) {
      debugPrint('Failed to initialize health service in vitals provider');
      return;
    }

    // Subscribe to health data updates
    _healthDataSubscription = _healthService.healthDataStream.listen(_processHealthData);

    // Start periodic fetch if not already started
    _healthService.startPeriodicFetch(interval: const Duration(minutes: 1));

    // Initial fetch
    final initialData = await _healthService.fetchHealthData();
    _processHealthData(initialData);
  }

  // Process incoming health data
  void _processHealthData(List<HealthDataPoint> dataPoints) {
    if (dataPoints.isEmpty) return;

    // Group data points by day for aggregation
    final Map<DateTime, List<HealthDataPoint>> dataPointsByDay = {};

    // Process each data point and store in appropriate maps
    for (final point in dataPoints) {
      if (point.value is NumericHealthValue) {
        final value = (point.value as NumericHealthValue).numericValue;
        final timestamp = point.dateFrom;

        // Get the date part only (year, month, day) to group by day
        final dateKey = DateTime(timestamp.year, timestamp.month, timestamp.day);

        // Add to day grouped collection
        if (!dataPointsByDay.containsKey(dateKey)) {
          dataPointsByDay[dateKey] = [];
        }
        dataPointsByDay[dateKey]!.add(point);

        switch (point.type) {
          case HealthDataType.STEPS:
            (_healthDataByType[HealthDataType.STEPS] as SplayTreeMap<DateTime, int>)[timestamp] = value.toInt();
            break;
          case HealthDataType.HEART_RATE:
            (_healthDataByType[HealthDataType.HEART_RATE] as SplayTreeMap<DateTime, double>)[timestamp] = value.toDouble();
            break;
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
            (_healthDataByType[HealthDataType.BLOOD_PRESSURE_SYSTOLIC] as SplayTreeMap<DateTime, double>)[timestamp] =
                value.toDouble();
            break;
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
            (_healthDataByType[HealthDataType.BLOOD_PRESSURE_DIASTOLIC] as SplayTreeMap<DateTime, double>)[timestamp] =
                value.toDouble();
            break;
          case HealthDataType.BLOOD_OXYGEN:
            (_healthDataByType[HealthDataType.BLOOD_OXYGEN] as SplayTreeMap<DateTime, double>)[timestamp] = value.toDouble();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            // We'll process aggregated values later
            break;
          case HealthDataType.DISTANCE_WALKING_RUNNING:
            // We'll process aggregated values later
            break;
          case HealthDataType.WATER:
            // We'll process aggregated values later
            break;
          default:
            // Ignore other types for now
            break;
        }
      }
    }

    // Now process the grouped data for daily statistics
    dataPointsByDay.forEach((day, points) {
      _processDataForDay(day, points);
    });

    // Update latest values and calculate averages
    _updateLatestValues();
    _calculateAverages();

    // Set today's totals for quick access
    _setTodayTotals();

    // Notify listeners about the updates
    notifyListeners();
  }

  // New method to process data for a specific day
  void _processDataForDay(DateTime day, List<HealthDataPoint> points) {
    int steps = 0;
    double calories = 0.0;
    double distance = 0.0;
    int activeMinutes = 0;
    int waterIntake = 0;

    // Count active minutes based on heart rate
    final List<double> heartRateValues = [];

    for (final point in points) {
      if (point.value is NumericHealthValue) {
        final value = (point.value as NumericHealthValue).numericValue;

        switch (point.type) {
          case HealthDataType.STEPS:
            steps += value.toInt();
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            calories += value.toDouble();
            break;
          case HealthDataType.DISTANCE_WALKING_RUNNING:
            distance += value.toDouble();
            break;
          case HealthDataType.WATER:
            waterIntake += value.toInt();
            break;
          case HealthDataType.HEART_RATE:
            heartRateValues.add(value.toDouble());
            break;
          default:
            // Ignore other types
            break;
        }
      }
    }

    // Calculate active minutes based on elevated heart rate
    // Simply counting readings where heart rate was above threshold
    activeMinutes = heartRateValues.where((hr) => hr > 80).length;

    // Update daily maps
    _dailySteps[day] = steps;
    _dailyCaloriesBurned[day] = calories;
    _dailyDistanceWalked[day] = distance;
    _dailyActiveMinutes[day] = activeMinutes;
    _dailyWaterIntake[day] = waterIntake;
  }

  // Set today's totals for quick access
  void _setTodayTotals() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    _totalSteps = _dailySteps[today] ?? 0;
    _totalCaloriesBurned = _dailyCaloriesBurned[today] ?? 0.0;
    _totalDistanceWalked = _dailyDistanceWalked[today] ?? 0.0;
    _totalActiveMinutes = _dailyActiveMinutes[today] ?? 0;
    _totalWaterIntake = _dailyWaterIntake[today] ?? 0;
  }

  // Update the latest value for each vital
  void _updateLatestValues() {
    final stepsMap = _healthDataByType[HealthDataType.STEPS] as SplayTreeMap<DateTime, int>;
    if (stepsMap.isNotEmpty) {
      _latestSteps = stepsMap.values.last;
    }

    final heartRateMap = _healthDataByType[HealthDataType.HEART_RATE] as SplayTreeMap<DateTime, double>;
    if (heartRateMap.isNotEmpty) {
      _latestHeartRate = heartRateMap.values.last;
    }

    final systolicMap = _healthDataByType[HealthDataType.BLOOD_PRESSURE_SYSTOLIC] as SplayTreeMap<DateTime, double>;
    if (systolicMap.isNotEmpty) {
      _latestSystolic = systolicMap.values.last;
    }

    final diastolicMap = _healthDataByType[HealthDataType.BLOOD_PRESSURE_DIASTOLIC] as SplayTreeMap<DateTime, double>;
    if (diastolicMap.isNotEmpty) {
      _latestDiastolic = diastolicMap.values.last;
    }

    final spo2Map = _healthDataByType[HealthDataType.BLOOD_OXYGEN] as SplayTreeMap<DateTime, double>;
    if (spo2Map.isNotEmpty) {
      _latestSpo2 = spo2Map.values.last;
    }
  }

  // Calculate averages for the last minute
  void _calculateAverages() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Calculate average steps
    final recentSteps =
        _getRecentDataPoints<int>(_healthDataByType[HealthDataType.STEPS] as SplayTreeMap<DateTime, int>, oneMinuteAgo);
    _averageSteps = recentSteps.isEmpty ? 0 : recentSteps.reduce((a, b) => a + b) ~/ recentSteps.length;

    // Calculate average heart rate
    final recentHeartRate = _getRecentDataPoints<double>(
        _healthDataByType[HealthDataType.HEART_RATE] as SplayTreeMap<DateTime, double>, oneMinuteAgo);
    _averageHeartRate = recentHeartRate.isEmpty ? 0.0 : recentHeartRate.reduce((a, b) => a + b) / recentHeartRate.length;

    // Calculate average blood pressure (systolic)
    final recentSystolic = _getRecentDataPoints<double>(
        _healthDataByType[HealthDataType.BLOOD_PRESSURE_SYSTOLIC] as SplayTreeMap<DateTime, double>, oneMinuteAgo);
    _averageSystolic = recentSystolic.isEmpty ? 0.0 : recentSystolic.reduce((a, b) => a + b) / recentSystolic.length;

    // Calculate average blood pressure (diastolic)
    final recentDiastolic = _getRecentDataPoints<double>(
        _healthDataByType[HealthDataType.BLOOD_PRESSURE_DIASTOLIC] as SplayTreeMap<DateTime, double>, oneMinuteAgo);
    _averageDiastolic = recentDiastolic.isEmpty ? 0.0 : recentDiastolic.reduce((a, b) => a + b) / recentDiastolic.length;

    // Calculate average SpO2
    final recentSpo2 = _getRecentDataPoints<double>(
        _healthDataByType[HealthDataType.BLOOD_OXYGEN] as SplayTreeMap<DateTime, double>, oneMinuteAgo);
    _averageSpo2 = recentSpo2.isEmpty ? 0.0 : recentSpo2.reduce((a, b) => a + b) / recentSpo2.length;
  }

  // Helper method to get recent data points
  List<T> _getRecentDataPoints<T>(SplayTreeMap<DateTime, T> map, DateTime since) {
    final filteredEntries = map.entries.where((entry) => entry.key.isAfter(since)).toList();
    return filteredEntries.map((entry) => entry.value).toList();
  }

  // Force a manual refresh of health data
  Future<void> refreshHealthData() async {
    final freshData = await _healthService.fetchHealthData();
    _processHealthData(freshData);
  }

  // Get total steps for a specific date
  Future<int> getTotalStepsForDate(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);

    // Check if we already have the data
    if (_dailySteps.containsKey(dateKey)) {
      return _dailySteps[dateKey] ?? 0;
    }

    // If not, fetch from health service
    final startOfDay = dateKey;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final steps = await _healthService.getTotalStepsInInterval(startOfDay, endOfDay);

    // Store the result for future use
    if (steps != null) {
      _dailySteps[dateKey] = steps;
      notifyListeners();
    }

    return steps ?? 0;
  }

  // Get total steps for current week
  Future<int> getTotalStepsForWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    int totalSteps = 0;

    // Try to use cached daily values first
    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      // Don't go beyond today
      if (day.isAfter(now)) break;

      totalSteps += await getTotalStepsForDate(day);
    }

    return totalSteps;
  }

  // Get weekly data as a map for charts
  Map<DateTime, int> getWeeklySteps() {
    final now = DateTime.now();
    final Map<DateTime, int> weeklyData = {};

    // Get the start of the current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Collect data for the week
    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      weeklyData[day] = _dailySteps[day] ?? 0;
    }

    return weeklyData;
  }

  // Get weekly calories burned
  Map<DateTime, double> getWeeklyCalories() {
    final now = DateTime.now();
    final Map<DateTime, double> weeklyData = {};

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      weeklyData[day] = _dailyCaloriesBurned[day] ?? 0.0;
    }

    return weeklyData;
  }

  // Clean up resources
  @override
  void dispose() {
    _healthDataSubscription?.cancel();
    super.dispose();
  }
}
