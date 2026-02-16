import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../controller/user_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';

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

      // Set selected company if available
      if (widget.user!.companyId != null && widget.user!.companyName != null) {
        _selectedCompany = CompanyAutocomplete(
          id: widget.user!.companyId!,
          name: widget.user!.companyName!,
        );
      }
    }
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await ref.read(userProvider.notifier).getRoles();
      setState(() {
        _roles = roles;
        if (widget.user != null && widget.user!.roleId != null) {
          _selectedRole = roles.firstWhere(
            (r) => r.id == widget.user!.roleId,
            orElse: () => roles.first,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
    } finally {
      setState(() => _isLoadingRoles = false);
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
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_usernameController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('User Name is required')),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }

    if (widget.user == null && _passwordController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password is required')),
      );
      return;
    }

    if (widget.user == null &&
        _passwordController.text != _confirmPasswordController.text) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_selectedRole == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Role')),
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
      sessionTimeout: 86400,
    );

    final success = widget.user != null
        ? await ref
              .read(userProvider.notifier)
              .updateUser(widget.user!.userId, request)
        : await ref.read(userProvider.notifier).createUser(request);

    if (success && mounted) {
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.user != null
                ? 'User updated successfully'
                : 'User created successfully',
          ),
        ),
      );
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
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          width: 500,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(32),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user != null ? 'EDIT USER' : 'ADD USER',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildLabelField(
                            'User Name*',
                            AppTextField(
                              controller: _usernameController,
                              hint: 'Enter User Name',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'First Name*',
                                  AppTextField(
                                    controller: _firstNameController,
                                    hint: 'Enter First Name',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'Last Name*',
                                  AppTextField(
                                    controller: _lastNameController,
                                    hint: 'Enter Last Name',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'Mobile Number*',
                                  AppTextField(
                                    controller: _mobileController,
                                    hint: 'Enter Mobile Number',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'Email-ID*',
                                  AppTextField(
                                    controller: _emailController,
                                    hint: 'Enter Your Email',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Company',
                            _buildCompanyAutocomplete(),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  widget.user != null
                                      ? 'Enter Password'
                                      : 'Enter Password*',
                                  AppTextField(
                                    controller: _passwordController,
                                    hint: 'Enter Password',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  widget.user != null
                                      ? 'Re-Enter Password'
                                      : 'Re-Enter Password*',
                                  AppTextField(
                                    controller: _confirmPasswordController,
                                    hint: 'Re-Enter Password',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Role*',
                            _isLoadingRoles
                                ? const LinearProgressIndicator(minHeight: 2)
                                : AppDropdown<Role>(
                                    value: _selectedRole,
                                    items: _roles ?? [],
                                    itemLabel: (role) => role.name,
                                    hint: 'Select Role',
                                    onChanged: (v) =>
                                        setState(() => _selectedRole = v),
                                  ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    groupValue: _status,
                                    activeColor: const Color(0xFF1B1B4B),
                                    onChanged: (v) =>
                                        setState(() => _status = v!),
                                  ),
                                  const Text('ACTIVE'),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  Radio<int>(
                                    value: 0,
                                    groupValue: _status,
                                    activeColor: const Color(0xFF1B1B4B),
                                    onChanged: (v) =>
                                        setState(() => _status = v!),
                                  ),
                                  const Text('INACTIVE'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: userState.isProcessing ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1B4B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: userState.isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SAVE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              if (userState.isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<CompanyAutocomplete>(
          textEditingController: _companyAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<CompanyAutocomplete>.empty();
            }
            return await ref
                .read(userProvider.notifier)
                .searchCompanies(textEditingValue.text);
          },
          displayStringForOption: (CompanyAutocomplete option) => option.name,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Enter Your Company',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(() => _selectedCompany = option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B1B4B),
      ),
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFF1B1B4B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.user != null
                  ? 'Enter The User Name And Basic Details To Update The User.'
                  : 'Enter The User Name And Basic Details To Create A New User.',
              style: const TextStyle(color: Color(0xFF1B1B4B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
