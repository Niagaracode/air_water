import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/asset_group_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../domain/models/asset_group_model.dart';
import '../widgets/add_asset_group_modal.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../company/presentation/model/company_model.dart';

class AssetGroupNarrow extends ConsumerStatefulWidget {
  const AssetGroupNarrow({super.key});

  @override
  ConsumerState<AssetGroupNarrow> createState() => _AssetGroupNarrowState();
}

class _AssetGroupNarrowState extends ConsumerState<AssetGroupNarrow> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(assetGroupProvider.notifier).loadGroups();
      ref.read(userProvider.notifier).loadUsers();
      ref.read(productNotifierProvider.notifier).loadProducts();
      ref.read(companyNotifierProvider.notifier).loadGroupedCompanies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog([AssetGroupModel? group]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddAssetGroup',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) =>
          AddAssetGroupModal(initialGroup: group),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
            CurvedAnimation(parent: anim1, curve: Curves.fastOutSlowIn),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final userState = ref.watch(userProvider);
    final productState = ref.watch(productNotifierProvider);
    final tankState = ref.watch(allTanksProvider);
    final deviceState = ref.watch(deviceNotifierProvider);
    final companyState = ref.watch(companyNotifierProvider);

    final filteredGroups = state.groups.where((g) {
      if (_searchController.text.isEmpty) return true;
      final term = _searchController.text.toLowerCase();
      return g.name.toLowerCase().contains(term) ||
          g.description.toLowerCase().contains(term);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create group',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildFilterRow(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF141E7A)),
                    )
                  : filteredGroups.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(
                              filteredGroups[index],
                              userState,
                              productState,
                              tankState,
                              deviceState,
                              companyState,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ASSET GROUP MANAGER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Define dynamic grouping rules based on asset parameters and assign users.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Search groups...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list_off_rounded, color: Colors.grey, size: 18),
            tooltip: 'Clear filters',
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
    AssetGroupModel group,
    UserState userState,
    ProductState productState,
    AsyncValue<List<dynamic>> tankState,
    DeviceState deviceState,
    CompanyState companyState,
  ) {
    final isAllGroup = group.name.toLowerCase() == 'all';
    final criteriaStr = isAllGroup
        ? 'Includes all assets'
        : () {
            final buffer = StringBuffer();
            for (int i = 0; i < group.criteria.length; i++) {
              final c = group.criteria[i];
              String displayValue = c.value;

              if (c.parameter == 'Product') {
                final productId = int.tryParse(c.value);
                if (productId != null) {
                  final productList = productState.products;
                  final product = productList.isEmpty
                      ? null
                      : productList.cast<dynamic>().firstWhere(
                          (p) => p.id == productId || p.id.toString() == c.value,
                          orElse: () => null,
                        );
                  if (product != null) {
                    displayValue = product.productCode != null && product.productCode.isNotEmpty
                        ? product.productCode
                        : product.name;
                  }
                }
              }

              if (c.parameter == 'Tank Name') {
                final tankId = int.tryParse(c.value);
                if (tankId != null) {
                  final tankList = tankState.value ?? [];
                  final tank = tankList.isEmpty
                      ? null
                      : tankList.cast<dynamic>().firstWhere(
                          (t) => t.tankId == tankId || t.tankId.toString() == c.value,
                          orElse: () => null,
                        );
                  if (tank != null) {
                    displayValue = tank.tankNumber;
                  }
                }
              }

              if (c.parameter == 'DeviceID') {
                final deviceNumId = int.tryParse(c.value);
                if (deviceNumId != null) {
                  final allDevices = deviceState.groupedDevices.expand((g) => g.devices).toList();
                  final device = allDevices.isEmpty
                      ? null
                      : allDevices.cast<dynamic>().firstWhere(
                          (d) => d.id == deviceNumId || d.id.toString() == c.value,
                          orElse: () => null,
                        );
                  if (device != null) {
                    displayValue = device.deviceId;
                  }
                }
              }

              if (c.parameter == 'Customer Name') {
                final companyId = int.tryParse(c.value);
                if (companyId != null) {
                  final companyList = companyState.groupedCompanies;
                  final company = companyList.isEmpty
                      ? null
                      : companyList.firstWhere(
                          (g) => g.addresses.isNotEmpty && g.addresses.first.companyId == companyId,
                          orElse: () => CompanyGroup(name: '', addresses: []),
                        );
                  if (company != null && company.name.isNotEmpty) {
                    displayValue = company.name;
                  }
                }
              }

              final paramLabel = c.parameter == 'DeviceID' ? 'Device Name' : c.parameter;
              buffer.write('$paramLabel ${c.logic} $displayValue');
              if (i < group.criteria.length - 1) {
                buffer.write(' ${c.operator} ');
              }
            }
            return buffer.toString();
          }();

    final displayUserCount = userState.users.where((u) {
      if (group.companyId != null && u.companyId != group.companyId) {
        return false;
      }
      final isInAllGroup = u.groupNames?.any((n) => n.trim().toLowerCase() == 'all') ?? false;
      if (isAllGroup) return isInAllGroup;
      final isInThisGroup = u.groupNames?.contains(group.name) ?? false;
      return isInThisGroup && !isInAllGroup;
    }).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: primary, size: 18),
                      onPressed: () => _showAddDialog(group),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                      onPressed: () => _confirmDelete(group),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                group.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const Divider(height: 24, thickness: 1),
            Text(
              'CRITERIA:',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE).withValues(alpha: 0.5)),
              ),
              child: Text(
                criteriaStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: primary),
                const SizedBox(width: 4),
                Text(
                  '$displayUserCount users assigned',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.layers_outlined, size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            'No asset groups found',
            style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AssetGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await ref
                  .read(assetGroupProvider.notifier)
                  .deleteGroup(group.id!);
              if (mounted && !success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error: ${ref.read(assetGroupProvider).error ?? 'Failed to delete group'}',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
