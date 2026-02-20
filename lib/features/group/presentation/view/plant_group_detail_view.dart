import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../plant/presentation/controller/plant_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../user/presentation/widgets/add_user_modal.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';

class PlantGroupDetailView extends ConsumerStatefulWidget {
  final Group group;
  final int plantId;

  const PlantGroupDetailView({
    super.key,
    required this.group,
    required this.plantId,
  });

  @override
  ConsumerState<PlantGroupDetailView> createState() =>
      _PlantGroupDetailViewState();
}

class _PlantGroupDetailViewState extends ConsumerState<PlantGroupDetailView> {
  bool _isLoading = true;
  dynamic _plantData;
  List<dynamic> _tanks = [];
  List<GroupUser> _groupUsers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Load Plant Details with Address
      final plantRepo = ref.read(plantRepositoryProvider);
      _plantData = await plantRepo.getPlantWithAddresses(widget.plantId);

      // 2. Load Tanks for this plant
      final tankRepo = ref.read(tankRepositoryProvider);
      final tanksResponse = await tankRepo.getTanks(plantId: widget.plantId);
      // Filter tanks that are assigned to this group
      final assignedTankIds = widget.group.assignedTanks.toSet();
      _tanks = tanksResponse
          .where((t) => assignedTankIds.contains(t.tankId))
          .toList();

      // 3. Load Group Users
      final groupNotifier = ref.read(groupProvider.notifier);
      _groupUsers = await groupNotifier.getGroupUsers(widget.group.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddUserModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add User',
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AddUserModal();
      },
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${_plantData?['name'] ?? 'PLANT'} - ${widget.group.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlantInfoCard(),
                  const SizedBox(height: 24),
                  _buildTanksSection(),
                  const SizedBox(height: 24),
                  _buildUsersSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlantInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.factory_outlined, color: primary, size: 24),
              const SizedBox(width: 12),
              Text(
                _plantData?['name'] ?? 'Unknown Plant',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _plantData?['plant_organization_code'] ?? '-',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'ADDRESS DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_plantData?['country_name'] ?? '-'}, ${_plantData?['state_name'] ?? '-'}, ${_plantData?['city_name'] ?? '-'}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTanksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ASSIGNED TANKS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 12),
        if (_tanks.isEmpty)
          const Text(
            'No tanks from this plant assigned to this group.',
            style: TextStyle(color: Colors.grey),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: _tanks.asMap().entries.map((entry) {
                final tank = entry.value;
                final isLast = entry.key == _tanks.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: Colors.grey.shade100),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storage,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tank.tankNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${tank.tankTypeName} | ${tank.productName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tank.width ?? 0} x ${tank.height ?? 0} (${tank.unitName ?? '-'})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GROUP USERS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddUserModal,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADD USER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (_groupUsers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No users in this group.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._groupUsers.map((user) => _buildUserRow(user)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(GroupUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.1),
            child: Text(
              user.username[0].toUpperCase(),
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email ?? '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
            onPressed: () {}, // Implement Edit
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _removeUserFromGroup(user.userId),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUserFromGroup(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: const Text(
          'Are you sure you want to remove this user from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(groupProvider.notifier)
          .removeUserFromGroup(widget.group.id, userId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User removed from group')),
        );
        _loadData();
      }
    }
  }
}
