import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/profile_provider.dart';
import '../model/profile_model.dart';
import 'package:go_router/go_router.dart';

class ProfileMiddle extends ConsumerStatefulWidget {
  const ProfileMiddle({super.key});

  @override
  ConsumerState<ProfileMiddle> createState() => _ProfileMiddleState();
}

class _ProfileMiddleState extends ConsumerState<ProfileMiddle> {
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

    ref.listen(profileNotifierProvider, (previous, next) {
      if (next.profile != null && (previous?.profile != next.profile)) {
        _updateControllers(next.profile!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text('Profile Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Fixed Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: _buildHeader(state),
                ),
                
                // Scrollable Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSection(
                          Icons.person_outline,
                          'Personal Information',
                          [
                            _buildField('Username', _usernameController, prefixIcon: Icons.alternate_email),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildField('First Name', _firstNameController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildField('Last Name', _lastNameController)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildField('Email', _emailController, prefixIcon: Icons.mail_outline, type: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildField('Phone', _mobileController, prefixIcon: Icons.phone_outlined, type: TextInputType.phone),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          Icons.lock_outline,
                          'Security',
                          [
                            _buildField(
                              'New Password',
                              _passwordController,
                              isPassword: true,
                              obscure: _obscurePassword,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              'Confirm Password',
                              _confirmPasswordController,
                              isPassword: true,
                              obscure: _obscureConfirmPassword,
                              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                
                // Fixed Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  child: _buildActions(state),
                ),
              ],
            ),
    );
  }


  Widget _buildHeader(ProfileState state) {
    final profile = state.profile;
    final fullName = profile != null ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim() : 'User';
    final initial = (profile?.username ?? 'U').isNotEmpty ? (profile?.username ?? 'U')[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF9FAFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF141E7A),
            child: Text(
              initial,
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? (profile?.username ?? 'User') : fullName,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                ),
                Text(
                  profile?.roleName?.toUpperCase() ?? 'USER',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? prefixIcon, bool isPassword = false, bool obscure = false, VoidCallback? onToggle, TextInputType? type, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), letterSpacing: 0.5),
          ),
        ),
        AppTextField(
          controller: controller,
          hint: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
          isPassword: isPassword,
          obscureText: obscure,
          onToggle: onToggle,
          keyboardType: type,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildActions(ProfileState state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: state.isUpdating ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF141E7A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: state.isUpdating
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('SAVE CHANGES', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (_passwordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final request = ProfileUpdateRequest(
      username: _usernameController.text,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      mobileNumber: _mobileController.text,

    );

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(request);
    if (mounted) {
      if (success) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      } else {
        final error = ref.read(profileNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Update failed')));
      }
    }
  }
}
