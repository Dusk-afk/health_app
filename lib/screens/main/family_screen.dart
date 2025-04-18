import 'package:flutter/material.dart';
import 'package:well_nest/screens/main/member/member_screen.dart';
import '../../models/family_member.dart';
import '../../services/api/family_service.dart';
import 'package:intl/intl.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({Key? key}) : super(key: key);

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final FamilyService _familyService = FamilyService.instance;
  List<FamilyMember> _familyMembers = [];
  FamilyMember? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _familyService.getFamilyMembers();

      // curr user alag and family user alag 
      // final currentUser = members.firstWhere((member) => member.isSelf, orElse: () => members.first);
      // final otherMembers = members.where((member) => !member.isSelf).toList();
      final currentUser = members.firstWhere((member) => member.isSelf, orElse: () => members.first);
      final otherMembers = members.where((member) => !member.isSelf).toList();

      setState(() {
        _currentUser = currentUser;
        _familyMembers = otherMembers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load family members: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: Text(
              'Family Members',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),


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
          const SizedBox(height: 8),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton.icon(
              onPressed: _loadFamilyMembers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9AD7D8),
              ),
            ),
          ),
          const SizedBox(height: 8),

        //error loading
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _loadFamilyMembers,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    //empty state is here is not found...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: (_currentUser == null && _familyMembers.isEmpty) ? _buildEmptyState() : _buildFamilyContent(),
    );
  }

  Widget _buildFamilyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
//profile card 
        if (_currentUser != null) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildCurrentUserCard(_currentUser!),
          const SizedBox(height: 24),
        ],

  //family members 
        if (_familyMembers.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Family Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: () => _showAddFamilyMemberDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA2A3F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _familyMembers.length,
              itemBuilder: (context, index) {
                final member = _familyMembers[index];
                return _buildFamilyMemberCard(member);
              },
            ),
          ),
        ] else ...[
//no family member is there , oinly the curr user is there 
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 64,
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
                    'Add family members to manage their health information',
                    textAlign: TextAlign.center,
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentUserCard(FamilyMember user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9AD7D8), Color(0xFFA2A3F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 36,
              child: Icon(
                user.avatar,
                size: 40,
                color: const Color(0xFFA2A3F3),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         user.fullName,
          //         style: const TextStyle(
          //           fontSize: 20,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.white,
          //         ),
          //       ),
          //       const SizedBox(height: 4),
          //       if (user.age != null)
          //         Text(
          //           'Age: ${user.age}',
          //           style: const TextStyle(
          //             fontSize: 14,
          //             color: Colors.white,
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.phoneNumber != null)
                  Text(
                    user.phoneNumber!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 4),
                if (user.age != null)
                  Text(
                    'Age: ${user.age}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _navigateToMemberScreen(user);
            },
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

  Widget _buildFamilyMemberCard(FamilyMember member) {
    //color based on gender
    final String gender = member.gender ?? 'prefer_not_to_say';

    // Colors for male/prefer not to say (light blue) and female (purple)
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
        const Color(0xFF9AD7D8), // light blue
        const Color(0xFFC9EBED), // Light blue bg
      ],
    };

    // select colors based on gender
    final List<Color> colors = genderColors[gender] ?? genderColors['prefer_not_to_say']!;
    final Color avatarBorderColor = colors[0];
    final Color avatarBgColor = colors[1];

    return InkWell(
      onTap: () {
        // to mmber scrn
        _navigateToMemberScreen(member);
      },
      onLongPress: () {
        //edit and delete 
        _showMemberOptions(member);
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
            // Container(
            //   padding: const EdgeInsets.all(2),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [avatarBorderColor, avatarBorderColor.withOpacity(0.7)],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     shape: BoxShape.circle,
            //   ),
            //   child: CircleAvatar(
            //     backgroundColor: avatarBgColor,
            //     radius: 40,
            //     child: Icon(
            //       member.avatar,
            //       size: 45,
            //       color: avatarBorderColor,
            //     ),
            //   ),
            // ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarBorderColor, avatarBorderColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: avatarBgColor,
                radius: 40,
                child: Icon(
                  member.avatar,
                  size: 45,
                  color: avatarBorderColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member.fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              member.relationship,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            if (member.age != null)
              Text(
                'Age: ${member.age}',
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

  void _navigateToMemberScreen(FamilyMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberScreen(familyMember: member),
      ),
    );
  }

  void _showMemberOptions(FamilyMember member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              member.fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditFamilyMemberDialog(context, member);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[700]),
              title: Text('Delete', style: TextStyle(color: Colors.red[700])),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFamilyMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    DateTime? selectedDate;
    String selectedGender = 'prefer_not_to_say'; // Default gender
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
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
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: 'Enter phone number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'Enter email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Date of Birth picker
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (Optional)',
                      hintText: 'Select date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null ? DateFormat('MMM dd, yyyy').format(selectedDate!) : 'Select date',
                          style: TextStyle(
                            color: selectedDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gender (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Male'),
                        value: 'male',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFF9AD7D8),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Female'),
                        value: 'female',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFFA2A3F3),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                RadioListTile<String>(
                  title: const Text('Prefer not to say'),
                  value: 'prefer_not_to_say',
                  groupValue: selectedGender,
                  activeColor: const Color(0xFF9AD7D8),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty || relationController.text.isEmpty) {
                        setState(() {
                          errorMessage = 'Name and Relation are required';
                        });
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final dateOfBirth = selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null;

                        // final newMember = await _familyService.addFamilyMember(
                        //   fullName: nameController.text,
                        //   relationship: relationController.text,
                        //   phoneNumber: phoneController.text.isEmpty ? null : phoneController.text,
                        //   email: emailController.text.isEmpty ? null : emailController.text,
                        //   gender: selectedGender == 'prefer_not_to_say' ? null : selectedGender,
                        // );
                        final newMember = await _familyService.addFamilyMember(
                          fullName: nameController.text,
                          relationship: relationController.text,
                          phoneNumber: phoneController.text.isEmpty ? null : phoneController.text,
                          email: emailController.text.isEmpty ? null : emailController.text,
                          dateOfBirth: dateOfBirth,
                          gender: selectedGender == 'prefer_not_to_say' ? null : selectedGender,
                        );

                        // Reload family members list
                        await _loadFamilyMembers();
                        Navigator.pop(context);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${newMember.fullName} added successfully')),
                        );
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Error: ${e.toString()}';
                          isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9AD7D8),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFamilyMemberDialog(BuildContext context, FamilyMember member) {
    final nameController = TextEditingController(text: member.fullName);
    final relationController = TextEditingController(text: member.relationship);
    final emailController = TextEditingController(text: member.email ?? '');
    DateTime? selectedDate = member.dateOfBirth != null ? DateTime.parse(member.dateOfBirth!) : null;
    String selectedGender = member.gender ?? 'prefer_not_to_say';
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
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
                // Phone number is read-only in edit mode
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  child: Text(member.phoneNumber ?? 'Not provided'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Date of Birth picker
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (Optional)',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null ? DateFormat('MMM dd, yyyy').format(selectedDate!) : 'Not provided',
                          style: TextStyle(
                            color: selectedDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Male'),
                        value: 'male',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFF9AD7D8),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Female'),
                        value: 'female',
                        groupValue: selectedGender,
                        activeColor: const Color(0xFFA2A3F3),
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                RadioListTile<String>(
                  title: const Text('Prefer not to say'),
                  value: 'prefer_not_to_say',
                  groupValue: selectedGender,
                  activeColor: const Color(0xFF9AD7D8),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty || relationController.text.isEmpty) {
                        setState(() {
                          errorMessage = 'Name and Relation are required';
                        });
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final dateOfBirth = selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null;

                        await _familyService.updateFamilyMember(
                          familyMemberId: member.familyMemberId,
                          fullName: nameController.text,
                          relationship: relationController.text,
                          email: emailController.text.isEmpty ? null : emailController.text,
                          dateOfBirth: dateOfBirth,
                          gender: selectedGender == 'prefer_not_to_say' ? null : selectedGender,
                        );

                        // Reload family members list
                        await _loadFamilyMembers();
                        Navigator.pop(context);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Family member updated successfully')),
                        );
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Error: ${e.toString()}';
                          isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9AD7D8),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMember(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to remove ${member.fullName} from your family members?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _familyService.deleteFamilyMember(member.familyMemberId);
                await _loadFamilyMembers();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.fullName} removed from your family members')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to remove family member: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
