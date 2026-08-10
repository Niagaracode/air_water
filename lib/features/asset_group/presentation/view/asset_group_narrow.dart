import 'package:air_water/core/helpers/app_colors_helper.dart';
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

class AssetGroupNarrow extends ConsumerStatefulWidget {
  const AssetGroupNarrow({super.key});

  @override
  ConsumerState<AssetGroupNarrow> createState() => _AssetGroupNarrowState();
}

class _AssetGroupNarrowState extends ConsumerState<AssetGroupNarrow> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(assetGroupProvider.notifier).loadGroups();
      ref.read(userProvider.notifier).loadUsers();
      ref.read(productNotifierProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showAddDialog([AssetGroupModel? group]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddAssetGroup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          AddAssetGroupModal(initialGroup: group),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final userState = ref.watch(userProvider);
    final productState = ref.watch(productNotifierProvider);
    final tankState = ref.watch(allTanksProvider);
    final deviceState = ref.watch(deviceNotifierProvider);

    final filteredGroups = state.groups.where((g) {
      if (_searchController.text.isEmpty) return true;
      final term = _searchController.text.toLowerCase();
      return g.name.toLowerCase().contains(term) ||
          g.description.toLowerCase().contains(term);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 2,
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create group',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _buildHeader(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: state.isLoading && filteredGroups.isEmpty
                ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
                : filteredGroups.isEmpty
                ? SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
                : SliverList.builder(
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                return _buildGroupCard(
                  filteredGroups[index],
                  userState,
                  productState,
                  tankState,
                  deviceState,
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.layers_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USER GROUP MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Define dynamic grouping rules based on asset parameters',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar with built-in clear button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: TextFormField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search groups by name or description',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return value.text.isNotEmpty
                      ? IconButton(
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                      : const SizedBox.shrink();
                },
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
            onChanged: (value) {
              setState(() {});
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

    final groupColor = AppColorsHelper.colorForGroup(group.name);

    return InkWell(
      onTap: () => _showAddDialog(group),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Group icon with color
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      size: 20,
                      color: groupColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (group.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.description,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Delete button only
                  InkWell(
                    onTap: () => _confirmDelete(group),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Criteria section
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: groupColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.rule_rounded,
                          size: 14,
                          color: groupColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CRITERIA',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: groupColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      criteriaStr,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // User count
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$displayUserCount users assigned',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.criteria.length} rules',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: groupColor,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No user groups found',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first user group to get started',
              style: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AssetGroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Delete User Group',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}