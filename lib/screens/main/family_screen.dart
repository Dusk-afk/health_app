import 'package:flutter/material.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({Key? key}) : super(key: key);

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  // Sample family member data with Indian names
  final List<Map<String, dynamic>> _familyMembers = [
    {
      'name': 'Priya',
      'relation': 'Spouse',
      'age': 34,
      'avatar': Icons.face,
    },
    {
      'name': 'Arjun',
      'relation': 'Child',
      'age': 12,
      'avatar': Icons.child_care,
    },
    {
      'name': 'Ananya',
      'relation': 'Child',
      'age': 8,
      'avatar': Icons.child_care,
    },
    {
      'name': 'Rajesh',
      'relation': 'Father',
      'age': 68,
      'avatar': Icons.elderly,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: const Text(
              'Family Members',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Manage your family members\' health information',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Grid view of family members
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _familyMembers.isEmpty ? _buildEmptyState() : _buildFamilyGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No family members yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a family member to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Family Member'),
            onPressed: () => _showAddFamilyMemberDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA2A3F3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _familyMembers.length + 1, // +1 for the add button
      itemBuilder: (context, index) {
        if (index == _familyMembers.length) {
          // This is the last item - the add button
          return _buildAddMemberCard();
        }
        final member = _familyMembers[index];
        return _buildFamilyMemberCard(member);
      },
    );
  }

  Widget _buildAddMemberCard() {
    return InkWell(
      onTap: () => _showAddFamilyMemberDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF9AD7D8).withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9AD7D8),
                    const Color(0xFFA2A3F3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 40,
                child: Icon(
                  Icons.add_rounded,
                  size: 45,
                  color: const Color(0xFFA2A3F3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Member',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create new profile',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member) {
    // Alternate between two colors from HomeScreen
    final List<Color> avatarColors = [
      const Color(0xFF9AD7D8), // Light blue
      const Color(0xFFA2A3F3), // Purple
    ];

    final List<Color> bgColors = [
      const Color(0xFFC9EBED), // Light blue bg
      const Color(0xFFD0D1FF), // Purple bg
    ];

    final colorIndex = _familyMembers.indexOf(member) % 2;

    return InkWell(
      onTap: () {
        // Navigate to member details or edit page when tapped
        _showEditFamilyMemberDialog(context, member);
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColors[colorIndex], avatarColors[colorIndex].withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: bgColors[colorIndex],
                radius: 40,
                child: Icon(
                  member['avatar'],
                  size: 45,
                  color: avatarColors[colorIndex],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member['relation'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Age: ${member['age']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFamilyMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                hintText: 'E.g., Spouse, Child, Parent',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter age',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && relationController.text.isNotEmpty && ageController.text.isNotEmpty) {
                setState(() {
                  _familyMembers.add({
                    'name': nameController.text,
                    'relation': relationController.text,
                    'age': int.parse(ageController.text),
                    'avatar': Icons.person,
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9AD7D8),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFamilyMemberDialog(BuildContext context, Map<String, dynamic> member) {
    final nameController = TextEditingController(text: member['name']);
    final relationController = TextEditingController(text: member['relation']);
    final ageController = TextEditingController(text: member['age'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && relationController.text.isNotEmpty && ageController.text.isNotEmpty) {
                setState(() {
                  final index = _familyMembers.indexOf(member);
                  if (index != -1) {
                    _familyMembers[index] = {
                      'name': nameController.text,
                      'relation': relationController.text,
                      'age': int.parse(ageController.text),
                      'avatar': member['avatar'],
                    };
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9AD7D8),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
