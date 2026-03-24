import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/profile_provider.dart';
import '../model/profile_model.dart';
import '../../../../shared/widgets/location_picker.dart';

class ProfileNarrow extends ConsumerStatefulWidget {
  const ProfileNarrow({super.key});

  @override
  ConsumerState<ProfileNarrow> createState() => _ProfileNarrowState();
}

class _ProfileNarrowState extends ConsumerState<ProfileNarrow> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _companyNameController = TextEditingController();
  List<AddressControllerGroup> _addressControllers = [];

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
    _companyNameController.dispose();
    for (var group in _addressControllers) {
      group.dispose();
    }
    super.dispose();
  }

  void _updateControllers(ProfileModel profile) {
    _usernameController.text = profile.username;
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _emailController.text = profile.email ?? '';
    _mobileController.text = profile.mobileNumber ?? '';
    _companyNameController.text = profile.companyName ?? '';
    
    // Clear existing address controllers
    for (var group in _addressControllers) {
      group.dispose();
    }
    
    setState(() {
      _addressControllers = profile.addresses.map((addr) => AddressControllerGroup(
        id: addr.id,
        address: addr.addressLine1 ?? '',
        city: addr.city ?? '',
        state: addr.state ?? '',
        country: addr.country ?? '',
        pincode: addr.pincode ?? '',
      )).toList();

      if (_addressControllers.isEmpty) {
        _addAddress();
      }
    });
  }

  void _addAddress() {
    setState(() {
      _addressControllers.add(AddressControllerGroup(
        address: '',
        city: '',
        state: '',
        country: '',
        pincode: '',
      ));
    });
  }

  void _removeAddress(int index) {
    setState(() {
      _addressControllers[index].dispose();
      _addressControllers.removeAt(index);
    });
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
        title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(state),
                ),
                
                // Scrollable Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSection(
                          'Personal Info',
                          Icons.person_outline,
                          [
                            _buildField('Username', _usernameController, icon: Icons.alternate_email),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildField('First Name', _firstNameController)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildField('Last Name', _lastNameController)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildField('Email', _emailController, type: TextInputType.emailAddress, icon: Icons.mail_outline),
                            const SizedBox(height: 12),
                            _buildField('Phone', _mobileController, type: TextInputType.phone, icon: Icons.phone_outlined),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          'Security',
                          Icons.lock_outline,
                          [
                            _buildField(
                              'New Password',
                              _passwordController,
                              isPassword: true,
                              obscure: _obscurePassword,
                              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              'Confirm Password',
                              _confirmPasswordController,
                              isPassword: true,
                              obscure: _obscureConfirmPassword,
                              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildCompanySection(state),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Fixed Footer Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildActions(state),
                ),
              ],
            ),
    );
  }

  Widget _buildCompanySection(ProfileState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 18, color: Color(0xFF141E7A)),
                  const SizedBox(width: 8),
                  Text(
                    'Company',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addAddress,
                icon: const Icon(Icons.add_location_alt_outlined, size: 14),
                label: const Text('ADD'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF141E7A),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildField('Company Name', _companyNameController, icon: Icons.business_rounded),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          ...List.generate(_addressControllers.length, (index) {
            final group = _addressControllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ADDRESS ${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF141E7A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_addressControllers.length > 1)
                        IconButton(
                          onPressed: () => _removeAddress(index),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField('Street Address', group.addressController, maxLines: 2),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  LocationPicker(
                    currentCountry: group.country,
                    currentState: group.state,
                    currentCity: group.city,
                    isVertical: true,
                    onCountryChanged: (value) => setState(() => group.country = value),
                    onStateChanged: (value) => setState(() => group.state = value),
                    onCityChanged: (value) => setState(() => group.city = value),
                  ),
                  const SizedBox(height: 12),
                  _buildField('Pincode', group.pincodeController),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileState state) {
    final profile = state.profile;
    final initial = (profile?.username ?? 'U').isNotEmpty ? (profile?.username ?? 'U')[0].toUpperCase() : 'U';

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFF141E7A),
          child: Text(
            initial,
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile?.username ?? 'User',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
        ),
        Text(
          profile?.roleName ?? '',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Icon(icon, size: 18, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isPassword = false, bool obscure = false, VoidCallback? onToggle, TextInputType? type, int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.5),
          ),
        ),
        AppTextField(
          controller: controller,
          hint: label,
          isPassword: isPassword,
          obscureText: obscure,
          onToggle: onToggle,
          keyboardType: type,
          maxLines: maxLines,
          prefixIcon: icon != null ? Icon(icon, size: 16) : null,
        ),
      ],
    );
  }

  Widget _buildActions(ProfileState state) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isUpdating ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF141E7A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: state.isUpdating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
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
      companyName: _companyNameController.text,
      addresses: _addressControllers.map((g) => AddressModel(
        id: g.id,
        addressLine1: g.addressController.text,
        city: g.city,
        state: g.state,
        country: g.country,
        pincode: g.pincodeController.text,
      )).toList(),
    );

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(request);
    if (mounted) {
      if (success) {
        _passwordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
      }
    }
  }
}

class AddressControllerGroup {
  final int? id;
  final TextEditingController addressController;
  final TextEditingController pincodeController;
  String? city;
  String? state;
  String? country;

  AddressControllerGroup({
    this.id,
    required String address,
    required String city,
    required String state,
    required String country,
    required String pincode,
  })  : addressController = TextEditingController(text: address),
        pincodeController = TextEditingController(text: pincode),
        city = city,
        state = state,
        country = country;

  void dispose() {
    addressController.dispose();
    pincodeController.dispose();
  }
}
