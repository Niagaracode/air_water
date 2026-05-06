import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../controller/asset_group_provider.dart';
import '../../domain/models/asset_group_model.dart';
import 'asset_group_edit_page.dart';
import '../widgets/add_asset_group_modal.dart';

class AssetGroupWide extends ConsumerStatefulWidget {
  const AssetGroupWide({super.key});

  @override
  ConsumerState<AssetGroupWide> createState() => _AssetGroupWideState();
}

class _AssetGroupWideState extends ConsumerState<AssetGroupWide> {
  final TextEditingController _searchController = TextEditingController();

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

    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: Column(
        children: [
          _buildHeader(state),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF141E7A)))
                : _buildTable(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AssetGroupState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: Colors.white,
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
                    'ASSET GROUP MANAGER',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define dynamic grouping rules based on asset parameters and assign users.',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('CREATE GROUP'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search groups by description...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    // Implement local filter or call provider filter
                  },
                ),
              ),
              const SizedBox(width: 16),
              AppClearButton(onPressed: () => _searchController.clear()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AssetGroupState state) {
    if (state.groups.isEmpty) {
      return const AppTableEmptyState(
        icon: Icons.layers_outlined,
        title: 'No Asset Groups defined',
        subtitle: 'Click "Create Group" to start defining asset rules.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                AppTableHeaderCell('Group Name', flex: 3),
                AppTableHeaderCell('Criteria & Description', flex: 4),
                AppTableHeaderCell('Users', width: 100),
                AppTableHeaderCell('Domain', width: 120),
                AppTableHeaderCell('Display', width: 100),
                AppTableHeaderCell('Action', width: 100),
              ],
            ),
          ),
          ...state.groups.asMap().entries.map((entry) {
            final group = entry.value;
            final criteriaStr = group.criteria.isEmpty 
                ? 'No criteria (Includes all)' 
                : group.criteria.map((c) => '${c.parameter} ${c.logic} ${c.value}').join(' ${group.criteria.first.operator} ');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                            Text(
                              group.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
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
                  AppTableCell(group.userCount?.toString() ?? '0', width: 100, textAlign: TextAlign.center),
                  AppTableCell(group.domain, width: 120),
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
          const AppTableBottomCap(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
