import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/profile_provider.dart';
import '../model/profile_model.dart';
import 'package:go_router/go_router.dart';

class ProfileWide extends ConsumerStatefulWidget {
  const ProfileWide({super.key});

  @override
  ConsumerState<ProfileWide> createState() => _ProfileWideState();
}

class _ProfileWideState extends ConsumerState<ProfileWide> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Initial check: if profile is already loaded, update controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileNotifierProvider).profile;
      if (profile != null) {
        _updateControllers(profile);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateControllers(ProfileModel profile) {
    _usernameController.text = profile.username;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _emailController.text = profile.email ?? '';
    _mobileController.text = profile.mobileNumber ?? '';
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);

    // Initial fill
    ref.listen(profileNotifierProvider, (previous, next) {
      if (next.profile != null && (previous?.profile != next.profile)) {
        _updateControllers(next.profile!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Fixed Header
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                  color: const Color(0xFFF3F4F6),
                  alignment: Alignment.center,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: _buildHeader(state),
                  ),
                ),

                // Scrollable Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildPersonalCard(state)),
                                const SizedBox(width: 32),
                                Expanded(child: _buildChangePasswordCard(state)),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Fixed Footer Actions
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: _buildActionButtons(state),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ProfileState state) {
    final profile = state.profile;
    final fullName = profile != null
        ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim()
        : 'User';
    final initial = (profile?.username ?? 'U').isNotEmpty
        ? (profile?.username ?? 'U')[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF9FAFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF141E7A), size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF141E7A),
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? (profile?.username ?? 'User') : fullName,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        profile?.roleName?.toUpperCase() ?? 'USER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E40AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      profile?.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(ProfileState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.person_outline, 'Personal Information'),
            const SizedBox(height: 24),
            _buildFieldLabel('Username'),
            AppTextField(
              controller: _usernameController,
              hint: 'Username',
              prefixIcon: const Icon(Icons.alternate_email, size: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('First Name'),
                      AppTextField(
                        controller: _firstNameController,
                        hint: 'First Name',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Last Name'),
                      AppTextField(
                        controller: _lastNameController,
                        hint: 'Last Name',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Email Address'),
            AppTextField(
              controller: _emailController,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline, size: 18),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Mobile Number'),
            AppTextField(
              controller: _mobileController,
              hint: 'Mobile Number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordCard(ProfileState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.lock_outline, 'Change Password'),
            const SizedBox(height: 24),
            _buildFieldLabel('New Password'),
            AppTextField(
              controller: _passwordController,
              hint: 'New Password',
              isPassword: true,
              obscureText: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Confirm Password'),
            AppTextField(
              controller: _confirmPasswordController,
              hint: 'Confirm Password',
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF141E7A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ProfileState state) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: state.isUpdating ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141E7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('UPDATE PROFILE'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final request = ProfileUpdateRequest(
      username: _usernameController.text,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      mobileNumber: _mobileController.text,

    );

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile(request);

    if (mounted) {
      if (success) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        final error = ref.read(profileNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to update profile')),
        );
      }
    }
  }
}

