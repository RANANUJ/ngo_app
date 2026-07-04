import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;
  final String collectionName; // 'volunteers' or 'admins'

  const UserDetailsScreen({
    Key? key,
    required this.userData,
    required this.userId,
    required this.collectionName,
  }) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isActive = true;
  String _role = 'Volunteer';

  // Permission settings
  bool _canManageNgos = false;
  bool _canManageUsers = false;
  bool _canViewReports = false;
  bool _canManageSettings = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? widget.userData['ngoName'] ?? widget.userData['name'] ?? 'User');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? widget.userData['officialPhone'] ?? '');
    _isActive = widget.userData['status'] == 'Active' || widget.userData['isActive'] != false;
    _role = widget.userData['role'] ?? (widget.collectionName == 'admins' ? 'Admin' : 'Volunteer');

    // Permissions
    final perms = widget.userData['permissions'] as Map<String, dynamic>? ?? {};
    _canManageNgos = perms['manageNgos'] == true || _role == 'Admin';
    _canManageUsers = perms['manageUsers'] == true || _role == 'Admin';
    _canViewReports = perms['viewReports'] == true || _role == 'Admin';
    _canManageSettings = perms['manageSettings'] == true || _role == 'Admin';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.userId)
          .update({
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'isActive': _isActive,
        'status': _isActive ? 'Active' : 'Inactive',
        'role': _role,
        'permissions': {
          'manageNgos': _canManageNgos,
          'manageUsers': _canManageUsers,
          'viewReports': _canViewReports,
          'manageSettings': _canManageSettings,
        }
      });

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Profile Updated Successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.userData['photoUrl'] ?? widget.userData['profileImageUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person, color: primaryColor, size: 36)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _emailController.text,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _isActive ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Information Form
                  _buildSectionHeader('Basic Information'),
                  _buildTextField('Full Name', _nameController),
                  _buildTextField('Contact Number', _phoneController, keyboardType: TextInputType.phone),

                  // Dropdown for Role selection
                  const SizedBox(height: 12),
                  const Text('System Role', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _role,
                        isExpanded: true,
                        items: ['Admin', 'Reviewer', 'Volunteer'].map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _role = val;
                              // Admins auto-enable all permissions
                              if (_role == 'Admin') {
                                _canManageNgos = true;
                                _canManageUsers = true;
                                _canViewReports = true;
                                _canManageSettings = true;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Operational Status Switch
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Operational Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          SizedBox(height: 2),
                          Text('Toggle whether this user account is active.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Switch(
                        activeColor: primaryColor,
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Permissions checklist
                  _buildSectionHeader('Permissions'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildPermissionTile(
                          'Manage NGO Approvals',
                          'Verify, Approve, or Reject pending NGO applications.',
                          _canManageNgos,
                          _role == 'Admin' ? null : (val) => setState(() => _canManageNgos = val ?? false),
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          'Manage App Users',
                          'Edit, block, or delete system user permissions.',
                          _canManageUsers,
                          _role == 'Admin' ? null : (val) => setState(() => _canManageUsers = val ?? false),
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          'View Performance Reports',
                          'Access line charts and statistical distribution charts.',
                          _canViewReports,
                          _role == 'Admin' ? null : (val) => setState(() => _canViewReports = val ?? false),
                        ),
                        const Divider(height: 1),
                        _buildPermissionTile(
                          'Configure Settings',
                          'Modify document requirements, email templates and templates.',
                          _canManageSettings,
                          _role == 'Admin' ? null : (val) => setState(() => _canManageSettings = val ?? false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _saveUser,
                      child: const Text('Save User Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, bool value, ValueChanged<bool?>? onChanged) {
    return CheckboxListTile(
      activeColor: primaryColor,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
