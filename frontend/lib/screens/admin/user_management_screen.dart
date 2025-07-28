// lib/screens/admin/user_management_screen.dart - COMPLETELY FIXED VERSION
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedRoleFilter = '';
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final fetchedUsers = await _adminService.getUsers(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery:
            _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
        roleFilter: _selectedRoleFilter.isEmpty ? null : _selectedRoleFilter,
      );

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load users: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserRole(
    Map<String, dynamic> user,
    String newRole,
  ) async {
    try {
      final success = await _adminService.updateUserRole(
        user['id'].toString(),
        newRole,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully')),
        );
        _loadUsers();
      } else {
        throw Exception('Failed to update role');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final isCurrentlyActive = user['is_active'] ?? true;
      final success = await _adminService.toggleUserStatus(
        user['id'].toString(),
        !isCurrentlyActive,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${!isCurrentlyActive ? 'activated' : 'deactivated'} successfully',
            ),
          ),
        );
        _loadUsers();
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: ${e.toString()}')),
        );
      }
    }
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = user['role'] ?? 'student';
    final userName = user['full_name'] ?? user['first_name'] ?? 'User';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Change Role - $userName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['student', 'instructor', 'coordinator', 'admin'].map((role) {
                    return RadioListTile<String>(
                      title: Text(role.toUpperCase()),
                      value: role,
                      groupValue: currentRole,
                      onChanged: (String? value) {
                        if (value != null && value != currentRole) {
                          Navigator.pop(context);
                          _updateUserRole(user, value);
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value:
                            _selectedRoleFilter.isEmpty
                                ? null
                                : _selectedRoleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          ...[
                            'student',
                            'instructor',
                            'coordinator',
                            'admin',
                          ].map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value ?? '';
                          });
                          _loadUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : users.isEmpty
                    ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userName =
                              user['full_name'] ??
                              user['first_name'] ??
                              'Unknown User';
                          final userEmail = user['email'] ?? 'No email';
                          final userRole = user['role'] ?? 'student';
                          final isActive = user['is_active'] ?? true;
                          final firstName =
                              user['first_name'] ?? user['full_name'] ?? 'U';
                          final username = user['username'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(userRole),
                                child: Text(
                                  firstName.isNotEmpty 
                                    ? firstName.substring(0, 1).toUpperCase()
                                    : username.isNotEmpty 
                                      ? username.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userEmail),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(userRole),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          userRole.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'change_role':
                                      _showRoleDialog(user);
                                      break;
                                    case 'toggle_status':
                                      _toggleUserStatus(user);
                                      break;
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(
                                          children: [
                                            Icon(Icons.admin_panel_settings),
                                            SizedBox(width: 8),
                                            Text('Change Role'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.block
                                                  : Icons.check_circle,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isActive
                                                  ? 'Deactivate'
                                                  : 'Activate',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                              onTap: () => _showUserDetails(user),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'coordinator':
        return Colors.purple;
      case 'instructor':
        return Colors.green;
      case 'student':
      default:
        return Colors.blue;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final userName = user['full_name'] ?? user['first_name'] ?? 'Unknown User';
    final userEmail = user['email'] ?? 'No email';
    final userRole = user['role'] ?? 'student';
    final isActive = user['is_active'] ?? true;
    final dateJoined =
        user['date_joined'] ??
        user['created_at'] ??
        DateTime.now().toIso8601String();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('User Details - $userName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', userEmail),
                _buildDetailRow('Role', userRole.toUpperCase()),
                _buildDetailRow('Status', isActive ? 'Active' : 'Inactive'),
                _buildDetailRow('Joined', _formatDate(dateJoined)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
