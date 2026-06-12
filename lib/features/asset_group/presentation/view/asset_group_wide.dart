import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/view_header.dart';
import '../controller/asset_group_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../domain/models/asset_group_model.dart';
import 'asset_group_edit_page.dart';
import '../widgets/add_asset_group_modal.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../company/presentation/model/company_model.dart';


class AssetGroupWide extends ConsumerStatefulWidget {
  const AssetGroupWide({super.key});

  @override
  ConsumerState<AssetGroupWide> createState() => _AssetGroupWideState();
}

class _AssetGroupWideState extends ConsumerState<AssetGroupWide> {
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

  void _navigateToEdit([AssetGroupModel? group]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetGroupEditPage(group: group),
      ),
    );
  }

  void _showAddDialog([AssetGroupModel? group]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddAssetGroup',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) => AddAssetGroupModal(initialGroup: group),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.fastOutSlowIn)),
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


    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 12, right: 24),
            child: _buildFilterRow(state),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF141E7A)))
                : Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
                  child: _buildTable(state, userState, productState, tankState, deviceState, companyState),
                ),

          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'ASSET GROUP MANAGER',
      subtitle:
      'Define dynamic grouping rules based on asset parameters and assign users.',
      buttonText: 'CREATE GROUP',
      onPressed: () => _showAddDialog(),
    );
  }

  Widget _buildFilterRow(AssetGroupState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Search groups by description...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
              onChanged: (v) {
                // Implement local filter or call provider filter
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E7A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF141E7A)),
            tooltip: 'Clear all filters',
            onPressed: () {
              _searchController.clear();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTable(AssetGroupState state, UserState userState, ProductState productState, AsyncValue<List<dynamic>> tankState, DeviceState deviceState, CompanyState companyState) {

    if (state.groups.isEmpty) {
      return const AppTableEmptyState(
        icon: Icons.layers_outlined,
        title: 'No Asset Groups defined',
        subtitle: 'Click "Create Group" to start defining asset rules.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              border: Border(
                left: BorderSide(color: Colors.grey.shade300, width: 1),
                right: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                AppTableHeaderCell('Group Name', flex: 3),
                AppTableHeaderCell('Criteria & Description', flex: 4),
                AppTableHeaderCell('Users', width: 100),
                AppTableHeaderCell('Company', width: 150),
                AppTableHeaderCell('Display', width: 100),
                AppTableHeaderCell('Action', width: 100),
              ],
            ),
          ),
          ...state.groups.asMap().entries.map((entry) {
            final group = entry.value;
            final isLast = entry.key == state.groups.length - 1;
            final isAllGroup = group.name.toLowerCase() == 'all';
            final criteriaStr = isAllGroup 
                ? 'Includes all assets'
                : () {
                    final buffer = StringBuffer();
                    for (int i = 0; i < group.criteria.length; i++) {
                      final c = group.criteria[i];
                      String displayValue = c.value;
                      
                      // Resolve Product ID to Name if parameter is Product
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
                      
                      // Resolve Tank ID to Name if parameter is Tank Name
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

                      // Resolve Device numeric ID to deviceId string if parameter is DeviceID
                      if (c.parameter == 'DeviceID') {
                        final deviceNumId = int.tryParse(c.value);
                        if (deviceNumId != null) {
                          final allDevices = deviceState.groupedDevices
                              .expand((g) => g.devices)
                              .toList();
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

                      // Resolve Company ID to Name if parameter is Customer Name
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

                      // Map parameter display label
                      final paramLabel = c.parameter == 'DeviceID' ? 'Device Name' : c.parameter;

                      buffer.write('$paramLabel ${c.logic} $displayValue');
                      if (i < group.criteria.length - 1) {
                        buffer.write(' ${c.operator} ');
                      }
                    }
                    return buffer.toString();
                  }();

            final displayUserCount = userState.users.where((u) {
              // If group is scoped to a company, only count users from that company
              if (group.companyId != null && u.companyId != group.companyId) {
                return false;
              }

              final isInAllGroup = u.groupNames?.any((n) => n.trim().toLowerCase() == 'all') ?? false;
              if (isAllGroup) return isInAllGroup;
              
              final isInThisGroup = u.groupNames?.contains(group.name) ?? false;
              return isInThisGroup && !isInAllGroup;
            }).length;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: isLast
                      ? BorderSide(color: Colors.grey.shade300, width: 1)
                      : const BorderSide(color: Color(0xFFF3F4F6)),
                ),
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  AppTableCell(
                    null,
                    flex: 3,
                    child: InkWell(
                      onTap: () => _navigateToEdit(group),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF141E7A), // Make it look clickable
                            ),
                          ),
                          if (group.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                group.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AppTableCell(
                    null,
                    flex: 4,
                    child: Text(
                      criteriaStr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AppTableCell(displayUserCount.toString(), width: 100, textAlign: TextAlign.center),
                  AppTableCell(group.companyName ?? '-', width: 150),
                  SizedBox(
                    width: 100,
                    child: Switch(
                      value: group.displayInTree,
                      onChanged: (v) {
                        ref.read(assetGroupProvider.notifier).updateGroupStatus(group.id!, v);
                      },
                      activeColor: const Color(0xFF141E7A),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppTableActionButton(
                          icon: Icons.edit_outlined,
                          color: Colors.indigo,
                          bg: Colors.indigo.shade50,
                          onTap: () => _showAddDialog(group),
                        ),
                        const SizedBox(width: 8),
                        AppTableActionButton(
                          icon: Icons.delete_outline,
                          color: Colors.red,
                          bg: Colors.red.shade50,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Asset Group'),
                                content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final success = await ref.read(assetGroupProvider.notifier).deleteGroup(group.id!);
                                      if (mounted && !success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: ${ref.read(assetGroupProvider).error ?? 'Failed to delete group'}')),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
