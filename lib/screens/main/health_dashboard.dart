import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../../services/api/health_service.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({Key? key}) : super(key: key);

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final HealthService _healthService = HealthService.instance;
  List<HealthDataPoint> _healthData = [];
  int? _steps;
  double? _heartRate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeHealthData();
  }

  Future<void> _initializeHealthData() async {
    // Start periodic fetching every 15 minutes
    _healthService.startPeriodicFetch(interval: const Duration(minutes: 15));

    // Load initial data
    await _refreshHealthData();

    // Listen for health data updates
    _healthService.healthDataStream.listen((data) {
      if (mounted) {
        _processHealthData(data);
      }
    });
  }

  Future<void> _refreshHealthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch health data
      final healthData = await _healthService.fetchHealthData();

      // Get today's step count
      final steps = await _healthService.getTotalStepsToday();

      if (mounted) {
        _processHealthData(healthData);
        setState(() {
          _steps = steps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing health data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _processHealthData(List<HealthDataPoint> data) {
    setState(() {
      _healthData = data;

      // Process heart rate data
      final heartRateData = data.where((p) => p.type == HealthDataType.HEART_RATE).toList();
      if (heartRateData.isNotEmpty) {
        // Get the most recent heart rate
        final latestHeartRate = heartRateData.reduce((a, b) => a.dateFrom.isAfter(b.dateFrom) ? a : b);

        _heartRate = (latestHeartRate.value as NumericHealthValue).numericValue.toDouble();
      }
    });
  }

  @override
  void dispose() {
    _healthService.stopPeriodicFetch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshHealthData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildHealthDataList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricCard(
              icon: Icons.directions_walk,
              title: 'Steps',
              value: _steps != null ? _steps.toString() : 'No data',
              color: Colors.blue,
            ),
            _buildMetricCard(
              icon: Icons.favorite,
              title: 'Heart Rate',
              value: _heartRate != null ? '${_heartRate!.toStringAsFixed(0)} bpm' : 'No data',
              color: Colors.red,
            ),
          ],
        ),
        if (_steps != null) ...[
          const SizedBox(height: 24),
          _buildStepsChart(),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Steps Goal Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _steps != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(
                            value: _steps!.toDouble(),
                            color: Colors.blue,
                            radius: 20,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: (_steps! < 10000) ? 10000 - _steps!.toDouble() : 0,
                            color: Colors.blue.withOpacity(0.2),
                            radius: 20,
                            title: '',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _steps.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'of 10,000 steps',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(
                  child: Text('No step data available'),
                ),
        ),
      ],
    );
  }

  Widget _buildHealthDataList() {
    if (_healthData.isEmpty) {
      return const Center(
        child: Text(
          'No health data available',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Group health data by type
    final groupedData = <HealthDataType, List<HealthDataPoint>>{};
    for (final point in _healthData) {
      if (!groupedData.containsKey(point.type)) {
        groupedData[point.type] = [];
      }
      groupedData[point.type]!.add(point);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Health Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...groupedData.entries.map((entry) {
          return _buildHealthDataTypeCard(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildHealthDataTypeCard(HealthDataType type, List<HealthDataPoint> points) {
    final latestPoint = points.reduce((a, b) => a.dateFrom.isAfter(b.dateFrom) ? a : b);
    final value = latestPoint.value;

    String displayValue = 'N/A';
    if (value is NumericHealthValue) {
      displayValue = '${value.numericValue.toStringAsFixed(1)} ${latestPoint.unit.name}';
    } else if (value is WorkoutHealthValue) {
      displayValue = '${value.workoutActivityType.name} (${value.totalEnergyBurned} kcal)';
    } else if (value is AudiogramHealthValue) {
      displayValue = 'Audiogram data available';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          _healthDataTypeToString(type),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Last updated: ${_formatDateTime(latestPoint.dateFrom)}\n$displayValue',
        ),
        isThreeLine: true,
        leading: Icon(
          _getIconForHealthDataType(type),
          color: Theme.of(context).primaryColor,
          size: 32,
        ),
      ),
    );
  }

  IconData _getIconForHealthDataType(HealthDataType type) {
    switch (type) {
      case HealthDataType.STEPS:
        return Icons.directions_walk;
      case HealthDataType.HEART_RATE:
        return Icons.favorite;
      case HealthDataType.BLOOD_GLUCOSE:
        return Icons.opacity;
      case HealthDataType.BLOOD_OXYGEN:
        return Icons.air;
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return Icons.monitor_heart;
      case HealthDataType.BODY_MASS_INDEX:
      case HealthDataType.WEIGHT:
        return Icons.monitor_weight;
      case HealthDataType.HEIGHT:
        return Icons.height;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return Icons.local_fire_department;
      case HealthDataType.BODY_TEMPERATURE:
        return Icons.thermostat;
      case HealthDataType.DISTANCE_WALKING_RUNNING:
        return Icons.directions_run;
      case HealthDataType.SLEEP_IN_BED:
      case HealthDataType.SLEEP_ASLEEP:
        return Icons.bedtime;
      case HealthDataType.WATER:
        return Icons.water_drop;
      case HealthDataType.WORKOUT:
        return Icons.fitness_center;
      default:
        return Icons.health_and_safety;
    }
  }

  String _healthDataTypeToString(HealthDataType type) {
    return type.name.split('_').map((word) => word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
