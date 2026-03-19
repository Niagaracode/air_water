import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/user/presentation/controller/user_provider.dart';
import 'package:air_water/shared/widgets/app_loader.dart';

class ManageParametersModal extends ConsumerStatefulWidget {
  final Roaster roaster;
  const ManageParametersModal({super.key, required this.roaster});

  @override
  ConsumerState<ManageParametersModal> createState() => _ManageParametersModalState();
}

class _ManageParametersModalState extends ConsumerState<ManageParametersModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _availableParameters = ['LEVEL', 'BATTERY', 'PRESSURE', 'TEMPERATURE', 'FLOW', 'TAG', 'OTHER'];
  
  final List<Map<String, dynamic>> _workingAssignments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingAssignments();
  }

  Future<void> _loadExistingAssignments() async {
    await ref.read(roasterNotifierProvider.notifier).selectRoaster(widget.roaster.id);
    final selected = ref.read(roasterNotifierProvider).selectedRoaster;
    if (selected != null) {
      setState(() {
        _workingAssignments.addAll(selected.assignments.map((e) => e.toJson()));
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref.read(roasterNotifierProvider.notifier).assignParameters(
      roasterId: widget.roaster.id,
      assignments: _workingAssignments,
    );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parameters assigned successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        child: SizedBox(
          width: 850,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRoleTab(),
                        _buildUserTab(),
                      ],
                    ),
                    if (state.isProcessing && state.selectedRoaster == null) const AppLoader(message: 'Loading...'),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          const Icon(Icons.settings_input_component_outlined, color: Color(0xFF141E7A), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Parameters: ${widget.roaster.name}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700)),
                Text('Select parameters to display for particular roles or users.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF141E7A),
        indicatorColor: const Color(0xFF141E7A),
        tabs: const [Tab(text: 'ROLE-BASED ASSIGNMENT'), Tab(text: 'USER-SPECIFIC OVERRIDES')],
      ),
    );
  }

  Widget _buildRoleTab() {
    final List<Map<String, dynamic>> roles = [
      {'id': 1, 'name': 'SUPER_ADMIN'},
      {'id': 2, 'name': 'ORG_ADMIN'},
      {'id': 3, 'name': 'PLANT_MANAGER'},
      {'id': 4, 'name': 'OPERATOR'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return _buildAssignmentRow(
          title: role['name'],
          onToggle: (param, value) {
            setState(() {
              _workingAssignments.removeWhere((a) => a['role_id'] == role['id'] && a['parameter_name'] == param);
              if (value) _workingAssignments.add({'role_id': role['id'], 'parameter_name': param});
            });
          },
          isAssigned: (param) => _workingAssignments.any((a) => a['role_id'] == role['id'] && a['parameter_name'] == param),
        );
      },
    );
  }

  Widget _buildUserTab() {
    final users = ref.watch(userProvider).users;
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildAssignmentRow(
          title: user.username,
          subtitle: user.roleName,
          onToggle: (param, value) {
            setState(() {
              _workingAssignments.removeWhere((a) => a['user_id'] == user.userId && a['parameter_name'] == param);
              if (value) _workingAssignments.add({'user_id': user.userId, 'parameter_name': param});
            });
          },
          isAssigned: (param) => _workingAssignments.any((a) => a['user_id'] == user.userId && a['parameter_name'] == param),
        );
      },
    );
  }

  Widget _buildAssignmentRow({required String title, String? subtitle, required Function(String, bool) onToggle, required bool Function(String) isAssigned}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              if (subtitle != null) ...[const SizedBox(width: 8), Text('($subtitle)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)))],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableParameters.map((param) {
              final active = isAssigned(param);
              return FilterChip(
                label: Text(param, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF64748B))),
                selected: active,
                onSelected: (v) => onToggle(param, v),
                selectedColor: const Color(0xFF141E7A),
                checkmarkColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141E7A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('SAVE PARAMETER ASSIGNMENTS'),
          ),
        ],
      ),
    );
  }
}
