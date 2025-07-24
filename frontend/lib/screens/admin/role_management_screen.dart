// lib/screens/admin/role_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedRole = '';

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
        searchQuery: _searchController.text.trim(),
        roleFilter: _selectedRole.isEmpty ? null : _selectedRole,
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
    if (user.role == newRole) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Change Role',
      'Are you sure you want to change ${user.fullName}\'s role from ${user.role.toUpperCase()} to ${newRole.toUpperCase()}?',
    );

    if (!confirmed) return;

    try {
      final success = await _adminService.updateUserRole(user.id, newRole);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.fullName}\'s role updated to ${newRole.toUpperCase()}',
            ),
          ),
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

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Map<String, List<User>> _groupUsersByRole() {
    final Map<String, List<User>> grouped = {};
    for (final role in AppConstants.allRoles) {
      grouped[role] = _users.where((user) => user.role == role).toList();
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        backgroundColor: Colors.green,
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
                        value: _selectedRole.isEmpty ? null : _selectedRole,
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
                            _selectedRole = value ?? '';
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

          // Role Overview
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildRoleOverview(),
          ),

          // Users by Role
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
                    : _selectedRole.isEmpty
                    ? _buildGroupedUsersList()
                    : _buildFilteredUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOverview() {
    final roleStats = <String, int>{};
    for (final role in AppConstants.allRoles) {
      roleStats[role] = _users.where((user) => user.role == role).length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.allRoles.map((role) {
                    final count = roleStats[role] ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getRoleColor(role)),
                      ),
                      child: Text(
                        '${role.toUpperCase()}: $count',
                        style: TextStyle(
                          color: _getRoleColor(role),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedUsersList() {
    final groupedUsers = _groupUsersByRole();
    return ListView(
      children:
          AppConstants.allRoles.map((role) {
            final users = groupedUsers[role] ?? [];
            if (users.isEmpty) return const SizedBox.shrink();

            return ExpansionTile(
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getRoleColor(role),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${role.toUpperCase()} (${users.length})'),
                ],
              ),
              children: users.map((user) => _buildUserTile(user)).toList(),
            );
          }).toList(),
    );
  }

  Widget _buildFilteredUsersList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) => _buildUserTile(_users[index]),
    );
  }

  Widget _buildUserTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ],
        ),
        trailing: DropdownButton<String>(
          value: user.role,
          items:
              AppConstants.allRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
          onChanged: (newRole) {
            if (newRole != null) {
              _updateUserRole(user, newRole);
            }
          },
        ),
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
}
