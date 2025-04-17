import 'package:flutter/material.dart';

class MemberScreen extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const MemberScreen({
    Key? key,
    required this.memberData,
  }) : super(key: key);

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> _memberDetails = {
    'illnesses': [
      {
        'name': 'Common Cold',
        'date': '22 Jan 2025',
        'status': 'Recovered',
        'color': Colors.green,
      },
      {
        'name': 'Seasonal Allergy',
        'date': '10 Mar 2025',
        'status': 'Active',
        'color': Colors.amber,
      },
    ],
    'documents': [
      {
        'title': 'Blood Test Report',
        'date': '22 Jan 2025',
        'type': 'PDF',
        'icon': Icons.picture_as_pdf,
      },
      {
        'title': 'X-Ray Report',
        'date': '15 Feb 2025',
        'type': 'Image',
        'icon': Icons.image,
      },
      {
        'title': 'Medical Certificate',
        'date': '10 Mar 2025',
        'type': 'PDF',
        'icon': Icons.picture_as_pdf,
      },
    ],
    'doctors': [
      {
        'name': 'Dr. Rahul Sharma',
        'speciality': 'General Physician',
        'lastVisit': '22 Jan 2025',
        'avatar': Icons.person,
      },
      {
        'name': 'Dr. Meera Patel',
        'speciality': 'ENT Specialist',
        'lastVisit': '15 Feb 2025',
        'avatar': Icons.person,
      },
    ],
    'history': [
      {
        'title': 'Consulted Dr. Rahul Sharma',
        'date': '22 Jan 2025',
        'description': 'For common cold and fever',
        'icon': Icons.medical_services,
        'color': Colors.blue,
      },
      {
        'title': 'Blood Test',
        'date': '22 Jan 2025',
        'description': 'Complete blood count',
        'icon': Icons.science,
        'color': Colors.red,
      },
      {
        'title': 'Consulted Dr. Meera Patel',
        'date': '15 Feb 2025',
        'description': 'For persistent cold',
        'icon': Icons.medical_services,
        'color': Colors.blue,
      },
      {
        'title': 'X-Ray',
        'date': '15 Feb 2025',
        'description': 'Chest X-Ray',
        'icon': Icons.image,
        'color': Colors.purple,
      },
    ],
  };

  final Map<String, Map<String, dynamic>> _vitals = {
    'heart_rate': {
      'title': 'Heart Rate',
      'value': '72',
      'unit': 'bpm',
      'icon': Icons.favorite,
      'color': Color(0xFF9AD7D8),
      'bgColor': Color(0xFFC9EBED),
      'history': [72, 75, 70, 76, 71, 73, 72],
    },
    'blood_pressure': {
      'title': 'Blood Pressure',
      'value': '120/80',
      'unit': 'mmHg',
      'icon': Icons.opacity,
      'color': Color(0xFFECC2C0),
      'bgColor': Color(0xFFF3DFDE),
      'history': [120, 122, 118, 121, 119, 120, 120],
    },
    'temperature': {
      'title': 'Temperature',
      'value': '98.6',
      'unit': '°F',
      'icon': Icons.thermostat,
      'color': Color(0xFFA2A3F3),
      'bgColor': Color(0xFFD0D1FF),
      'history': [98.6, 98.4, 98.7, 98.5, 98.6, 98.6, 98.5],
    },
    'blood_sugar': {
      'title': 'Blood Sugar',
      'value': '110',
      'unit': 'mg/dL',
      'icon': Icons.water_drop,
      'color': Color(0xFF7BBEEB),
      'bgColor': Color(0xFFCEE7F8),
      'history': [110, 108, 115, 112, 109, 111, 110],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false, // Only apply SafeArea to the top
        child: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return <Widget>[
                // App bar with back button and edit action
                SliverAppBar(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF9AD7D8)),
                      onPressed: () {
                        // TODO: Implement edit functionality
                      },
                    ),
                  ],
                  floating: true,
                  pinned: false,
                ),

                // Profile summary section
                SliverToBoxAdapter(
                  child: _buildProfileSummary(),
                ),

                // Tab bar that will stick to the top
                SliverPersistentHeader(
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF9AD7D8),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF9AD7D8),
                      tabs: const [
                        Tab(text: 'Vitals'),
                        Tab(text: 'History'),
                        Tab(text: 'Documents'),
                        Tab(text: 'Doctors'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildVitalsTab(),
                _buildHistoryTab(),
                _buildDocumentsTab(),
                _buildDoctorsTab(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new record functionality
        },
        backgroundColor: const Color(0xFFA2A3F3),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileSummary() {
    // Get gender from member data with a default value
    final String gender = widget.memberData['gender'] ?? 'prefer_not_to_say';

    // Define colors based on gender (blue for male/prefer not to say, purple for female)
    final Map<String, List<Color>> genderColors = {
      'male': [
        const Color(0xFF9AD7D8), // Light blue for avatar border
        const Color(0xFFC9EBED), // Light blue bg
      ],
      'female': [
        const Color(0xFFA2A3F3), // Purple for avatar border
        const Color(0xFFD0D1FF), // Purple bg
      ],
      'prefer_not_to_say': [
        const Color(0xFF9AD7D8), // Same as male - light blue
        const Color(0xFFC9EBED), // Light blue bg
      ],
    };

    // Select the appropriate colors based on gender
    final List<Color> colors = genderColors[gender] ?? genderColors['prefer_not_to_say']!;
    final Color avatarColor = colors[0];
    final Color bgColor = colors[1];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avatarColor, avatarColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: bgColor,
              radius: 50,
              child: Icon(
                widget.memberData['avatar'],
                size: 60,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.memberData['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.memberData['relation'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Age: ${widget.memberData['age']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Illnesses', _memberDetails['illnesses']?.length ?? 0, avatarColor),
              _buildQuickStat('Documents', _memberDetails['documents']?.length ?? 0, avatarColor),
              _buildQuickStat('Doctors', _memberDetails['doctors']?.length ?? 0, avatarColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String title, int count, Color accentColor) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Vitals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid of vital cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _vitals.length,
            itemBuilder: (context, index) {
              final vital = _vitals.values.toList()[index];
              return _buildVitalCard(
                vital['title'],
                vital['value'],
                vital['unit'],
                vital['icon'],
                vital['bgColor'],
                vital['color'],
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Health Conditions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Current illnesses
          ...(_memberDetails['illnesses'] ?? [])
              .map((illness) => _buildIllnessCard(
                    illness['name'],
                    illness['date'],
                    illness['status'],
                    illness['color'],
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildVitalCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildIllnessCard(
    String name,
    String date,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: const Color(0xFFA2A3F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.healing,
              color: Color(0xFFA2A3F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Since $date',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (_memberDetails['history'] ?? []).length,
      itemBuilder: (context, index) {
        final item = _memberDetails['history']![index];
        final bool isLast = index == (_memberDetails['history'] ?? []).length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column with dot and line
            Column(
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: item['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['date'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
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
                            color: item['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'],
                            color: item['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (_memberDetails['documents'] ?? []).length,
      itemBuilder: (context, index) {
        final doc = _memberDetails['documents']![index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: doc['type'] == 'PDF' ? const Color(0xFFECC2C0).withOpacity(0.1) : const Color(0xFF9AD7D8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                doc['icon'],
                color: doc['type'] == 'PDF' ? const Color(0xFFECC2C0) : const Color(0xFF9AD7D8),
                size: 24,
              ),
            ),
            title: Text(
              doc['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Added on ${doc['date']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    // TODO: Implement download functionality
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    // TODO: Implement share functionality
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (_memberDetails['doctors'] ?? []).length,
      itemBuilder: (context, index) {
        final doctor = _memberDetails['doctors']![index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFA2A3F3).withOpacity(0.1),
              radius: 25,
              child: Icon(
                Icons.person,
                color: const Color(0xFFA2A3F3),
                size: 30,
              ),
            ),
            title: Text(
              doctor['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  doctor['speciality'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last visit: ${doctor['lastVisit']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement schedule appointment functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9AD7D8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Schedule'),
            ),
          ),
        );
      },
    );
  }
}

// Custom delegate to make the tab bar sticky
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
