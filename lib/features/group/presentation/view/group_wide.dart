import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';
import '../widgets/add_group_modal.dart';
import 'group_detail.dart';

class GroupWide extends ConsumerStatefulWidget {
  const GroupWide({super.key});

  @override
  ConsumerState<GroupWide> createState() => _GroupWideState();
}

class _GroupWideState extends ConsumerState<GroupWide> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(groupProvider.notifier).loadGroups());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddModal([Group? group]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: group == null ? 'Add Group' : 'Edit Group',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddGroupModal(group: group);
      },
    );
  }

  void _showDetail(Group group) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => GroupDetail(group: group)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupProvider);
    final notifier = ref.read(groupProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GROUP MANAGEMENT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage Access Groups By Assigning Specific Plants And Tanks To Control User Permissions.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddModal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('ADD GROUP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search By Group Name',
                                prefixIcon: Icon(Icons.search, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (v) => notifier.loadGroups(name: v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Showing ${state.groups.length} entries',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.isLoading && state.groups.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else
                    _buildGroupTable(state, notifier),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTable(GroupState state, GroupNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _tableHeaderCell('SI.NO', width: 70),
                _tableHeaderCell('Group Name', flex: 3),
                _tableHeaderCell('Company', flex: 3),
                _tableHeaderCell('Assigned Plants', flex: 2),
                _tableHeaderCell('Total Tanks', flex: 2),
                _tableHeaderCell('Users', flex: 1),
                _tableHeaderCell('Status', flex: 1),
                _tableHeaderCell('Action', width: 120),
              ],
            ),
          ),
          if (state.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No groups found'),
            )
          else
            ...state.groups.asMap().entries.map((entry) {
              return _buildGroupRow(entry.value, entry.key, notifier);
            }),
        ],
      ),
    );
  }

  Widget _buildGroupRow(Group group, int index, GroupNotifier notifier) {
    return InkWell(
      onTap: () => _showDetail(group),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Center(
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            _tableCell(
              group.name,
              flex: 3,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            _tableCell(group.companyName ?? '-', flex: 3),
            _tableCell('${group.assignedPlants.length} Plants', flex: 2),
            _tableCell('${group.assignedTanks.length} Tanks', flex: 2),
            _tableCell(group.userCount.toString(), flex: 1),
            Expanded(
              flex: 1,
              child: Center(child: _buildStatusChip(group.status)),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _showDetail(group),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    color: Colors.green,
                    tooltip: 'View Detail',
                  ),
                  IconButton(
                    onPressed: () => _showAddModal(group),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.blue,
                    tooltip: 'Edit Group',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(group.id, notifier),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    tooltip: 'Delete Group',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    final isActive = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String label, {int? flex, double? width}) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _tableCell(
    String value, {
    int? flex,
    double? width,
    TextStyle? style,
  }) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        value,
        style: style ?? const TextStyle(fontSize: 13),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Future<void> _confirmDelete(int id, GroupNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this access group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await notifier.deleteGroup(id);
    }
  }
}
