import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/profile_provider.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  String _selectedAvatar = 'person';
  bool _isEditMode = false;

  final List<String> _avatars = ['person', 'face', 'cruelty_free', 'account_circle', 'psychology', 'rocket_launch'];

  @override
  void initState() {
    super.initState();
    // If profile already exists, pre-fill fields for editing
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingProfile());
  }

  void _loadExistingProfile() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    
    if (profile != null && mounted) {
      setState(() {
        _isEditMode = true;
        _nameController.text = profile.name;
        _emailController.text = profile.email ?? '';
        _mobileController.text = profile.mobile ?? '';
        _selectedAvatar = profile.profileImage ?? 'person';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Remove any spaces, dashes, +91 prefix
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    // After removing +91 or 91 prefix, should be exactly 10 digits
    final digits = cleaned.startsWith('91') && cleaned.length == 12
        ? cleaned.substring(2)
        : cleaned;
    return RegExp(r'^[6-9]\d{9}$').hasMatch(digits);
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation for email
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    // Extra validation for phone
    final phone = _mobileController.text.trim();
    if (phone.isNotEmpty && !_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be a valid 10-digit Indian number')),
      );
      return;
    }

    final db = Provider.of<AppDatabase>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    await profileProvider.saveProfile(
      db,
      _nameController.text.trim(),
      email.isEmpty ? null : email,
      phone.isEmpty ? null : phone,
      _selectedAvatar,
    );

    if (!mounted) return;

    if (_isEditMode) {
      Navigator.pop(context, true); // Return true to signal data changed
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: _isEditMode 
        ? AppBar(
            title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          )
        : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditMode ? 'Update your Profile' : 'Set up your Profile',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Personalize your offline expense tracking experience.',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Avatar Selector
                const Text(
                  'Choose an Avatar',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = avatar),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1E1E24),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white10,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIconData(avatar),
                            color: isSelected ? Colors.white : Colors.white54,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),
                
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Shadab Saifi',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address (Optional)',
                  hint: 'e.g. shadab@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty && !_isValidEmail(value.trim())) {
                      return 'Enter a valid email (e.g. name@example.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _mobileController,
                  label: 'Mobile Number (Optional)',
                  hint: 'e.g. 9876543210',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty && !_isValidPhone(value.trim())) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 60),

                ElevatedButton(
                  onPressed: profileProvider.isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                  ),
                  child: profileProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Update Profile' : 'Save Profile',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'person': return Icons.person;
      case 'face': return Icons.face;
      case 'cruelty_free': return Icons.cruelty_free;
      case 'account_circle': return Icons.account_circle;
      case 'psychology': return Icons.psychology;
      case 'rocket_launch': return Icons.rocket_launch;
      default: return Icons.person;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 22),
            filled: true,
            fillColor: const Color(0xFF1E1E24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
            counterStyle: const TextStyle(color: Colors.white38),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
