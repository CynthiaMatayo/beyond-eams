// lib/screens/admin/role_management_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import '../../widgets/admin_bottom_nav_bar.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = []; // Add filtered list
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedRoleFilter = '';

  // Mock role distribution data
  final Map<String, int> _roleDistribution = {
    'student': 10,
    'instructor': 1,
    'coordinator': 2,
    'admin': 2,
  };

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

      // Load all users first
      final fetchedUsers = await _adminService.getUsers(
        page: 1,
        pageSize: 100,
        searchQuery:
            _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
        // Always get all users, then filter locally for better UX
        roleFilter: null,
      );

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          _applyFilters(); // Apply filters after loading
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

  // Local filtering method for better responsiveness
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(users);

    // Apply role filter
    if (_selectedRoleFilter.isNotEmpty) {
      filtered =
          filtered.where((user) {
            final userRole =
                (user['role'] ?? 'student').toString().toLowerCase();
            return userRole == _selectedRoleFilter.toLowerCase();
          }).toList();
    }

    // Apply search filter
    if (_searchController.text.trim().isNotEmpty) {
      final searchTerm = _searchController.text.trim().toLowerCase();
      filtered =
          filtered.where((user) {
            final userName =
                (user['full_name'] ?? user['first_name'] ?? '')
                    .toString()
                    .toLowerCase();
            final userEmail = (user['email'] ?? '').toString().toLowerCase();
            return userName.contains(searchTerm) ||
                userEmail.contains(searchTerm);
          }).toList();
    }

    setState(() {
      filteredUsers = filtered;
    });
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
        _loadUsers(); // Reload to get fresh data
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
        title: const Text('Role Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed:
                () => Navigator.pushNamed(context, '/admin/notifications'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Search and Compact Role Distribution
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
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
                  onChanged: (_) => _applyFilters(), // Real-time search
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 16),

                // Compact Role Distribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Role Distribution',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedRoleFilter.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedRoleFilter = '';
                                });
                                _applyFilters();
                              },
                              child: const Text('Clear Filter'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _roleDistribution.entries.map((entry) {
                              final isSelected =
                                  entry.key == _selectedRoleFilter;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedRoleFilter =
                                        isSelected ? '' : entry.key;
                                  });
                                  _applyFilters(); // Apply filter immediately
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? _getRoleColor(entry.key)
                                            : _getRoleColor(
                                              entry.key,
                                            ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getRoleColor(entry.key),
                                      width: isSelected ? 0 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${entry.key.toUpperCase()}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : _getRoleColor(entry.key),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
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
                    : filteredUsers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedRoleFilter.isNotEmpty
                                ? 'No ${_selectedRoleFilter}s found'
                                : 'No users found',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          if (_selectedRoleFilter.isNotEmpty ||
                              _searchController.text.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedRoleFilter = '';
                                  _searchController.clear();
                                });
                                _applyFilters();
                              },
                              child: const Text('Clear all filters'),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final userName =
                              user['full_name'] ??
                              user['first_name'] ??
                              'Unknown User';
                          final userEmail = user['email'] ?? 'No email';
                          final userRole = user['role'] ?? 'student';
                          final isActive = user['is_active'] ?? true;
                          final firstName =
                              user['first_name'] ?? user['full_name'] ?? 'U';

                          return Container(
                            key: ValueKey(user['id']),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(userRole),
                                child: Text(
                                  firstName.substring(0, 1).toUpperCase(),
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
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(userEmail),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
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
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
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
                                    case 'view_details':
                                      _showUserDetails(user);
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
                                      const PopupMenuItem(
                                        value: 'view_details',
                                        child: Row(
                                          children: [
                                            Icon(Icons.info),
                                            SizedBox(width: 8),
                                            Text('View Details'),
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
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRoleDialog(user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Change Role'),
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
