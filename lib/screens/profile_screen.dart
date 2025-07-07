import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch profile data
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create default profile if doesn't exist
        final newProfile = {
          'id': user.id,
          'username': user.email?.split('@').first ?? 'user',
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('profiles').upsert(newProfile);
        setState(() {
          _profile = newProfile;
        });
      } else {
        setState(() {
          _profile = response;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth', 
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            _profile?['username']?.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _profile?['username'] ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _profile?['email'] ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    final user = _supabase.auth.currentUser;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('User ID', user?.id.substring(0, 8)),
        _buildInfoRow('Username', _profile?['username']),
        _buildInfoRow('Email', _profile?['email']),
        _buildInfoRow('Phone', _profile?['phone'] ?? 'Not provided'),
        _buildInfoRow(
          'Email Verified', 
          user?.emailConfirmedAt != null ? 'Yes' : 'No'
        ),
        _buildInfoRow(
          'Account Created',
          user?.createdAt != null 
            ? dateFormat.format(user!.createdAt.toLocal())
            : 'Unknown'
        ),
        _buildInfoRow(
          'Last Login',
          _profile?['last_login_at'] != null
            ? dateFormat.format(DateTime.parse(_profile!['last_login_at']).toLocal())
            : 'Not provided'
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      _buildProfileInfo(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
                    ], 
                  ),
                ),
    );
  }
}

extension DateTimeStringExtension on String {
  DateTime toLocal() {
    return DateTime.parse(this).toLocal();
  }
}