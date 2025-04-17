import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String? userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting text
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF9AD7D8), Color(0xFFA2A3F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 22,
                      child: Icon(
                        Icons.account_circle,
                        size: 44,
                        color: Color(0xFF9AD7D8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${userName ?? 'User'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFD0D1FF).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color(0xFFA2A3F3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Health Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'Health Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable row of health stat cards - no horizontal padding to avoid cutoff
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildHealthCard(
                    context,
                    'Breath Rate',
                    '16',
                    'breaths/min',
                    Icons.air,
                    Color(0xFFD0D1FF),
                    Color(0xFFA2A3F3),
                  ),
                  _buildHealthCard(
                    context,
                    'Heart Rate',
                    '72',
                    'bpm',
                    Icons.favorite,
                    Color(0xFFC9EBED),
                    Color(0xFF9AD7D8),
                  ),
                  _buildHealthCard(
                    context,
                    'Blood Pressure',
                    '120/80',
                    'mmHg',
                    Icons.opacity,
                    Color(0xFFF3DFDE),
                    Color(0xFFECC2C0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Planner section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'Today\'s Planner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Medicine plans for different times
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTimeBasedMedicinePlan(context),
            ),

            const SizedBox(height: 16),

            // Today's appointments
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildTodayAppointments(context),
            ),

            // Add bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color bgColor,
    Color bgColor2,
  ) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with icon and right arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
          Spacer(),
          // Title text
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Value with unit
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New method for medicine plans organized by time
  Widget _buildTimeBasedMedicinePlan(BuildContext context) {
    return Column(
      children: [
        _buildMedicineTimeSection(context, 'Morning', [
          _MedicineItem('Vitamin D', '1 tablet', '8:00 AM', Colors.amber),
          // _MedicineItem('Levothyroxine', '1 tablet', '8:00 AM', Colors.lightBlue),
        ]),
        const SizedBox(height: 12),
        // _buildMedicineTimeSection(context, 'Afternoon', [
        //   _MedicineItem('Metformin', '1 tablet', '1:00 PM', Colors.orange),
        // ]),
        // const SizedBox(height: 12),
        _buildMedicineTimeSection(context, 'Evening', [
          _MedicineItem('Multivitamin', '1 tablet', '8:00 PM', Colors.green),
          // _MedicineItem('Atorvastatin', '1 tablet', '9:00 PM', Colors.purple),
        ]),
      ],
    );
  }

  Widget _buildMedicineTimeSection(BuildContext context, String timeOfDay, List<_MedicineItem> medicines) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                timeOfDay == 'Morning' ? Icons.wb_sunny : (timeOfDay == 'Afternoon' ? Icons.wb_twilight : Icons.nightlight),
                color: timeOfDay == 'Morning' ? Colors.orange : (timeOfDay == 'Afternoon' ? Colors.amber : Colors.indigo),
              ),
              const SizedBox(width: 8),
              Text(
                timeOfDay,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: medicines.map((medicine) => _buildMedicineItem(context, medicine)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(BuildContext context, _MedicineItem medicine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: medicine.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                '${medicine.dosage} - ${medicine.time}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Checkbox(
            value: false,
            onChanged: (value) {
              // TODO: Implement medicine taken functionality
            },
          ),
        ],
      ),
    );
  }

  // Widget for today's appointments
  Widget _buildTodayAppointments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all appointments view
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAppointmentItem(
          context,
          'Dr. Sarah Johnson',
          'Cardiology Checkup',
          '3:30 PM - 4:15 PM',
          Icons.favorite,
          Colors.redAccent,
        ),
        const SizedBox(height: 12),
        _buildAppointmentItem(
          context,
          'Lab Test',
          'Blood Work',
          '5:00 PM - 5:30 PM',
          Icons.science,
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildAppointmentItem(
    BuildContext context,
    String doctorName,
    String purpose,
    String timeSlot,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purpose,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeSlot,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for medicine items
class _MedicineItem {
  final String name;
  final String dosage;
  final String time;
  final Color color;

  _MedicineItem(this.name, this.dosage, this.time, this.color);
}
