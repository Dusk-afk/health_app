import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:well_nest/services/providers/vitals_provider.dart';
import 'package:intl/intl.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Day labels for the x-axis
  List<String> dayLabels = [];

  // Tracking loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Update TabController to have 5 tabs instead of 4
    _tabController = TabController(length: 5, vsync: this);

    // Fetch data when screen initializes
    _refreshData();

    // Set up day labels
    _setupDayLabels();
  }

  // Setup day labels for the x-axis of charts
  void _setupDayLabels() {
    final now = DateTime.now();
    dayLabels = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return DateFormat('E').format(day); // Short day name (Mon, Tue, etc.)
    });
  }

  // Refresh data from the provider
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the provider without listening
      final vitalsProvider = Provider.of<VitalsProvider>(context, listen: false);
      await vitalsProvider.refreshHealthData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Vitals'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Steps'),
            Tab(text: 'Heart Rate'),
            Tab(text: 'Blood Pressure'),
            Tab(text: 'Oxygen (SPO2)'),
            Tab(text: 'Water Intake'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStepsTab(),
                _buildHeartRateTab(),
                _buildBloodPressureTab(),
                _buildSpo2Tab(),
                _buildWaterIntakeTab(),
              ],
            ),
    );
  }

  // New method to build the Steps tab
  Widget _buildStepsTab() {
    final vitalsProvider = Provider.of<VitalsProvider>(context);

    // Convert steps data to chart format
    final stepsData = _convertStepsDataToChartFormat(vitalsProvider);

    // Calculate weekly total and average
    final dailyStepsMap = vitalsProvider.dailySteps;

    // Calculate average steps per day
    int totalDaySteps = 0;
    int dayCount = 0;

    dailyStepsMap.forEach((date, steps) {
      final daysAgo = DateTime.now().difference(date).inDays;
      if (daysAgo < 7) {
        totalDaySteps += steps;
        dayCount++;
      }
    });

    final avgSteps = dayCount > 0 ? (totalDaySteps / dayCount).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Steps Count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average: $avgSteps steps/day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: stepsData.isEmpty
                ? Center(child: Text('No steps data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calculateMaxStepsY(vitalsProvider),
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = stepsData.containsKey(groupIndex) ? stepsData[groupIndex]! : 0;
                            return BarTooltipItem(
                              '${dayLabels[groupIndex]}: $value steps',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Text(dayLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                        ),
                      ),
                      barGroups: _getStepsBarGroups(stepsData, Color(0xFFA2A3F3)),
                    ),
                  ),
          ),
          // Weekly goal progress indicator removed
        ],
      ),
    );
  }

  Widget _buildHeartRateTab() {
    final vitalsProvider = Provider.of<VitalsProvider>(context);

    // Convert heart rate data to chart format
    final heartRateData = _convertHeartRateDataToChartFormat(vitalsProvider);

    // Calculate average
    final avgHeartRate = vitalsProvider.averageHeartRate.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Heart Rate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average: $avgHeartRate bpm',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: heartRateData.isEmpty
                ? Center(child: Text('No heart rate data available'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Text(dayLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: heartRateData,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 4,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.2),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: dayLabels.length - 1.0,
                      minY: _calculateMinY(heartRateData, 60),
                      maxY: _calculateMaxY(heartRateData, 100),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureTab() {
    final vitalsProvider = Provider.of<VitalsProvider>(context);

    // Convert blood pressure data to chart format
    final systolicData = _convertBloodPressureDataToChartFormat(vitalsProvider, true);
    final diastolicData = _convertBloodPressureDataToChartFormat(vitalsProvider, false);

    // Calculate averages
    final avgSystolic = vitalsProvider.averageSystolic.toStringAsFixed(0);
    final avgDiastolic = vitalsProvider.averageDiastolic.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Blood Pressure',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average: $avgSystolic/$avgDiastolic mmHg',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: (systolicData.isEmpty && diastolicData.isEmpty)
                ? Center(child: Text('No blood pressure data available'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Text(dayLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: systolicData,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        LineChartBarData(
                          spots: diastolicData,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 4,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: dayLabels.length - 1.0,
                      minY: 60,
                      maxY: 160,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  const Text('Systolic'),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  const Text('Diastolic'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpo2Tab() {
    final vitalsProvider = Provider.of<VitalsProvider>(context);

    // Get SPO2 data by day
    final Map<int, double> spo2ByDay = _getSpo2DataByDay(vitalsProvider);

    // Calculate average
    final avgSpo2 = vitalsProvider.averageSpo2.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Oxygen Saturation (SPO2)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average: $avgSpo2%',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: spo2ByDay.isEmpty
                ? Center(child: Text('No SPO2 data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      minY: 90,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = spo2ByDay[groupIndex] ?? 0;
                            return BarTooltipItem(
                              '${dayLabels[groupIndex]}: ${value.toStringAsFixed(0)}%',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Text(dayLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                        ),
                      ),
                      barGroups: _getBarGroups(spo2ByDay, Colors.purple),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeTab() {
    final vitalsProvider = Provider.of<VitalsProvider>(context);

    // Get water intake data by day
    final Map<int, int> waterByDay = _getWaterIntakeByDay(vitalsProvider);

    // Calculate average water intake
    int totalWater = 0;
    int dayCount = 0;

    waterByDay.forEach((day, amount) {
      totalWater += amount;
      dayCount++;
    });

    final avgWater = dayCount > 0 ? (totalWater / dayCount).toStringAsFixed(0) : '0';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Water Intake',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Average: $avgWater ml/day',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: waterByDay.isEmpty
                ? Center(child: Text('No water intake data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calculateMaxWaterY(waterByDay),
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = waterByDay[groupIndex] ?? 0;
                            return BarTooltipItem(
                              '${dayLabels[groupIndex]}: $value ml',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dayLabels.length) {
                                return Text(dayLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey),
                          left: BorderSide(color: Colors.grey),
                        ),
                      ),
                      barGroups: _getIntBarGroups(waterByDay, Colors.blue),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method to convert heart rate data to chart format
  List<FlSpot> _convertHeartRateDataToChartFormat(VitalsProvider provider) {
    final heartRateMap = provider.heartRate;
    final now = DateTime.now();
    final spots = <FlSpot>[];

    // Create a map to group heart rate by day
    final Map<int, List<double>> heartRatesByDay = {};

    // Initialize the map with empty lists for all 7 days
    for (int i = 0; i < 7; i++) {
      heartRatesByDay[i] = [];
    }

    // Group heart rates by day (last 7 days)
    heartRateMap.forEach((timestamp, value) {
      final daysAgo = now.difference(timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final dayIndex = 6 - daysAgo; // Convert to chart index (most recent day is last)
        heartRatesByDay[dayIndex]?.add(value);
      }
    });

    // Calculate average heart rate for each day
    heartRatesByDay.forEach((dayIndex, rates) {
      if (rates.isNotEmpty) {
        final avgRate = rates.reduce((a, b) => a + b) / rates.length;
        spots.add(FlSpot(dayIndex.toDouble(), avgRate));
      }
    });

    return spots;
  }

  // Helper method to convert blood pressure data to chart format
  List<FlSpot> _convertBloodPressureDataToChartFormat(VitalsProvider provider, bool isSystolic) {
    final bpMap = isSystolic ? provider.bloodPressureSystolic : provider.bloodPressureDiastolic;
    final now = DateTime.now();
    final spots = <FlSpot>[];

    // Create a map to group blood pressure by day
    final Map<int, List<double>> bpByDay = {};

    // Initialize the map with empty lists for all 7 days
    for (int i = 0; i < 7; i++) {
      bpByDay[i] = [];
    }

    // Group blood pressure by day (last 7 days)
    bpMap.forEach((timestamp, value) {
      final daysAgo = now.difference(timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final dayIndex = 6 - daysAgo; // Convert to chart index (most recent day is last)
        bpByDay[dayIndex]?.add(value);
      }
    });

    // Calculate average blood pressure for each day
    bpByDay.forEach((dayIndex, values) {
      if (values.isNotEmpty) {
        final avgValue = values.reduce((a, b) => a + b) / values.length;
        spots.add(FlSpot(dayIndex.toDouble(), avgValue));
      }
    });

    return spots;
  }

  // Helper method to get SPO2 data by day
  Map<int, double> _getSpo2DataByDay(VitalsProvider provider) {
    final spo2Map = provider.spo2;
    final now = DateTime.now();
    final Map<int, List<double>> spo2ByDay = {};
    final Map<int, double> avgSpo2ByDay = {};

    // Initialize the map with empty lists for all 7 days
    for (int i = 0; i < 7; i++) {
      spo2ByDay[i] = [];
    }

    // Group SPO2 readings by day
    spo2Map.forEach((timestamp, value) {
      final daysAgo = now.difference(timestamp).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final dayIndex = 6 - daysAgo; // Convert to chart index
        spo2ByDay[dayIndex]?.add(value);
      }
    });

    // Calculate average SPO2 for each day
    spo2ByDay.forEach((dayIndex, values) {
      if (values.isNotEmpty) {
        final avgValue = values.reduce((a, b) => a + b) / values.length;
        avgSpo2ByDay[dayIndex] = avgValue;
      }
    });

    return avgSpo2ByDay;
  }

  // Helper method to get water intake by day
  Map<int, int> _getWaterIntakeByDay(VitalsProvider provider) {
    final waterIntakeMap = provider.dailyWaterIntake;
    final now = DateTime.now();
    final Map<int, int> waterByDay = {};

    // Initialize map with zeros for all 7 days
    for (int i = 0; i < 7; i++) {
      waterByDay[i] = 0;
    }

    // Map water intake to chart index
    waterIntakeMap.forEach((date, amount) {
      final daysAgo = now.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final dayIndex = 6 - daysAgo; // Convert to chart index
        waterByDay[dayIndex] = amount;
      }
    });

    return waterByDay;
  }

  // Helper method to create bar groups for SPO2 chart
  List<BarChartGroupData> _getBarGroups(Map<int, double> dataByDay, Color color) {
    return dataByDay.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey[200],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Helper method to create bar groups for water intake chart
  List<BarChartGroupData> _getIntBarGroups(Map<int, int> dataByDay, Color color) {
    return dataByDay.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxWaterY(dataByDay),
              color: Colors.grey[200],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Helper method to convert steps data to chart format
  Map<int, int> _convertStepsDataToChartFormat(VitalsProvider provider) {
    final dailyStepsMap = provider.dailySteps;
    final now = DateTime.now();
    final Map<int, int> stepsByDayIndex = {};

    // Initialize map with zeros for all 7 days
    for (int i = 0; i < 7; i++) {
      stepsByDayIndex[i] = 0;
    }

    // Map step counts to chart day indices
    dailyStepsMap.forEach((date, steps) {
      final daysAgo = now.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final dayIndex = 6 - daysAgo; // Convert to chart index (most recent day is last)
        stepsByDayIndex[dayIndex] = steps;
      }
    });

    return stepsByDayIndex;
  }

  // Helper method to create bar groups for steps chart
  List<BarChartGroupData> _getStepsBarGroups(Map<int, int> dataByDay, Color color) {
    return dataByDay.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxStepsY(Provider.of<VitalsProvider>(context)),
              color: Colors.grey[200],
            ),
          ),
        ],
      );
    }).toList();
  }

  // Calculate minimum Y value for charts
  double _calculateMinY(List<FlSpot> spots, double defaultValue) {
    if (spots.isEmpty) return defaultValue;
    double minY = spots.first.y;
    for (var spot in spots) {
      if (spot.y < minY) minY = spot.y;
    }
    return (minY * 0.9).floorToDouble(); // Add 10% margin below
  }

  // Calculate maximum Y value for charts
  double _calculateMaxY(List<FlSpot> spots, double defaultValue) {
    if (spots.isEmpty) return defaultValue;
    double maxY = spots.first.y;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    return (maxY * 1.1).ceilToDouble(); // Add 10% margin above
  }

  // Calculate maximum Y value for water intake chart
  double _calculateMaxWaterY(Map<int, int> waterByDay) {
    int maxValue = 0;
    waterByDay.forEach((day, amount) {
      if (amount > maxValue) maxValue = amount;
    });

    // If there's no data or maximum is too small, use 3000 as default
    if (maxValue < 1000) {
      return 3000;
    }

    // Round up to nearest 500
    return (((maxValue * 1.1) / 500).ceil() * 500).toDouble();
  }

  // Calculate maximum Y value for steps chart
  double _calculateMaxStepsY(VitalsProvider provider) {
    final dailyStepsMap = provider.dailySteps;
    int maxValue = 0;

    dailyStepsMap.forEach((date, steps) {
      if (steps > maxValue) maxValue = steps;
    });

    // If there's no data or maximum is too small, use 10000 as default
    if (maxValue < 1000) {
      return 10000;
    }

    // Round up to nearest 1000
    return (((maxValue * 1.1) / 1000).ceil() * 1000).toDouble();
  }
}
