// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
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
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final users = await _adminService.getUsers(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.trim(),
        roleFilter: _selectedRoleFilter.isEmpty ? null : _selectedRoleFilter,
      );

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    try {
      final success = await _adminService.updateUserRole(user.id, newRole);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully')),
        );
        _loadUsers(); // Refresh the list
      } else {
        throw Exception('Failed to update role');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final success = await _adminService.toggleUserStatus(
        user.id,
        !user.isActive,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${!user.isActive ? 'activated' : 'deactivated'} successfully',
            ),
          ),
        );
        _loadUsers(); // Refresh the list
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}')),
      );
    }
  }

  void _showRoleDialog(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Change Role - ${user.fullName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppConstants.allRoles.map((role) {
                    return RadioListTile<String>(
                      title: Text(role.toUpperCase()),
                      value: role,
                      groupValue: user.role,
                      onChanged: (String? value) {
                        if (value != null && value != user.role) {
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
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          ...AppConstants.allRoles.map(
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
                    : _users.isEmpty
                    ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRoleColor(user.role),
                              child: Text(
                                user.firstName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            user.isActive
                                                ? Colors.green
                                                : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.isActive ? 'ACTIVE' : 'INACTIVE',
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
                                            user.isActive
                                                ? Icons.block
                                                : Icons.check_circle,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            user.isActive
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
        ],
      ),
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

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('User Details - ${user.fullName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Role', user.role.toUpperCase()),
                _buildDetailRow(
                  'Status',
                  user.isActive ? 'Active' : 'Inactive',
                ),
                _buildDetailRow('Joined', _formatDate(user.dateJoined)),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
