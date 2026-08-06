import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Features
import 'package:air_water/features/user/presentation/model/user_model.dart';
import 'package:air_water/features/user/presentation/controller/user_provider.dart';

// Shared
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/core/app_theme/app_theme.dart';

class AddUserModal extends ConsumerStatefulWidget {
  final User? user;
  const AddUserModal({super.key, this.user});

  @override
  ConsumerState<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends ConsumerState<AddUserModal> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyAutocompleteController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _companyFocusNode = FocusNode();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _mobileError;

  List<Role>? _roles;
  Role? _selectedRole;
  CompanyAutocomplete? _selectedCompany;
  bool _isLoadingRoles = false;
  int _status = 1;



  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _firstNameController.text = widget.user!.firstName ?? '';
      _lastNameController.text = widget.user!.lastName ?? '';
      _emailController.text = widget.user!.email ?? '';
      _mobileController.text = widget.user!.mobileNumber ?? '';
      _companyAutocompleteController.text = widget.user!.companyName ?? '';
      _status = widget.user!.status;
      _timeoutController.text = (widget.user!.sessionHours ?? 24).toString();


      if (widget.user!.companyId != null && widget.user!.companyName != null) {
        _selectedCompany = CompanyAutocomplete(
          id: widget.user!.companyId!,
          name: widget.user!.companyName!,
        );
      }
    } else {
      _timeoutController.text = '24';
    }


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider).currentUser;
      if (currentUser != null) {
        if (widget.user == null) {
          if (currentUser.roleId != 1) {
            setState(() {
              _selectedCompany = CompanyAutocomplete(
                id: currentUser.companyId!,
                name: currentUser.companyName!,
              );
              _companyAutocompleteController.text = currentUser.companyName!;
            });
          } else {
            setState(() {
              _selectedCompany = CompanyAutocomplete(
                id: 216,
                name: 'Air Water',
              );
              _companyAutocompleteController.text = 'Air Water';
            });
          }
        }
      }
    });

    _loadRoles();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _firstNameFocus.addListener(() {
      if (!_firstNameFocus.hasFocus) _validateFirstName();
    });
    _lastNameFocus.addListener(() {
      if (!_lastNameFocus.hasFocus) _validateLastName();
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _validateEmail();
    });
    _mobileFocus.addListener(() {
      if (!_mobileFocus.hasFocus) _validateMobile();
    });
  }

  void _validateFirstName() {
    setState(() {
      if (_firstNameController.text.isNotEmpty &&
          !RegExp(r'^[a-zA-Z\s]+$').hasMatch(_firstNameController.text)) {
        _firstNameError = 'Letters only';
      } else {
        _firstNameError = null;
      }
    });
  }

  void _validateLastName() {
    setState(() {
      if (_lastNameController.text.isNotEmpty &&
          !RegExp(r'^[a-zA-Z\s]+$').hasMatch(_lastNameController.text)) {
        _lastNameError = 'Letters only';
      } else {
        _lastNameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = 'Email required';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text)) {
        _emailError = 'Invalid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validateMobile() {
    setState(() {
      if (_mobileController.text.isNotEmpty) {
        if (!RegExp(r'^\d+$').hasMatch(_mobileController.text)) {
          _mobileError = 'Digits only';
        } else if (_mobileController.text.length < 10) {
          _mobileError = 'Min 10 digits';
        } else {
          _mobileError = null;
        }
      } else {
        _mobileError = null;
      }
    });
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await ref.read(userProvider.notifier).getRoles();
      setState(() {
        _roles = roles;
        if (widget.user != null) {
          _selectedRole = roles
              .where((r) => r.id == widget.user!.roleId)
              .firstOrNull;
        }
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
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
    _companyAutocompleteController.dispose();
    _timeoutController.dispose();
    _companyFocusNode.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_usernameController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Username is required')),
      );
      return;
    }

    if (_selectedRole == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Role is required')));
      return;
    }

    // First Name Validation
    if (_firstNameController.text.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_firstNameController.text)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('First name should only contain letters')),
        );
        return;
      }
    }

    // Last Name Validation
    if (_lastNameController.text.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_lastNameController.text)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Last name should only contain letters')),
        );
        return;
      }
    }

    // Email Validation
    if (_emailController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email address is required')),
      );
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    // Mobile Validation
    if (_mobileController.text.isNotEmpty) {
      if (!RegExp(r'^\d+$').hasMatch(_mobileController.text)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mobile number should only contain digits')),
        );
        return;
      }
      if (_mobileController.text.length < 10) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mobile number must be at least 10 digits')),
        );
        return;
      }
    }

    if (widget.user == null && _passwordController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password is required for new users')),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final request = UserCreateRequest(
      username: _usernameController.text,
      email: _emailController.text,
      firstName: _firstNameController.text.isEmpty
          ? null
          : _firstNameController.text,
      lastName: _lastNameController.text.isEmpty
          ? null
          : _lastNameController.text,
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      roleId: _selectedRole!.id,
      companyId: _selectedCompany?.id ?? widget.user?.companyId,
      mobileNumber: _mobileController.text.isEmpty
          ? null
          : _mobileController.text,
      status: _status,
      sessionHours: int.tryParse(_timeoutController.text) ?? 24,
      sessionMinutes: 0,
      rosterGroupId: widget.user?.rosterGroupId,
    );

    final currentUser = ref.read(userProvider).currentUser;
    if (widget.user != null && currentUser?.roleId == 2 && widget.user!.roleId == 1) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Admin role users cannot edit SuperAdmin accounts'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userNotifier = ref.read(userProvider.notifier);
    bool success;

    if (widget.user != null) {
      success = await userNotifier.updateUser(widget.user!.userId, request);
    } else {
      success = await userNotifier.createUser(request);
    }

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.user != null
                  ? 'User updated successfully'
                  : 'User created successfully',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorMsg = ref.read(userProvider).error ?? 'Failed to save user';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final currentUser = userState.currentUser;
    final isReadOnly = widget.user != null &&
        currentUser?.roleId == 2 &&
        widget.user!.roleId == 1;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SafeArea(
          child: SizedBox(
            width: isMobile ? double.infinity : 600,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                      vertical: isMobile ? 24 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user != null
                                        ? 'Edit User'
                                        : 'Register New User',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Manage user profiles, roles, and access permissions.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 22),
                              color: const Color(0xFF6B7280),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (isReadOnly) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Admin role users cannot edit SuperAdmin accounts.',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF991B1B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        _buildInfoBar(),
                        const SizedBox(height: 48),



                        _buildLabelField(
                          'USERNAME*',
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _usernameController,
                                  hint: 'e.g. john_doe',
                                ),
                              ),
                              if (ref.read(userProvider).currentUser?.roleId == 2 && _selectedCompany != null) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Text(
                                    '@${_selectedCompany!.name}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (isMobile) ...[
                          _buildLabelField(
                            'FIRST NAME',
                            AppTextField(
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              hint: 'First Name',
                              errorText: _firstNameError,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabelField(
                            'LAST NAME',
                            AppTextField(
                              controller: _lastNameController,
                              focusNode: _lastNameFocus,
                              hint: 'Last Name',
                              errorText: _lastNameError,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]')),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'FIRST NAME',
                                  AppTextField(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    hint: 'First Name',
                                    errorText: _firstNameError,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z\s]')),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'LAST NAME',
                                  AppTextField(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    hint: 'Last Name',
                                    errorText: _lastNameError,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z\s]')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        if (isMobile) ...[
                          _buildLabelField(
                            'EMAIL ADDRESS*',
                            AppTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hint: 'john@example.com',
                              errorText: _emailError,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabelField(
                            'MOBILE NUMBER',
                            AppTextField(
                              controller: _mobileController,
                              focusNode: _mobileFocus,
                              hint: '+1 234 567 890',
                              errorText: _mobileError,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'EMAIL ADDRESS*',
                                  AppTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    hint: 'john@example.com',
                                    errorText: _emailError,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'MOBILE NUMBER',
                                  AppTextField(
                                    controller: _mobileController,
                                    focusNode: _mobileFocus,
                                    hint: '+1 234 567 890',
                                    errorText: _mobileError,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        if (isMobile) ...[
                          _buildLabelField(
                            widget.user != null ? 'PASSWORD' : 'PASSWORD*',
                            AppTextField(
                              controller: _passwordController,
                              hint: '••••••••',
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabelField(
                            widget.user != null ? 'CONFIRM PASSWORD' : 'CONFIRM PASSWORD*',
                            AppTextField(
                              controller: _confirmPasswordController,
                              hint: '••••••••',
                              obscureText: true,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  widget.user != null ? 'PASSWORD' : 'PASSWORD*',
                                  AppTextField(
                                    controller: _passwordController,
                                    hint: '••••••••',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  widget.user != null ? 'CONFIRM PASSWORD' : 'CONFIRM PASSWORD*',
                                  AppTextField(
                                    controller: _confirmPasswordController,
                                    hint: '••••••••',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        if (isMobile) ...[
                          _buildLabelField(
                            'ACCOUNT ROLE*',
                            _isLoadingRoles
                                ? const LinearProgressIndicator(
                              minHeight: 2,
                            )
                                : AppDropdown<Role>(
                              value: _selectedRole,
                              items: _roles ?? [],
                              itemLabel: (r) => r.name,
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v),
                              hint: 'Select Role',
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabelField(
                            'TIMEOUT (HOURS)',
                            AppTextField(
                              controller: _timeoutController,
                              hint: 'e.g. 24',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLabelField(
                                  'ACCOUNT ROLE*',
                                  _isLoadingRoles
                                      ? const LinearProgressIndicator(
                                    minHeight: 2,
                                  )
                                      : AppDropdown<Role>(
                                    value: _selectedRole,
                                    items: _roles ?? [],
                                    itemLabel: (r) => r.name,
                                    onChanged: (v) =>
                                        setState(() => _selectedRole = v),
                                    hint: 'Select Role',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'TIMEOUT (HOURS)',
                                  AppTextField(
                                    controller: _timeoutController,
                                    hint: 'e.g. 24',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 48),

                        // Status Selector
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF3F4F6),
                            ),
                          ),
                          child: isMobile
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCOUNT STATUS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: primary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set the operational status of this user account.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatusToggle(
                                      1,
                                      'Active',
                                      const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatusToggle(
                                      0,
                                      'Inactive',
                                      const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                              : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ACCOUNT STATUS',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: primary,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Set the operational status of this user account.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _buildStatusToggle(
                                1,
                                'Active',
                                const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusToggle(
                                0,
                                'Inactive',
                                const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 64),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (userState.isProcessing || isReadOnly) ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: userState.isProcessing
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : Text(
                              widget.user != null
                                  ? 'UPDATE USER'
                                  : 'REGISTER USER',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (userState.isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildStatusToggle(int value, String label, Color activeColor) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFD1D5DB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE1FF)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure user credentials, profile information, and access control.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompanyAutocomplete() {
    return AppTextField(
      controller: _companyAutocompleteController,
      readOnly: true,
      hint: 'Company',
    );
  }
}
