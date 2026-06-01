import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asset_group_model.dart';
import '../controller/asset_group_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';

import '../../../product/provider/product_provider.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../company/presentation/model/company_model.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';

class AddAssetGroupModal extends ConsumerStatefulWidget {
  final AssetGroupModel? initialGroup;
  const AddAssetGroupModal({super.key, this.initialGroup});

  @override
  ConsumerState<AddAssetGroupModal> createState() => _AddAssetGroupModalState();
}

class _AddAssetGroupModalState extends ConsumerState<AddAssetGroupModal> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _displayInTree = true;
  String _groupType = 'Other';

  List<AssetCriteria> _criteria = [];
  List<AssetGroupUser> _assignedUsers = [];
  User? _selectedUserForAssignment;
  int? _selectedCompanyId;
  List<CompanyAutocomplete> _companies = [];
  bool _isLoadingCompanies = false;
  bool _isLoadingDetails = false;
  bool _didAutoAssign = false;
  int _initialCriteriaCount = 0;

  final List<String> _parameters = [
    'City',
    'Country',
    'Customer Name',
    'DeviceID',
    'Product Name',
    'Site Name',
    'State or Province',
    'Tank Name',
  ];
  final List<String> _logics = ['Like', '=', '!='];
  final List<String> _operators = ['And', 'Or'];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _nameController.text = widget.initialGroup!.name;
      _descriptionController.text = widget.initialGroup!.description;
      _displayInTree = widget.initialGroup!.displayInTree;
      _groupType = widget.initialGroup!.name == 'All' ? 'All' : 'Other';
      Future.microtask(() => _loadFullDetails());
    } else {
      _groupType = 'Other';
      _displayInTree = true;
      _addCriteria();
    }

    Future.microtask(() {
      ref.read(userProvider.notifier).loadUsers();
      _checkSuperAdminAndLoadCompanies();
      ref.read(productNotifierProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkSuperAdminAndLoadCompanies() async {
    final user = ref.read(userProvider).currentUser;
    if (user != null) {
      if (user.roleId == 1) {
        setState(() => _isLoadingCompanies = true);
        final results = await ref
            .read(userProvider.notifier)
            .searchCompanies('');
        if (mounted) {
          setState(() {
            _companies = results;
            _isLoadingCompanies = false;
          });
        }
      } else {
        setState(() {
          _selectedCompanyId = user.companyId;
        });
      }
    }
  }

  Future<void> _loadFullDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      await ref
          .read(assetGroupProvider.notifier)
          .loadGroupById(widget.initialGroup!.id!);
      final fullGroup = ref.read(assetGroupProvider).currentGroup;

      if (fullGroup != null && mounted) {
        setState(() {
          _criteria = List.from(fullGroup.criteria);
          for (var rule in _criteria) {
            if (!_operators.contains(rule.operator)) {
              rule.operator = _operators.first;
            }
            if (!_logics.contains(rule.logic)) {
              rule.logic = _logics.contains('=') ? '=' : _logics.first;
            }
          }
          _initialCriteriaCount = _criteria.length;
          _assignedUsers = List.from(fullGroup.users ?? []);
          _selectedCompanyId = fullGroup.companyId;
          if (_criteria.isEmpty) _addCriteria();
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group details: $e')),
        );
      }
    }
  }

  void _addCriteria() {
    setState(() {
      _criteria.add(
        AssetCriteria(
          parameter: 'City',
          logic: 'Like',
          value: '',
          operator: 'And',
        ),
      );
    });
  }

  void _removeCriteria(int index) {
    if (_criteria.length <= 1) {
      setState(() {
        _criteria[0] = AssetCriteria(
          parameter: 'City',
          logic: 'Like',
          value: '',
          operator: 'And',
        );
      });
      return;
    }
    setState(() {
      _criteria.removeAt(index);
    });
  }

  void _showPreviewDialog() async {
    if (widget.initialGroup?.id == null) return;
    await ref
        .read(assetGroupProvider.notifier)
        .loadPreview(widget.initialGroup!.id!);
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
                  ? const Center(
                      child: Text('No assets match the current criteria.'),
                    )
                  : ListView.builder(
                      itemCount: preview.length,
                      itemBuilder: (context, index) {
                        final asset = preview[index];
                        return ListTile(
                          leading: const Icon(Icons.storage),
                          title: Text(asset['tank_number'] ?? 'Unnamed Tank'),
                          subtitle: Text(
                            '${asset['plant_name']} - ${asset['city_name']}',
                          ),
                          trailing: Text(asset['device_id'] ?? '-'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    final groupName = _groupType == 'All' ? 'All' : _nameController.text.trim();
    if (_groupType == 'Other' && groupName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter Group Name')),
      );
      return;
    }

    final newGroup = AssetGroupModel(
      id: widget.initialGroup?.id,
      name: groupName,
      description: _descriptionController.text.trim(),
      displayInTree: _displayInTree,
      criteria: _groupType == 'All' ? [] : _criteria,
      users: _assignedUsers,
      companyId: _selectedCompanyId,
    );

    final success = await ref
        .read(assetGroupProvider.notifier)
        .saveGroup(newGroup, users: _assignedUsers);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      if (widget.initialGroup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully.')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      }
    } else {
      final error = ref.read(assetGroupProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Action failed: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final userState = ref.watch(userProvider);

    ref.listen<UserState>(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        _checkSuperAdminAndLoadCompanies();
      }
    });

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SizedBox(
          width: 800,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
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
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.initialGroup != null
                                      ? 'Edit Group'
                                      : 'Create Group',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Define group details, criteria, and access control.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        if (widget.initialGroup == null &&
                            !state.groups.any((g) => g.name == 'All')) ...[
                          _buildLabelField(
                            'GROUP TYPE',
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRadioOption(
                                    'All',
                                    'Includes all assets automatically',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildRadioOption(
                                    'Other',
                                    'Define custom criteria for this group',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (ref.watch(userProvider).currentUser?.roleId ==
                            1) ...[
                          _buildLabelField(
                            'COMPANY',
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _selectedCompanyId,
                              hint: const Text('Select Company'),
                              items: _companies.map<DropdownMenuItem<int>>((c) {
                                return DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: GoogleFonts.inter(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedCompanyId = v;
                                  _assignedUsers.clear();
                                  _selectedUserForAssignment = null;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText:
                                    'Which company does this group belong to?',
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (_groupType == 'Other') ...[
                          _buildLabelField(
                            'GROUP NAME',
                            AppTextField(
                              controller: _nameController,
                              hint: 'e.g. Battery Tanks',
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        _buildLabelField(
                          'DETAILED DESCRIPTION',
                          AppTextField(
                            controller: _descriptionController,
                            hint:
                                'e.g. This group includes all tanks categorized under battery maintenance...',
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStatusToggle(),

                        if (_groupType == 'Other') ...[
                          const SizedBox(height: 32),
                          _buildCriteriaSection(),
                        ],

                        const SizedBox(height: 32),
                        _buildUserSection(userState),

                        if (widget.initialGroup?.id != null &&
                            _groupType == 'Other') ...[
                          const SizedBox(height: 32),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _showPreviewDialog,
                              icon: const Icon(Icons.remove_red_eye_outlined),
                              label: const Text('PREVIEW MATCHING ASSETS'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: state.isProcessing ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF141E7A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: state.isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    widget.initialGroup != null
                                        ? 'UPDATE GROUP'
                                        : 'CREATE GROUP',
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
                ),
              ),
            ],
          ),
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
            color: const Color(0xFF141E7A),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        field,
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: const Color(0xFF141E7A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toggle group active/inactive status.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _displayInTree,
            onChanged: (v) => setState(() => _displayInTree = v),
            activeColor: const Color(0xFF141E7A),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String subtitle) {
    final isSelected = _groupType == value;
    return InkWell(
      onTap: () => setState(() => _groupType = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF141E7A).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF141E7A)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF141E7A).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF141E7A)
                        : const Color(0xFF374151),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF141E7A),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF141E7A).withValues(alpha: 0.7)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF6B7280),
    letterSpacing: 0.5,
  );

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
          const SizedBox(
            width: 48,
            child: Center(
              child: Text(
                'CLEAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaValueField(int index) {
    final rule = _criteria[index];

    if (rule.parameter == 'Customer Name') {
      final companies = ref
          .watch(companyNotifierProvider)
          .groupedCompanies
          .map((g) {
            final companyId = g.addresses.isNotEmpty
                ? g.addresses.first.companyId
                : null;
            return {'id': companyId?.toString() ?? '', 'name': g.name};
          })
          .where((c) => c['id'] != '')
          .toList();
      companies.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (rule.value.isEmpty && companies.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = companies.first['id']!),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && companies.isNotEmpty
            ? companies.first['id']
            : (companies.any((c) => c['id'] == rule.value) ? rule.value : null),
        items: companies
            .map(
              (c) => DropdownMenuItem<String>(
                value: c['id'] as String,
                child: Text(c['name']!, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Customer',
        ),
      );
    }

    if (rule.parameter == 'Product Name') {
      final state = ref.watch(productNotifierProvider);
      final products = state.products.map((p) {
        return {'id': p.id.toString(), 'name': p.name};
      }).toList();

      products.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (rule.value.isEmpty && products.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = products.first['id']!),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && products.isNotEmpty
            ? products.first['id']
            : (products.any((p) => p['id'] == rule.value) ? rule.value : null),
        items: products
            .map(
              (p) => DropdownMenuItem<String>(
                value: p['id'] as String,
                child: Text(p['name']!, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Product',
        ),
      );
    }

    if (rule.parameter == 'City') {
      final companyCities = ref
          .watch(companyNotifierProvider)
          .groupedCompanies
          .expand((g) => g.addresses)
          .map((a) => a.city)
          .whereType<String>();
      final siteCities = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.city)
          .whereType<String>();
      final cities = <String>{...companyCities, ...siteCities}.toList()..sort();

      if (rule.value.isEmpty && cities.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = cities.first),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && cities.isNotEmpty
            ? cities.first
            : (cities.contains(rule.value) ? rule.value : null),
        items: cities
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select City',
        ),
      );
    }

    if (rule.parameter == 'Country') {
      final companyCountries = ref
          .watch(companyNotifierProvider)
          .groupedCompanies
          .expand((g) => g.addresses)
          .map((a) => a.country)
          .whereType<String>();
      final siteCountries = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.country)
          .whereType<String>();
      final countries = <String>{...companyCountries, ...siteCountries}.toList()
        ..sort();

      if (rule.value.isEmpty && countries.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = countries.first),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && countries.isNotEmpty
            ? countries.first
            : (countries.contains(rule.value) ? rule.value : null),
        items: countries
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Country',
        ),
      );
    }

    if (rule.parameter == 'State or Province') {
      final companyStates = ref
          .watch(companyNotifierProvider)
          .groupedCompanies
          .expand((g) => g.addresses)
          .map((a) => a.state)
          .whereType<String>();
      final siteStates = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.state)
          .whereType<String>();
      final states = <String>{...companyStates, ...siteStates}.toList()..sort();

      if (rule.value.isEmpty && states.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = states.first),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && states.isNotEmpty
            ? states.first
            : (states.contains(rule.value) ? rule.value : null),
        items: states
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select State/Province',
        ),
      );
    }

    if (rule.parameter == 'DeviceID') {
      final devices = ref
          .watch(deviceNotifierProvider)
          .groupedDevices
          .expand((g) => g.devices)
          .map((d) => {'id': d.id.toString(), 'name': d.deviceId})
          .toList();
      devices.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      if (rule.value.isEmpty && devices.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = devices.first['id']!),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && devices.isNotEmpty
            ? devices.first['id']
            : (devices.any((d) => d['id'] == rule.value) ? rule.value : null),
        items: devices
            .map(
              (d) => DropdownMenuItem<String>(
                value: d['id'] as String,
                child: Text(
                  d['name'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Device ID',
        ),
      );
    }

    if (rule.parameter == 'Site Name') {
      final siteState = ref.watch(siteNotifierProvider);
      final sites = siteState.groupedSites.map((g) => g.name).toSet().toList()
        ..sort();

      if (sites.isEmpty && siteState.isLoading) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Loading sites...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Site Name',
          ),
        );
      }

      if (sites.isEmpty) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(value: null, child: Text('No sites found')),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Site Name',
          ),
        );
      }

      if (rule.value.isEmpty && sites.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = sites.first),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && sites.isNotEmpty
            ? sites.first
            : (sites.contains(rule.value) ? rule.value : null),
        items: sites
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Site Name',
        ),
      );
    }

    if (rule.parameter == 'Tank Name') {
      final tankState = ref.watch(tankNotifierProvider);
      final tanks = tankState.groupedTanks
          .expand((g) => g.tanks)
          .map(
            (t) => {
              'id': t.tankId.toString(),
              'name': t.tankName ?? t.tankNumber,
            },
          )
          .toList();
      tanks.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (tanks.isEmpty && tankState.isLoading) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Loading tanks...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tank Name',
          ),
        );
      }

      if (tanks.isEmpty) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(value: null, child: Text('No tanks found')),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tank Name',
          ),
        );
      }

      if (rule.value.isEmpty && tanks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => rule.value = tanks.first['id']!),
        );
      }

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: rule.value.isEmpty && tanks.isNotEmpty
            ? tanks.first['id']
            : (tanks.any((t) => t['id'] == rule.value) ? rule.value : null),
        items: tanks
            .map(
              (t) => DropdownMenuItem<String>(
                value: t['id'] as String,
                child: Text(t['name']!, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Tank Name',
        ),
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
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: rule.parameter,
              items: _parameters
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: index < _initialCriteriaCount
                  ? null
                  : (v) {
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

          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _logics.contains(rule.logic)
                  ? rule.logic
                  : (_logics.contains('=') ? '=' : _logics.first),
              items: _logics
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(l, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => rule.logic = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(flex: 4, child: _buildCriteriaValueField(index)),
          const SizedBox(width: 12),

          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _operators.contains(rule.operator)
                  ? rule.operator
                  : _operators.first,
              items: _operators
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF141E7A),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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

          _criteria.length <= 1
              ? SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: () => _addCriteria(),
                    icon: const Icon(Icons.add, color: Colors.green, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        onPressed: () => _removeCriteria(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // space between icons

                    SizedBox(
                      width: 48,
                      child: IconButton(
                        onPressed: () => _addCriteria(),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

          //  SizedBox(
          //     width: 48,
          //     child: IconButton(
          //       onPressed: () => _removeCriteria(index),
          //       icon: const Icon(
          //         Icons.delete_outline,
          //         color: Colors.red,
          //         size: 20,
          //       ),
          //       style: IconButton.styleFrom(
          //         backgroundColor: Colors.red.withOpacity(0.05),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //       ),
          //     ),
          //   ),
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
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define the dynamic rules that populate this group.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
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
                  // const SizedBox(width: 8),
                  // ElevatedButton.icon(
                  //   onPressed: _addCriteria,
                  //   icon: const Icon(
                  //     Icons.add_circle_outline_rounded,
                  //     size: 18,
                  //   ),
                  //   label: const Text('ADD RULE'),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFF141E7A),
                  //     foregroundColor: Colors.white,
                  //     elevation: 0,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 16,
                  //       vertical: 12,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  // ),
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
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) => _buildCriteriaRow(index),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(UserState userState) {
    final allGroupUsers = userState.users
        .where(
          (u) =>
              u.roleId != 1 &&
              u.roleId != 2 &&
              u.companyId == _selectedCompanyId,
        )
        .toList();

    if (_assignedUsers.isEmpty &&
        !_didAutoAssign &&
        !userState.isLoading &&
        allGroupUsers.isNotEmpty) {
      _didAutoAssign = true;
      for (var user in allGroupUsers) {
        if (!_assignedUsers.any((au) => au.userId == user.userId)) {
          _assignedUsers.add(
            AssetGroupUser(
              userId: user.userId,
              username: user.username,
              firstName: user.firstName,
              lastName: user.lastName,
              roleName: user.roleName,
              groupNames: user.groupNames?.join(', '),
            ),
          );
        }
      }
    }

    final isEditingAllGroup = _groupType == 'All';

    final eligibleUsers = userState.users.where((u) {
      final isAlreadyAssigned = _assignedUsers.any(
        (au) => au.userId == u.userId,
      );
      final isRestrictedRole = u.roleId == 1 || u.roleId == 2;
      final isInAllGroupGlobally =
          u.groupNames?.any((n) => n.trim().toLowerCase() == 'all') ?? false;
      if (!isEditingAllGroup && isInAllGroupGlobally) return false;

      final isCorrectCompany = u.companyId == _selectedCompanyId;

      return !isAlreadyAssigned && !isRestrictedRole && isCorrectCompany;
    }).toList();

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
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (eligibleUsers.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var user in eligibleUsers) {
                        _assignedUsers.add(
                          AssetGroupUser(
                            userId: user.userId,
                            username: user.username,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            roleName: user.roleName,
                            groupNames: user.groupNames?.join(', '),
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('ASSIGN ALL USERS'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF141E7A),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_assignedUsers.length} Users Assigned',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141E7A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('NAME', style: _headerStyle)),
                // Expanded(
                //   flex: 2,
                //   child: Text('GROUP NAME', style: _headerStyle),
                // ),
                Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
                SizedBox(
                  width: 48,
                  child: Center(child: Text('ACTION', style: _headerStyle)),
                ),
              ],
            ),
          ),

          if (_isLoadingDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF141E7A)),
              ),
            )
          else if (_assignedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  'No users assigned to this group.',
                  style: GoogleFonts.inter(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final displayUsers = _assignedUsers.where((au) {
                  if (isEditingAllGroup) return true;
                  final isInAllGroupGlobally =
                      au.groupNames?.toLowerCase().contains('all') ?? false;
                  return !isInAllGroupGlobally;
                }).toList();

                if (displayUsers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'No users assigned to this group.',
                        style: GoogleFonts.inter(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayUsers.length,
                  itemBuilder: (context, index) {
                    final assignment = displayUsers[index];
                    final user = userState.users.firstWhere(
                      (u) => u.userId == assignment.userId,
                      orElse: () => User(
                        userId: assignment.userId,
                        username: assignment.username,
                        email: '',
                        roleId: 0,
                        status: 1,
                      ),
                    );

                    final role = user.roleName?.toLowerCase() ?? '';
                    final isRestricted =
                        role == 'customer' ||
                        role.contains('super admin') ||
                        role.contains('company admin');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isRestricted
                            ? const Color(0xFFF3F4F6)
                            : Colors.white,
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              user.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Expanded(
                          //   flex: 2,
                          //   child: Builder(
                          //     builder: (context) {
                          //       final hasAll =
                          //           user.groupNames?.any(
                          //             (n) => n.trim().toLowerCase() == 'all',
                          //           ) ??
                          //           false;
                          //       if (hasAll) {
                          //         return Text(
                          //           'All',
                          //           style: GoogleFonts.inter(
                          //             fontSize: 13,
                          //             color: Colors.blue,
                          //           ),
                          //         );
                          //       }

                          //       final gNames =
                          //           user.groupNames?.join(', ') ?? '';
                          //       return Text(
                          //         gNames,
                          //         style: GoogleFonts.inter(
                          //           fontSize: 13,
                          //           color: Colors.blue,
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              user.roleName ?? 'User',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: IconButton(
                              onPressed: () => setState(
                                () => _assignedUsers.remove(assignment),
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<User>(
                  isExpanded: true,
                  value: _selectedUserForAssignment,
                  hint: const Text('Select User'),
                  items: eligibleUsers.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(
                        '${u.fullName} (${u.roleName ?? "User"})',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedUserForAssignment = v),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                    fillColor: Color(0xFFF9FAFB),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectedUserForAssignment == null
                    ? null
                    : () {
                        setState(() {
                          _assignedUsers.add(
                            AssetGroupUser(
                              userId: _selectedUserForAssignment!.userId,
                              username: _selectedUserForAssignment!.username,
                              firstName: _selectedUserForAssignment!.firstName,
                              lastName: _selectedUserForAssignment!.lastName,
                              roleName: _selectedUserForAssignment!.roleName,
                              groupNames: _selectedUserForAssignment!.groupNames
                                  ?.join(', '),
                            ),
                          );
                          _selectedUserForAssignment = null;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
