import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/asset_group_provider.dart';
import '../../domain/models/asset_group_model.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';

class AssetGroupEditPage extends ConsumerStatefulWidget {
  final AssetGroupModel? group;
  const AssetGroupEditPage({super.key, this.group});

  @override
  ConsumerState<AssetGroupEditPage> createState() => _AssetGroupEditPageState();
}

class _AssetGroupEditPageState extends ConsumerState<AssetGroupEditPage> {
  final _formKey = GlobalKey<FormState>();
  List<AssetCriteria> _criteria = [];
  List<AssetGroupUser> _assignedUsers = [];
  User? _selectedUserForAssignment;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _displayInTree = true;
  int _initialCriteriaCount = 0;

  final List<String> _parameters = [
    'Asset Description', 'City', 'Country', 'Customer Name', 'DeviceID', 'Product Name', 'Site Name', 'State or Province', 'Tank Name'
  ];
  final List<String> _logics = ['Like', '=', '!=', 'Is Empty'];
  final List<String> _operators = ['And', 'Or', 'None'];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _criteria = List.from(widget.group!.criteria);
      _initialCriteriaCount = _criteria.length;
      _assignedUsers = List.from(widget.group!.users ?? []);
      _nameController = TextEditingController(text: widget.group!.name);
      _descriptionController = TextEditingController(text: widget.group!.description);
      _displayInTree = widget.group!.displayInTree;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _displayInTree = true;
    }
    if (_criteria.isEmpty) {
      _addCriteria();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  void _addCriteria() {
    setState(() {
      _criteria.add(AssetCriteria(parameter: 'Asset Description', logic: 'Like', value: '', operator: 'And'));
    });
  }

  void _removeCriteria(int index) {
    if (_criteria.length <= 1) {
      // If last rule, just reset it instead of removing
      setState(() {
        _criteria[0] = AssetCriteria(parameter: 'Asset Description', logic: 'Like', value: '', operator: 'And');
      });
      return;
    }
    setState(() {
      _criteria.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newGroup = AssetGroupModel(
      id: widget.group?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      displayInTree: _displayInTree,
      criteria: _criteria,
    );

    print('DEBUG: Number of criteria to save: ${_criteria.length}');
    print('DEBUG: Saving Group Data: ${jsonEncode(newGroup.toJson())}');
    print('DEBUG: Assigned Users: ${jsonEncode(_assignedUsers.map((u) => u.toJson()).toList())}');

    final success = await ref.read(assetGroupProvider.notifier).saveGroup(newGroup, users: _assignedUsers);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset Group saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final companyState = ref.watch(companyNotifierProvider);
    final productState = ref.watch(productListProvider);
    final siteState = ref.watch(siteNotifierProvider);
    final deviceState = ref.watch(deviceProvider);
    final tankState = ref.watch(tankProvider);
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.group == null ? 'Create Asset Group' : 'Edit Asset Group', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: state.isProcessing ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141E7A)),
              child: state.isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE GROUP'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralSection(),
              const SizedBox(height: 32),
              _buildCriteriaSection(),
              const SizedBox(height: 32),
              _buildUserSection(userState),
              const SizedBox(height: 48),
              if (widget.group?.id != null)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _showPreviewDialog,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('PREVIEW MATCHING ASSETS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(UserState userState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'User Access Control',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_assignedUsers.length} Users Assigned',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF141E7A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('USERNAME', style: _headerStyle)),
                Expanded(flex: 1, child: Text('IS DEFAULT?', style: _headerStyle)),
                Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
                Expanded(flex: 2, child: Text('FIRST NAME', style: _headerStyle)),
                Expanded(flex: 2, child: Text('LAST NAME', style: _headerStyle)),
                Expanded(flex: 1, child: Center(child: Text('SECURITY', style: _headerStyle))),
                const SizedBox(width: 48, child: Center(child: Icon(Icons.settings, size: 14, color: Color(0xFF6B7280)))),
              ],
            ),
          ),

          // User Rows
          if (_assignedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text('No users assigned to this group.', style: GoogleFonts.inter(color: Colors.grey.shade500)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignedUsers.length,
              itemBuilder: (context, index) {
                final assignment = _assignedUsers[index];
                final user = userState.users.firstWhere((u) => u.userId == assignment.userId, orElse: () => User(userId: assignment.userId, username: assignment.username, email: '', roleId: 0, status: 1));
                
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(user.username, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                      Expanded(
                        flex: 1, 
                        child: InkWell(
                          onTap: () => setState(() => assignment.isDefault = !assignment.isDefault),
                          child: Text(assignment.isDefault ? 'Yes' : 'No', style: GoogleFonts.inter(fontSize: 13, color: assignment.isDefault ? Colors.green : Colors.grey)),
                        )
                      ),
                      Expanded(flex: 2, child: Text(user.roleName ?? 'User', style: GoogleFonts.inter(fontSize: 13))),
                      Expanded(flex: 2, child: Text(user.firstName ?? '-', style: GoogleFonts.inter(fontSize: 13))),
                      Expanded(flex: 2, child: Text(user.lastName ?? '-', style: GoogleFonts.inter(fontSize: 13))),
                      Expanded(
                        flex: 1, 
                        child: Center(
                          child: Checkbox(
                            value: assignment.defaultSecurity,
                            onChanged: (v) => setState(() => assignment.defaultSecurity = v ?? false),
                            activeColor: const Color(0xFF141E7A),
                          ),
                        )
                      ),
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          onPressed: () => setState(() => _assignedUsers.removeAt(index)),
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Add User Controls
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<User>(
                  value: _selectedUserForAssignment,
                  hint: const Text('Select User'),
                  items: userState.users.where((u) {
                    final isAlreadyAssigned = _assignedUsers.any((au) => au.userId == u.userId);
                    final isCustomer = u.roleName?.toLowerCase() == 'customer';
                    return !isAlreadyAssigned && !isCustomer;
                  }).map((u) {
                    return DropdownMenuItem(value: u, child: Text(u.username, style: GoogleFonts.inter(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedUserForAssignment = v),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(),
                    fillColor: Color(0xFFF9FAFB),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedUserForAssignment == null ? null : () {
                  setState(() {
                    _assignedUsers.add(AssetGroupUser(
                      userId: _selectedUserForAssignment!.userId,
                      username: _selectedUserForAssignment!.username,
                    ));
                    _selectedUserForAssignment = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF141E7A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: value ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog() async {
    await ref.read(assetGroupProvider.notifier).loadPreview(widget.group!.id!);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final preview = ref.watch(assetGroupProvider).previewAssets;
          return AlertDialog(
            title: const Text('Matching Assets Preview'),
            content: SizedBox(
              width: 600,
              height: 400,
              child: preview.isEmpty 
                ? const Center(child: Text('No assets match the current criteria.'))
                : ListView.builder(
                    itemCount: preview.length,
                    itemBuilder: (context, index) {
                      final asset = preview[index];
                      return ListTile(
                        leading: const Icon(Icons.storage),
                        title: Text(asset['tank_number'] ?? 'Unnamed Tank'),
                        subtitle: Text('${asset['plant_name']} - ${asset['city_name']}'),
                        trailing: Text(asset['device_id'] ?? '-'),
                      );
                    },
                  ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.layers_rounded, color: Color(0xFF141E7A), size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'General Information',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              _buildTreeToggle(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Name',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      readOnly: widget.group != null,
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: widget.group != null ? const Color(0xFF6B7280) : const Color(0xFF111827),
                        fontWeight: widget.group != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter group name...',
                        border: const OutlineInputBorder(),
                        filled: widget.group != null,
                        fillColor: widget.group != null ? const Color(0xFFF9FAFB) : Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      readOnly: widget.group != null,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: widget.group != null ? const Color(0xFF6B7280) : const Color(0xFF111827),
                        fontWeight: widget.group != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe the purpose of this group...',
                        border: const OutlineInputBorder(),
                        filled: widget.group != null,
                        fillColor: widget.group != null ? const Color(0xFFF9FAFB) : Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreeToggle() {
    return InkWell(
      onTap: () => setState(() => _displayInTree = !_displayInTree),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _displayInTree ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _displayInTree ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _displayInTree ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 14,
              color: _displayInTree ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              _displayInTree ? 'VISIBLE IN TREE' : 'HIDDEN IN TREE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _displayInTree ? const Color(0xFF059669) : const Color(0xFFDC2626),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeStatusBadge(bool visible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visible ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visible ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visible ? Icons.account_tree_outlined : Icons.account_tree_rounded,
            size: 14,
            color: visible ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            visible ? 'VISIBLE IN TREE' : 'HIDDEN IN TREE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: visible ? const Color(0xFF059669) : const Color(0xFFDC2626),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset Selection Criteria',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define the dynamic rules that populate this group.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _criteria.clear();
                        _addCriteria();
                      });
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('CLEAR ALL'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addCriteria,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('ADD RULE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF141E7A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCriteriaHeader(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _criteria.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) => _buildCriteriaRow(index),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PARAMETER', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text('LOGIC', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text('VALUE', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('AND/OR', style: _headerStyle)),
          const SizedBox(width: 12),
          const SizedBox(width: 48, child: Center(child: Text('CLEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280))))),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF6B7280),
    letterSpacing: 0.5,
  );

  Widget _buildCriteriaValueField(int index) {
    final rule = _criteria[index];
    
    if (rule.parameter == 'Customer Name') {
      final companies = ref.watch(companyNotifierProvider).groupedCompanies.map((g) {
        final companyId = g.addresses.isNotEmpty ? g.addresses.first.companyId : null;
        return {'id': companyId?.toString() ?? '', 'name': g.name};
      }).where((c) => c['id'] != '').toList();
      companies.sort((a, b) => a['name']!.compareTo(b['name']!));
      
      final currentValue = companies.any((c) => c['id'] == rule.value) ? rule.value : (companies.isNotEmpty ? companies.first['id'] : '');
      if (rule.value.isEmpty && companies.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = companies.first['id']!));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && companies.isNotEmpty ? companies.first['id'] : (companies.any((c) => c['id'] == rule.value) ? rule.value : null),
        items: companies.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['name']!, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Customer'),
      );
    }
    
    if (rule.parameter == 'Product Name') {
      final products = ref.watch(productListProvider).value?.map((p) => {
        'id': p.id.toString(),
        'name': p.name
      }).toList() ?? [];
      products.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (rule.value.isEmpty && products.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = products.first['id']!));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && products.isNotEmpty ? products.first['id'] : (products.any((p) => p['id'] == rule.value) ? rule.value : null),
        items: products.map((p) => DropdownMenuItem<String>(value: p['id'] as String, child: Text(p['name']!, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Product'),
      );
    }

    if (rule.parameter == 'City') {
      final companyCities = ref.watch(companyNotifierProvider).groupedCompanies.expand((g) => g.addresses).map((a) => a.city).whereType<String>();
      final siteCities = ref.watch(siteNotifierProvider).groupedSites.expand((g) => g.addresses).map((a) => a.city).whereType<String>();
      final cities = <String>{...companyCities, ...siteCities}.toList()..sort();

      if (rule.value.isEmpty && cities.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = cities.first));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && cities.isNotEmpty ? cities.first : (cities.contains(rule.value) ? rule.value : null),
        items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select City'),
      );
    }

    if (rule.parameter == 'Country') {
      final companyCountries = ref.watch(companyNotifierProvider).groupedCompanies.expand((g) => g.addresses).map((a) => a.country).whereType<String>();
      final siteCountries = ref.watch(siteNotifierProvider).groupedSites.expand((g) => g.addresses).map((a) => a.country).whereType<String>();
      final countries = <String>{...companyCountries, ...siteCountries}.toList()..sort();

      if (rule.value.isEmpty && countries.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = countries.first));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && countries.isNotEmpty ? countries.first : (countries.contains(rule.value) ? rule.value : null),
        items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Country'),
      );
    }

    if (rule.parameter == 'State or Province') {
      final companyStates = ref.watch(companyNotifierProvider).groupedCompanies.expand((g) => g.addresses).map((a) => a.state).whereType<String>();
      final siteStates = ref.watch(siteNotifierProvider).groupedSites.expand((g) => g.addresses).map((a) => a.state).whereType<String>();
      final states = <String>{...companyStates, ...siteStates}.toList()..sort();

      if (rule.value.isEmpty && states.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = states.first));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && states.isNotEmpty ? states.first : (states.contains(rule.value) ? rule.value : null),
        items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select State/Province'),
      );
    }

    if (rule.parameter == 'DeviceID') {
      final devices = ref.watch(deviceProvider).groupedDevices
          .expand((g) => g.devices)
          .map((d) => {
            'id': d.id.toString(),
            'name': d.deviceId
          })
          .toList();
      devices.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      if (rule.value.isEmpty && devices.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = devices.first['id']!));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && devices.isNotEmpty ? devices.first['id'] : (devices.any((d) => d['id'] == rule.value) ? rule.value : null),
        items: devices.map((d) => DropdownMenuItem<String>(value: d['id'] as String, child: Text(d['name'] ?? '', style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Device ID'),
      );
    }

    if (rule.parameter == 'Site Name') {
      final siteState = ref.watch(siteNotifierProvider);
      final sites = siteState.groupedSites.map((g) => g.name).toSet().toList()..sort();

      if (sites.isEmpty && siteState.isLoading) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [DropdownMenuItem(value: null, child: Text('Loading sites...', style: TextStyle(color: Colors.grey)))],
          onChanged: null,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Site Name'),
        );
      }

      if (sites.isEmpty) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [DropdownMenuItem(value: null, child: Text('No sites found'))],
          onChanged: null,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Site Name'),
        );
      }

      if (rule.value.isEmpty && sites.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = sites.first));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && sites.isNotEmpty ? sites.first : (sites.contains(rule.value) ? rule.value : null),
        items: sites.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Site Name'),
      );
    }

    if (rule.parameter == 'Tank Name') {
      final tankState = ref.watch(tankProvider);
      final tanks = tankState.groupedTanks
          .expand((g) => g.tanks)
          .map((t) => {
            'id': t.tankId.toString(),
            'name': t.tankName ?? t.tankNumber
          })
          .toList();
      tanks.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (tanks.isEmpty && tankState.isLoading) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [DropdownMenuItem(value: null, child: Text('Loading tanks...', style: TextStyle(color: Colors.grey)))],
          onChanged: null,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Tank Name'),
        );
      }

      if (tanks.isEmpty) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [DropdownMenuItem(value: null, child: Text('No tanks found'))],
          onChanged: null,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Tank Name'),
        );
      }

      if (rule.value.isEmpty && tanks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = tanks.first['id']!));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && tanks.isNotEmpty ? tanks.first['id'] : (tanks.any((t) => t['id'] == rule.value) ? rule.value : null),
        items: tanks.map((t) => DropdownMenuItem<String>(value: t['id'] as String, child: Text(t['name']!, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Tank Name'),
      );
    }

    return TextFormField(
      initialValue: rule.value,
      key: ValueKey('rule_val_${index}_${rule.parameter}'),
      onChanged: (v) => setState(() => rule.value = v),
      decoration: const InputDecoration(
        border: OutlineInputBorder(), 
        labelText: 'Value',
      ),
    );
  }

  Widget _buildCriteriaRow(int index) {
    final rule = _criteria[index];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // 1. PARAMETER
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              value: rule.parameter,
              items: _parameters.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 13)))).toList(),
              onChanged: (v) {
                setState(() {
                  rule.parameter = v!;
                  rule.value = ''; 
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 2. LOGIC
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: rule.logic,
              items: _logics.map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.inter(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => rule.logic = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. VALUE
          Expanded(
            flex: 4,
            child: _buildCriteriaValueField(index),
          ),
          const SizedBox(width: 12),

          // 4. AND/OR
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: rule.operator,
              items: _operators.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF141E7A))))).toList(),
              onChanged: (v) => setState(() => rule.operator = v!),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(),
                fillColor: Color(0xFFF3F4FF),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 5. CLEAR (DELETE)
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _removeCriteria(index),
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
