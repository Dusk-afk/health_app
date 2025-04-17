import 'package:flutter/material.dart';
import '../../services/api/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userName;
  String? _userPhoneNumber;
  // String? _userMembers;
  String? _userEmail;
  // String? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final userData = await AuthService.instance.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _userName = userData['full_name'] ?? 'User';
        _userPhoneNumber = userData['phone_number'] ?? '';
        _userEmail = userData['email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            // print(logout);
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.instance.logout();
              if (!mounted) return;
              // print(mounted);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_userPhoneNumber != null && _userPhoneNumber!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _userPhoneNumber!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    if (_userEmail != null && _userEmail!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _userEmail!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Row(
                          //   children: [
                          //     CircleAvatar(
                          //       radius: 40,
                          //       backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          //       child: Icon(
                          //         Icons.person,
                          //         size: 40,
                          //         color: Theme.of(context).colorScheme.primary,
                          //       ),
                          //     ),
                          //     const SizedBox(width: 16),
                          //     Expanded(
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //           if (_userPhoneNumber != null && _userPhoneNumber!.isNotEmpty) ...[
                          //             const SizedBox(height: 6),
                          //             Text(
                          //               _userPhoneNumber!,
                          //               style: TextStyle(
                          //                 fontSize: 14,
                          //                 color: Colors.grey[600],
                          //               ),
                          //             ),
                          //           ],
                          //           if (_userEmail != null && _userEmail!.isNotEmpty) ...[
                          //             const SizedBox(height: 4),
                          //             Text(
                          //               _userEmail!,
                          //               style: TextStyle(
                          //                 fontSize: 14,
                          //                 color: Colors.grey[600],
                          //               ),
                          //             ),
                          //           ],
                          //         ],
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to edit profile screen (to be implemented)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit Profile - Coming soon')),
                              );
                            },
                            // icon: const Icon(Icons.edit),
                            // label: const Text('Edit Profile'),
                            // style: ElevatedButton.styleFrom(
                            //   backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            //   foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            // ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            // label: const Text('Edit avatar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Settings Section
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications Settings - Coming soon')),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: const Text('English'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language Settings - Coming soon')),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.health_and_safety),
                    title: const Text('Health Connect Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Health Connect Settings - Coming soon')),
                      );
                    },
                  ),

                  const Divider(),

                  // About and Support Section
                  const Text(
                    'About & Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support - Coming soon')),
                      );
                    },
                  ),

                  // ListName(
                  // //   leading: const Icon(Icons.info),
                  // //   title: const Text('About'),
                  // //   onTap: () {
                  // //     ScaffoldMessenger.of(context).showSnackBar(
                  // //       const SnackBar(content: Text('About - Coming soon')),
                  // //     );
                  // //   },
                  // // ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('About - Coming soon')),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy - Coming soon')),
                      );
                    },
                  ),

                  const Divider(),

                  // Logout Button
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}
