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
      final h = widget.user!.sessionHours ?? 24;
      final m = widget.user!.sessionMinutes ?? 0;
      _timeoutController.text = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      if (widget.user!.companyId != null && widget.user!.companyName != null) {
        _selectedCompany = CompanyAutocomplete(
          id: widget.user!.companyId!,
          name: widget.user!.companyName!,
        );
      }
    } else {
      _timeoutController.text = '24:00';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider).currentUser;
      if (currentUser != null && currentUser.roleId != 1) {
        if (widget.user == null) {
          setState(() {
            _selectedCompany = CompanyAutocomplete(
              id: currentUser.companyId!,
              name: currentUser.companyName!,
            );
            _companyAutocompleteController.text = currentUser.companyName!;
          });
        }
      }
    });

    _loadRoles();
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

  Future<void> _selectTime() async {
    final currentText = _timeoutController.text;
    TimeOfDay? initialTime;

    if (currentText.contains(':')) {
      final parts = currentText.split(':');
      final h = int.tryParse(parts[0]) ?? 24;
      final m = int.tryParse(parts[1]) ?? 0;
      initialTime = TimeOfDay(hour: h % 24, minute: m % 60);
    } else {
      initialTime = const TimeOfDay(hour: 0, minute: 0);
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF141E7A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _timeoutController.text =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        });
      }
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
      sessionHours: int.tryParse(_timeoutController.text.split(':')[0]) ?? 24,
      sessionMinutes: int.tryParse(_timeoutController.text.split(':').length > 1 ? _timeoutController.text.split(':')[1] : '0') ?? 0,
    );

    final userNotifier = ref.read(userProvider.notifier);
    bool success;

    if (widget.user != null) {
      success = await userNotifier.updateUser(widget.user!.userId, request);
    } else {
      success = await userNotifier.createUser(request);
      if (success) {
        // ... handled inside notifier if needed, or if we need the ID here later
      }
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 48,
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
                          _buildInfoBar(),
                          const SizedBox(height: 48),
                          _buildLabelField(
                            'PRIMARY COMPANY',
                            _buildCompanyAutocomplete(),
                          ),
                          const SizedBox(height: 24),

                          _buildLabelField(
                            'USERNAME*',
                            AppTextField(
                              controller: _usernameController,
                              hint: 'e.g. john_doe',
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'FIRST NAME',
                                  AppTextField(
                                    controller: _firstNameController,
                                    hint: 'First Name',
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
                                    hint: 'Last Name',
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z\s]')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'EMAIL ADDRESS',
                                  AppTextField(
                                    controller: _emailController,
                                    hint: 'john@example.com',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'MOBILE NUMBER',
                                  AppTextField(
                                    controller: _mobileController,
                                    hint: '+1 234 567 890',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'PASSWORD',
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
                                  'CONFIRM PASSWORD',
                                  AppTextField(
                                    controller: _confirmPasswordController,
                                    hint: '••••••••',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

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
                                  'TIMEOUT',
                                  AppTextField(
                                    controller: _timeoutController,
                                    hint: '24:00',
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.access_time_rounded,
                                        size: 20,
                                        color: Color(0xFF141E7A),
                                      ),
                                      onPressed: _selectTime,
                                    ),
                                    onTap: _selectTime,
                                    readOnly: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            child: Row(
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
                                          color: const Color(0xFF141E7A),
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
                              onPressed: userState.isProcessing ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF141E7A),
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
            ],
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
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF141E7A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure user credentials, profile information, and access control.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF141E7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAutocomplete() {
    final currentUser = ref.read(userProvider).currentUser;
    // Allow both Super Admin (1) and Company Admin (2) to edit the company
    if (currentUser?.roleId != 1 && currentUser?.roleId != 2) {
      return AppTextField(
        controller: _companyAutocompleteController,
        readOnly: true,
        hint: 'Company',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<CompanyAutocomplete>(
        focusNode: _companyFocusNode,
        textEditingController: _companyAutocompleteController,
        optionsBuilder: (TextEditingValue v) => v.text.isEmpty
            ? <CompanyAutocomplete>[]
            : ref.read(userProvider.notifier).searchCompanies(v.text),
        displayStringForOption: (o) => o.name,
        fieldViewBuilder: (context, controller, focus, onSubmitted) =>
            AppTextField(
              controller: controller,
              focusNode: focus,
              hint: 'Company',
            ),
        onSelected: (o) => setState(() => _selectedCompany = o),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: constraints.maxWidth,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(options.elementAt(i).name),
                  onTap: () => onSelected(options.elementAt(i)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
