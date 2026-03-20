import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/user/presentation/model/user_model.dart';
import 'package:air_water/features/user/presentation/controller/user_provider.dart';
import 'package:air_water/features/message_template/presentation/controller/message_template_provider.dart';
import 'package:air_water/features/message_template/presentation/model/message_template_model.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';

class RosterUserEditor extends ConsumerStatefulWidget {
  final int rosterId;
  final RosterMember? member;
  const RosterUserEditor({super.key, required this.rosterId, this.member});

  @override
  ConsumerState<RosterUserEditor> createState() => _RosterUserEditorState();
}

class _RosterUserEditorState extends ConsumerState<RosterUserEditor> {
  Role? _selectedRole;
  User? _selectedUser;
  bool _enabled = true;
  bool _emailEnabled = false;
  bool _pushEnabled = false;
  MessageTemplate? _selectedTemplate;
  final _emailController = TextEditingController();
  bool _isLoading = false;

  List<Role> _roles = [];
  List<User> _allUsers = [];
  List<MessageTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _enabled = widget.member!.enabled == 1;
      _emailEnabled = widget.member!.emailNotif == 1;
      _pushEnabled = widget.member!.pushNotif == 1;
      _emailController.text = widget.member!.email ?? '';
    }
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final templateRepo = ref.read(messageTemplateRepositoryProvider);
      
      final roles = await userNotifier.getRoles();
      await userNotifier.loadUsers();
      final users = ref.read(userProvider).users;
      final templates = await templateRepo.getActiveTemplates();
      final rosterMembers = await ref.read(roasterNotifierProvider.notifier).getRosterMembers(widget.rosterId);

      if (mounted) {
        setState(() {
          final assignedRoleIds = rosterMembers.map((m) => m.roleId).whereType<int>().toSet();
          _roles = roles.where((r) => assignedRoleIds.contains(r.id)).toList();
          _allUsers = users;
          _templates = templates;
          
          if (widget.member != null) {
            _selectedRole = _roles.where((r) => r.id == widget.member!.roleId).firstOrNull;
            _selectedUser = _allUsers.where((u) => u.userId == widget.member!.userId).firstOrNull;
            _selectedTemplate = _templates.where((t) => t.id == widget.member!.messageTemplateId).firstOrNull;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedUser == null && widget.member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    final data = {
      'roster_id': widget.rosterId,
      'user_id': widget.member?.userId ?? _selectedUser!.userId,
      'role_id': _selectedRole?.id,
      'enabled': _enabled ? 1 : 0,
      'email_notif': _emailEnabled ? 1 : 0,
      'push_notif': _pushEnabled ? 1 : 0,
      'email': _emailController.text.trim(),
      'message_template_id': _selectedTemplate?.id,
    };

    bool success;
    if (widget.member != null) {
      success = await ref.read(roasterNotifierProvider.notifier).updateMember(widget.member!.id!, data);
    } else {
      success = await ref.read(roasterNotifierProvider.notifier).addMember(data);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),
              _buildHeader(),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInformationSection(),
                        const SizedBox(height: 32),
                        _buildEmailSection(),
                        const SizedBox(height: 32),
                        _buildPushSection(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Roster User Editor',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Save & Close',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInformationSection() {
    return _buildSection(
      'User Information',
      Column(
        children: [
          _buildFieldRow('Role', AppDropdown<Role>(
            value: _selectedRole,
            items: _roles,
            hint: 'Select Role...',
            itemLabel: (r) => r.name,
            onChanged: (v) {
              setState(() {
                _selectedRole = v;
                _selectedUser = null;
              });
            },
          )),
          const SizedBox(height: 24),
          _buildFieldRow('Username', AppDropdown<User>(
            value: _selectedUser,
            items: _selectedRole == null 
                ? [] 
                : _allUsers.where((u) => u.roleId == _selectedRole!.id).toList(),
            hint: 'Select User...',
            itemLabel: (u) => u.username,
            onChanged: (v) => setState(() => _selectedUser = v),
            enabled: _selectedRole != null,
          )),
          const SizedBox(height: 24),
          _buildToggleRow('Enabled', _enabled, (v) => setState(() => _enabled = v)),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return _buildSection(
      'Email',
      Column(
        children: [
          _buildToggleRow('Enabled', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
          const SizedBox(height: 24),
          _buildFieldRow(
            'Email',
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'user@example.com',
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFieldRow('Message Template', AppDropdown<MessageTemplate>(
            value: _selectedTemplate,
            items: _templates,
            hint: 'Select Template...',
            itemLabel: (t) => t.name,
            onChanged: (v) => setState(() => _selectedTemplate = v),
          )),
        ],
      ),
    );
  }

  Widget _buildPushSection() {
    return _buildSection(
      'Mobile Push Notifications',
      _buildToggleRow('Enabled', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildFieldRow(String label, Widget field) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF141E7A),
        ),
        const SizedBox(width: 12),
        Text(
          value ? 'Yes' : 'No',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        ),
      ],
    );
  }
}
