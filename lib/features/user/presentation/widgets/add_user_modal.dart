import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../group/presentation/controller/group_provider.dart';
import '../../../group/presentation/model/group_model.dart';
import '../model/user_model.dart';
import '../controller/user_provider.dart';

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
  final _sessionTimeoutController = TextEditingController();
  final _companyFocusNode = FocusNode();

  List<Role>? _roles;
  Role? _selectedRole;
  CompanyAutocomplete? _selectedCompany;
  bool _isLoadingRoles = false;
  int _status = 1;

  // Group selection
  List<Group> _assignedGroups = [];
  bool _isLoadingGroups = false;

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
      _sessionTimeoutController.text = (widget.user!.sessionTimeout ?? 86400)
          .toString();

      if (widget.user!.companyId != null && widget.user!.companyName != null) {
        _selectedCompany = CompanyAutocomplete(
          id: widget.user!.companyId!,
          name: widget.user!.companyName!,
        );
      }
      _loadUserGroups();
    } else {
      _sessionTimeoutController.text = '86400';
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
      ref.read(groupProvider.notifier).loadGroups();
    });

    _loadRoles();
  }

  Future<void> _loadUserGroups() async {
    if (widget.user == null) return;
    setState(() => _isLoadingGroups = true);
    try {
      final groups = await ref
          .read(groupProvider.notifier)
          .getGroupsByUserId(widget.user!.userId);
      setState(() {
        _assignedGroups = groups;
      });
    } catch (e) {
      debugPrint('Error loading user groups: $e');
    } finally {
      setState(() => _isLoadingGroups = false);
    }
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
    _sessionTimeoutController.dispose();
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
      sessionTimeout: int.tryParse(_sessionTimeoutController.text) ?? 86400,
      assignedPlants: [],
      assignedTanks: [],
    );

    final userNotifier = ref.read(userProvider.notifier);
    bool success;
    int? userId;

    if (widget.user != null) {
      success = await userNotifier.updateUser(widget.user!.userId, request);
      userId = widget.user!.userId;
    } else {
      // For creation, we need the new ID. Let's assume the API returns it or it's handled.
      // In this specific codebase, we might need a way to get the ID from the state after creation.
      success = await userNotifier.createUser(request);
      // Wait for state update and find user by username if needed
      if (success) {
        final users = ref.read(userProvider).users;
        final newUser = users
            .where((u) => u.username == _usernameController.text)
            .firstOrNull;
        userId = newUser?.userId;
      }
    }

    if (success && userId != null) {
      await ref
          .read(groupProvider.notifier)
          .assignGroupsToUser(
            userId,
            _assignedGroups.map((g) => g.id).toList(),
          );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.user != null ? 'EDIT USER' : 'ADD USER',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(
                            'Username*',
                            AppTextField(
                              controller: _usernameController,
                              hint: 'Username',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabel(
                                  'First Name',
                                  AppTextField(
                                    controller: _firstNameController,
                                    hint: 'First Name',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabel(
                                  'Last Name',
                                  AppTextField(
                                    controller: _lastNameController,
                                    hint: 'Last Name',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabel(
                                  'Email',
                                  AppTextField(
                                    controller: _emailController,
                                    hint: 'Email',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabel(
                                  'Mobile',
                                  AppTextField(
                                    controller: _mobileController,
                                    hint: 'Mobile',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Company', _buildCompanyAutocomplete()),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabel(
                                  'Password',
                                  AppTextField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabel(
                                  'Confirm',
                                  AppTextField(
                                    controller: _confirmPasswordController,
                                    hint: 'Confirm',
                                    obscureText: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildLabel(
                                  'Role*',
                                  _isLoadingRoles
                                      ? const LinearProgressIndicator()
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
                                child: _buildLabel(
                                  'Timeout',
                                  AppTextField(
                                    controller: _sessionTimeoutController,
                                    hint: '86400',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Radio<int>(
                                value: 1,
                                groupValue: _status,
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                              const Text('ACTIVE'),
                              const SizedBox(width: 16),
                              Radio<int>(
                                value: 0,
                                groupValue: _status,
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                              const Text('INACTIVE'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
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
                      child: userState.isProcessing ? const SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildGroupSelection() {
    final groups = ref.watch(groupProvider).groups;
    if (_isLoadingGroups) return const LinearProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._assignedGroups.map(
              (g) => Chip(
                label: Text(g.name),
                onDeleted: () => setState(
                  () => _assignedGroups.removeWhere((x) => x.id == g.id),
                ),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add Group'),
              onPressed: () => _showGroupSelection(groups),
            ),
          ],
        ),
      ],
    );
  }

  void _showGroupSelection(List<Group> allGroups) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: allGroups.length,
        itemBuilder: (context, i) {
          final g = allGroups[i];
          final isSelected = _assignedGroups.any((x) => x.id == g.id);
          return ListTile(
            title: Text(g.name),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _assignedGroups.removeWhere((x) => x.id == g.id);
                } else {
                  _assignedGroups.add(g);
                }
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompanyAutocomplete() {
    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser?.roleId != 1) {
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
