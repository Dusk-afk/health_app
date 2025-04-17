import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

/// A service class to interact with the Health API (Health Connect on Android and HealthKit on iOS)
/// This service fetches health data at regular intervals and provides access to it
/// through methods and streams, without any UI components.
class HealthService {
  static final HealthService instance = HealthService._internal();

  HealthService._internal();

  // Health plugin instance
  final Health _health = Health();

  // Available data types to fetch
  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
    HealthDataType.WORKOUT,
  ];

  Timer? _dataFetchTimer;
  bool _isInitialized = false;

  // Stream controllers for real-time data updates
  final _healthDataController = StreamController<List<HealthDataPoint>>.broadcast();

  /// Stream providing access to health data updates
  Stream<List<HealthDataPoint>> get healthDataStream => _healthDataController.stream;

  /// Initialize the health service and request necessary permissions
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Configure the health plugin
      await _health.configure();

      // Request authorization for the health data types
      final requested = await _health.requestAuthorization(_types);

      if (requested) {
        _isInitialized = true;
        debugPrint('Health service initialized successfully');
      } else {
        debugPrint('Failed to get authorization for health data');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing health service: $e');
      return false;
    }
  }

  /// Start fetching health data at regular intervals
  void startPeriodicFetch({Duration interval = const Duration(minutes: 30)}) {
    if (!_isInitialized) {
      debugPrint('Health service is not initialized. Call initialize() first.');
      return;
    }

    // Cancel any existing timer
    _dataFetchTimer?.cancel();

    // Fetch immediately
    fetchHealthData();

    // Set up periodic fetch
    _dataFetchTimer = Timer.periodic(interval, (_) {
      fetchHealthData();
    });

    debugPrint('Started periodic health data fetch with interval: ${interval.inMinutes} minutes');
  }

  /// Stop periodic fetch of health data
  void stopPeriodicFetch() {
    _dataFetchTimer?.cancel();
    _dataFetchTimer = null;
    debugPrint('Stopped periodic health data fetch');
  }

  /// Fetch health data
  Future<List<HealthDataPoint>> fetchHealthData() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get current time
      final now = DateTime.now();
      // Get time 24 hours ago
      final from = now.subtract(const Duration(days: 8));

      // Fetch health data
      final healthData = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: from,
        endTime: now,
      );

      // Remove duplicates
      final uniqueHealthData = _health.removeDuplicates(healthData);

      // Log the data fetch
      debugPrint('Fetched ${uniqueHealthData.length} health data points at ${_formatDateTime(now)}');

      // Add data to stream for real-time updates
      _healthDataController.add(uniqueHealthData);

      return uniqueHealthData;
    } catch (e) {
      debugPrint('Error fetching health data: $e');
      return [];
    }
  }

  /// Get total steps in a specific time interval
  Future<int?> getTotalStepsInInterval(DateTime startTime, DateTime endTime) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _health.getTotalStepsInInterval(startTime, endTime);
    } catch (e) {
      debugPrint('Error getting total steps: $e');
      return null;
    }
  }

  /// Get total steps for today
  Future<int?> getTotalStepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return getTotalStepsInInterval(midnight, now);
  }

  /// Get all available health data types
  List<HealthDataType> get availableTypes => List.unmodifiable(_types);

  /// Format date time for logging
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Get health data points by type
  List<HealthDataPoint> getDataByType(List<HealthDataPoint> allData, HealthDataType type) {
    return allData.where((point) => point.type == type).toList();
  }

  /// Dispose of resources
  void dispose() {
    stopPeriodicFetch();
    _healthDataController.close();
  }
}
