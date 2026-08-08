import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asset_group_model.dart';
import '../controller/asset_group_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/app_theme/app_theme.dart';

import '../../../product/provider/product_provider.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
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
    'DeviceID',
    'Product',
    'Site Name',
    'State or Province',
    'Tank Name',
  ];
  final List<String> _logics = ['Like', '=', '!='];
  final List<String> _operators = ['Or', 'And'];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _nameController.text = widget.initialGroup!.name;
      _descriptionController.text = widget.initialGroup!.description;
      _displayInTree = widget.initialGroup!.displayInTree;
      _groupType = widget.initialGroup!.name.trim().toLowerCase().contains('all') ? 'All' : 'Other';
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
      ref.read(deviceNotifierProvider.notifier).loadGroupedDevices(limit: 500);
      ref.read(siteNotifierProvider.notifier).loadGroupedSites();
      ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
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
            if (widget.initialGroup == null) {
              _selectedCompanyId = 216;
            }
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
          _assignedUsers = List.from(
            (fullGroup.users ?? []).where((u) {
              final role = (u.roleName ?? '').toLowerCase().replaceAll(' ', '');
              return !role.contains('superadmin');
            }),
          );
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
    final selectedParameters = _criteria.map((c) => c.parameter).toSet();
    final nextParameter = _parameters.firstWhere(
      (p) => !selectedParameters.contains(p),
      orElse: () => _parameters.first,
    );
    setState(() {
      _criteria.add(
        AssetCriteria(
          parameter: nextParameter,
          logic: 'Like',
          value: '',
          operator: 'Or',
        ),
      );
    });
  }

  void _removeCriteria(int index) {
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
        child: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 800 ? MediaQuery.of(context).size.width : 800,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 40,
                        vertical: MediaQuery.of(context).size.width < 600 ? 24 : 48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.initialGroup != null
                                          ? 'Edit Group'
                                          : 'Create Group',
                                      style: GoogleFonts.outfit(
                                        fontSize: MediaQuery.of(context).size.width < 600 ? 22 : 28,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Define group details, criteria, and access control.',
                                      style: GoogleFonts.inter(
                                        fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                backgroundColor: primary,
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
            color: primary,
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
                    color: primary,
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
            activeColor: primary,
          ),
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

  Widget _buildCriteriaHeader() {
    if (MediaQuery.of(context).size.width < 600) {
      return const SizedBox.shrink();
    }
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

    if (rule.parameter == 'Product') {
      final state = ref.watch(productNotifierProvider);
      final products = state.products.map((p) {
        return {
          'id': p.id.toString(),
          'name': p.name,
        };
      }).toList();

      products.sort((a, b) => a['name']!.compareTo(b['name']!));

      // Filter out products selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Product' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredProducts = products
          .where((p) => 
              (!selectedVals.contains(p['id']) && !selectedVals.contains(p['name'])) || 
              p['id'] == rule.value || 
              p['name'] == rule.value)
          .toList();

      final matchIndex = filteredProducts.indexWhere((p) => p['id'] == rule.value || p['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredProducts[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: dropdownValue,
        items: filteredProducts
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

      final siteCities = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.city)
          .whereType<String>();
      final cities = <String>{ ...siteCities}.toList()..sort();

      // Filter out cities selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'City' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredCities = cities
          .where((c) => !selectedVals.contains(c) || c == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: filteredCities.contains(rule.value) ? rule.value : null,
        items: filteredCities
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

      final siteCountries = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.country)
          .whereType<String>();
      final countries = <String>{ ...siteCountries}.toList()
        ..sort();

      // Filter out countries selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Country' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredCountries = countries
          .where((c) => !selectedVals.contains(c) || c == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: filteredCountries.contains(rule.value) ? rule.value : null,
        items: filteredCountries
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

      final siteStates = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.state)
          .whereType<String>();
      final states = <String>{ ...siteStates}.toList()..sort();

      // Filter out states selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'State or Province' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredStates = states
          .where((s) => !selectedVals.contains(s) || s == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: filteredStates.contains(rule.value) ? rule.value : null,
        items: filteredStates
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
      final deviceState = ref.watch(deviceNotifierProvider);
      final devices = deviceState.groupedDevices
          .expand((g) => g.devices)
          .map((d) => {'id': d.id.toString(), 'name': d.deviceId})
          .toList();
      devices.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      if (devices.isEmpty && deviceState.isLoading) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Loading devices...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Select Device ID',
          ),
        );
      }

      if (devices.isEmpty) {
        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: null,
          items: const [
            DropdownMenuItem(value: null, child: Text('No devices found')),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Select Device ID',
          ),
        );
      }

      // Filter out devices selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'DeviceID' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredDevices = devices
          .where((d) => 
              (!selectedVals.contains(d['id']) && !selectedVals.contains(d['name'])) || 
              d['id'] == rule.value || 
              d['name'] == rule.value)
          .toList();

      final matchIndex = filteredDevices.indexWhere((d) => d['id'] == rule.value || d['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredDevices[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: dropdownValue,
        items: filteredDevices
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
      final sites = siteState.groupedSites
          .map((g) => g.name)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .toList()
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

      // Filter out sites selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Site Name' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredSites = sites
          .where((s) => !selectedVals.contains(s) || s == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: filteredSites.contains(rule.value) ? rule.value : null,
        items: filteredSites
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

      // Filter out tanks selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Tank Name' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredTanks = tanks
          .where((t) => 
              (!selectedVals.contains(t['id']) && !selectedVals.contains(t['name'])) || 
              t['id'] == rule.value || 
              t['name'] == rule.value)
          .toList();

      final matchIndex = filteredTanks.indexWhere((t) => t['id'] == rule.value || t['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredTanks[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        isExpanded: true,
        value: dropdownValue,
        items: filteredTanks
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RULE #${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: rule.parameter,
                    items: _parameters
                        .where((p) {
                          if (index < 3) {
                            return true;
                          } else {
                            final isSelectedInFirstThree = _criteria.asMap().entries.any(
                                  (e) => e.key < 3 && e.value.parameter == p,
                                );
                            return !isSelectedInFirstThree || p == rule.parameter;
                          }
                        })
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, style: GoogleFonts.inter(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (index < _initialCriteriaCount &&
                                !(ref.watch(userProvider).currentUser?.roleId == 1 ||
                                  ref.watch(userProvider).currentUser?.roleId == 2))
                        ? null
                        : (v) {
                            setState(() {
                              rule.parameter = v!;
                              rule.value = '';
                            });
                          },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelText: 'Parameter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                            child: Text(l, style: GoogleFonts.inter(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => rule.logic = v!),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelText: 'Logic',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCriteriaValueField(index),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => rule.operator = v!),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFFF3F4FF),
                      filled: true,
                      labelText: 'Next Join',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
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
                const SizedBox(width: 8),
                IconButton(
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
              ],
            ),
          ],
        ),
      );
    }

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
                  .where((p) {
                    if (index < 3) {
                      return true;
                    } else {
                      final isSelectedInFirstThree = _criteria.asMap().entries.any(
                            (e) => e.key < 3 && e.value.parameter == p,
                          );
                      return !isSelectedInFirstThree || p == rule.parameter;
                    }
                  })
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (index < _initialCriteriaCount &&
                          !(ref.watch(userProvider).currentUser?.roleId == 1 ||
                            ref.watch(userProvider).currentUser?.roleId == 2))
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
                          color: primary,
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

          Row(
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
        ],
      ),
    );
  }

  Widget _buildCriteriaSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Selection Criteria',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define the dynamic rules that populate this group.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _criteria.clear();
                  });
                },
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('CLEAR ALL', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (_criteria.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No selection criteria added.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ] else ...[
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
        ],
      ),
    );
  }

  Widget _buildUserSection(UserState userState) {
    final allGroupUsers = userState.users.where((u) {
      final isSuper = u.roleId == 1 || (u.roleName ?? '').toLowerCase().replaceAll(' ', '').contains('superadmin');
      return u.companyId == _selectedCompanyId && !isSuper;
    }).toList();

    final isEditingAllGroup = _groupType == 'All' || _nameController.text.trim().toLowerCase().contains('all');

    if (isEditingAllGroup &&
        _assignedUsers.isEmpty &&
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

    final eligibleUsers = userState.users.where((u) {
      final isAlreadyAssigned = _assignedUsers.any(
        (au) => au.userId == u.userId,
      );
      final isSuperAdmin = u.roleId == 1 ||
          (u.roleName ?? '').toLowerCase().replaceAll(' ', '').contains('superadmin');
      if (isSuperAdmin) return false;

      final isInAllGroupGlobally =
          u.groupNames?.any((n) => n.trim().toLowerCase() == 'all') ?? false;
      if (!isEditingAllGroup && isInAllGroupGlobally) return false;

      final isCorrectCompany = u.companyId == _selectedCompanyId;

      return !isAlreadyAssigned && isCorrectCompany;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Access Control',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                _selectedUserForAssignment = null;
                              });
                            },
                            icon: const Icon(Icons.group_add_outlined, size: 16),
                            label: const Text('ASSIGN ALL', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_assignedUsers.length} Assigned',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                            _selectedUserForAssignment = null;
                          });
                        },
                        icon: const Icon(Icons.group_add_outlined, size: 18),
                        label: const Text('ASSIGN ALL USERS'),
                        style: TextButton.styleFrom(
                          foregroundColor: primary,
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
                          color: primary,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: primary),
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
                final displayUsers = _assignedUsers;

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

                    final role = (assignment.roleName ?? user.roleName ?? '').toLowerCase();
                    final isRestricted =
                        role == 'customer' ||
                        role.contains('super admin') ||
                        role.contains('super_admin');

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
                            child: Builder(
                              builder: (context) {
                                final fName = assignment.firstName ?? user.firstName ?? '';
                                final lName = assignment.lastName ?? user.lastName ?? '';
                                final fullName = (fName.isEmpty && lName.isEmpty)
                                    ? (user.fullName.isNotEmpty ? user.fullName : assignment.username)
                                    : '$fName $lName'.trim();
                                return Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
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
                              assignment.roleName ?? user.roleName ?? 'User',
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

          isMobile
              ? Column(
                  children: [
                    DropdownButtonFormField<User>(
                      isExpanded: true,
                      value: eligibleUsers.contains(_selectedUserForAssignment)
                          ? _selectedUserForAssignment
                          : null,
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF111827),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<User>(
                        isExpanded: true,
                        value: eligibleUsers.contains(_selectedUserForAssignment)
                            ? _selectedUserForAssignment
                            : null,
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
                    OutlinedButton.icon(
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
                      style: OutlinedButton.styleFrom(
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
