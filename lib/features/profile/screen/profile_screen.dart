import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/face_registration_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  String? _fullName;
  String? _email;
  bool _hasFaceRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase.from('users').select().eq('id', userId).single();

      setState(() {
        _fullName = data['full_name'] ?? 'User';
        _email = data['email'];
        _hasFaceRegistered = data['face_image_url'] != null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          ProfileHeader(
            fullName: _fullName ?? 'User',
            email: _email ?? '',
          ),
          SizedBox(height: 16),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: _showEditProfileDialog,
                ),
                Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.face,
                  title: 'Face ID for Payments',
                  subtitle: _hasFaceRegistered ? 'Registered' : 'Not registered',
                  trailing: _hasFaceRegistered
                      ? Icon(Icons.check_circle, color: Colors.green, size: 24)
                      : Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _registerFace,
                ),
                Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  trailing: Icon(Icons.exit_to_app, color: Colors.red),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUserData('full_name', nameController.text);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              await _changePassword(newPasswordController.text);
              Navigator.pop(context);
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserData(String column, String value) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('users').update({column: value}).eq('id', userId);

      setState(() {
        if (column == 'full_name') _fullName = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  Future<void> _registerFace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceRegistrationScreen()),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    Navigator.of(context).pushReplacementNamed('/signin');
  }
}