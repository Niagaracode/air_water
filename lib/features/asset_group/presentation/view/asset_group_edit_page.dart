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
  List<User> _availableUsers = [];

  final List<String> _parameters = [
    'Asset Description', 'City', 'Country', 'Customer Name', 'DeviceID', 'Product Name', 'State or Province'
  ];
  final List<String> _logics = ['Like', '=', '!=', 'Is Empty'];
  final List<String> _operators = ['And', 'Or', 'None'];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _criteria = List.from(widget.group!.criteria);
      _assignedUsers = List.from(widget.group!.users ?? []);
    }
    if (_criteria.isEmpty) {
      _addCriteria();
    }
    _loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUsers() async {
    // Ensuring users are loaded from the userProvider
    await ref.read(userProvider.notifier).loadUsers();
    if(mounted) {
       setState(() {
         _availableUsers = ref.read(userProvider).users;
       });
    }
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
      name: widget.group?.name ?? '',
      description: widget.group?.description ?? '',
      displayInTree: widget.group?.displayInTree ?? true,
      criteria: _criteria,
    );

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
              _buildUserSection(),
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

  Widget _buildUserSection() {
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
          _availableUsers.isEmpty 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF141E7A)))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableUsers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _availableUsers[index];
                  final isAssigned = _assignedUsers.any((u) => u.userId == user.userId);
                  final assignment = isAssigned 
                      ? _assignedUsers.firstWhere((u) => u.userId == user.userId) 
                      : null;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isAssigned ? const Color(0xFFF9FAFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      activeColor: const Color(0xFF141E7A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: GoogleFonts.inter(
                          fontWeight: isAssigned ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(user.username, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(user.roleName ?? 'User', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                      value: isAssigned,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _assignedUsers.add(AssetGroupUser(
                              userId: user.userId,
                              username: user.username,
                            ));
                          } else {
                            _assignedUsers.removeWhere((u) => u.userId == user.userId);
                          }
                        });
                      },
                      secondary: isAssigned && assignment != null ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMiniBadge('DEFAULT SEC', assignment.defaultSecurity, (v) {
                            setState(() => assignment.defaultSecurity = v);
                          }),
                          const SizedBox(width: 8),
                          _buildMiniBadge('IS DEFAULT', assignment.isDefault, (v) {
                            setState(() => assignment.isDefault = v);
                          }),
                        ],
                      ) : null,
                    ),
                  );
                },
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
    final group = widget.group;
    if (group == null) return const SizedBox.shrink();

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.layers_rounded, color: Color(0xFF141E7A), size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildTreeStatusBadge(group.displayInTree),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  group.description.isEmpty ? 'No description available for this group.' : group.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      final companies = ref.watch(companyNotifierProvider).groupedCompanies.map((g) => g.name).toSet().toList();
      companies.sort();
      
      // Ensure the current value is valid for the dropdown
      final currentValue = companies.contains(rule.value) ? rule.value : (companies.isNotEmpty ? companies.first : '');
      if (rule.value != currentValue && companies.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => rule.value = currentValue);
        });
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && companies.isNotEmpty ? companies.first : (companies.contains(rule.value) ? rule.value : null),
        items: companies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Customer'),
      );
    }
    
    if (rule.parameter == 'Product Name') {
      final products = ref.watch(productListProvider).value?.map((p) => p.name).toSet().toList() ?? [];
      products.sort();

      // Ensure the current value is valid for the dropdown
      final currentValue = products.contains(rule.value) ? rule.value : (products.isNotEmpty ? products.first : '');
      if (rule.value != currentValue && products.isNotEmpty) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => rule.value = currentValue);
        });
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && products.isNotEmpty ? products.first : (products.contains(rule.value) ? rule.value : null),
        items: products.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Product'),
      );
    }

    if (rule.parameter == 'City') {
      final companyCities = ref.watch(companyNotifierProvider).groupedCompanies.expand((g) => g.addresses).map((a) => a.city).whereType<String>();
      final siteCities = ref.watch(siteNotifierProvider).groupedSites.expand((g) => g.addresses).map((a) => a.city).whereType<String>();
      final cities = <String>{...companyCities, ...siteCities}.toList()..sort();

      final currentValue = cities.contains(rule.value) ? rule.value : (cities.isNotEmpty ? cities.first : '');
      if (rule.value != currentValue && cities.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = currentValue));
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

      final currentValue = countries.contains(rule.value) ? rule.value : (countries.isNotEmpty ? countries.first : '');
      if (rule.value != currentValue && countries.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = currentValue));
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

      final currentValue = states.contains(rule.value) ? rule.value : (states.isNotEmpty ? states.first : '');
      if (rule.value != currentValue && states.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = currentValue));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && states.isNotEmpty ? states.first : (states.contains(rule.value) ? rule.value : null),
        items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select State/Province'),
      );
    }

    if (rule.parameter == 'DeviceID') {
      final devices = ref.watch(deviceProvider).groupedDevices.expand((g) => g.devices).map((d) => d.deviceId).toSet().toList()..sort();

      final currentValue = devices.contains(rule.value) ? rule.value : (devices.isNotEmpty ? devices.first : '');
      if (rule.value != currentValue && devices.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => rule.value = currentValue));
      }

      return DropdownButtonFormField<String>(
        value: rule.value.isEmpty && devices.isNotEmpty ? devices.first : (devices.contains(rule.value) ? rule.value : null),
        items: devices.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Select Device ID'),
      );
    }

    return TextFormField(
      initialValue: rule.value,
      key: ValueKey('rule_val_${index}_${rule.parameter}'),
      onChanged: (v) => setState(() => rule.value = v),
      decoration: InputDecoration(
        border: const OutlineInputBorder(), 
        labelText: 'Value',
        suffixIcon: rule.value.isNotEmpty ? IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () => setState(() => rule.value = ''),
        ) : null,
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
              items: _parameters.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13)))).toList(),
              onChanged: (v) {
                setState(() {
                  rule.parameter = v!;
                  rule.value = ''; 
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
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
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
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
