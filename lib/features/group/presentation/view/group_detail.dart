import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../tank/presentation/model/tank_model.dart';
import '../model/group_model.dart';

class GroupDetail extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetail({super.key, required this.group});

  @override
  ConsumerState<GroupDetail> createState() => _GroupDetailState();
}

class _GroupDetailState extends ConsumerState<GroupDetail> {
  bool _isLoading = true;
  List<TankGroup> _filteredGroups = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroupAssignments();
  }

  Future<void> _loadGroupAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(tankRepositoryProvider);
      // Fetch all grouped tanks and filter for those assigned to this group
      final response = await repository.getTanksGrouped(limit: 100);

      final assignedPlantIds = widget.group.assignedPlants.toSet();
      final assignedTankIds = widget.group.assignedTanks.toSet();

      _filteredGroups = response.data
          .where((pg) {
            return assignedPlantIds.contains(pg.plantId);
          })
          .map((pg) {
            // Filter tanks within each plant group
            final filteredTanks = pg.tanks.where((t) {
              return assignedTankIds.contains(t.tankId);
            }).toList();

            return pg.copyWith(tanks: filteredTanks);
          })
          .where((pg) => pg.tanks.isNotEmpty)
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${widget.group.name.toUpperCase()} DETAIL'),
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    'ASSIGNED PLANTS & TANKS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filteredGroups.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'No plant or tank assignments found for this group.',
                        ),
                      ),
                    )
                  else
                    ..._filteredGroups.map((pg) => _buildPlantCard(pg)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primary.withOpacity(0.1),
            child: Icon(Icons.group_outlined, color: primary, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.group.description ?? 'No description provided',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.business,
                      widget.group.companyName ?? 'Unassigned',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.people_outline,
                      '${widget.group.userCount} Users Assigned',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(TankGroup pg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.factory_outlined, color: Colors.blueGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pg.plantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (pg.addressLine1 != null)
                        Text(
                          '${pg.addressLine1}, ${pg.city ?? ''}, ${pg.state ?? ''} - ${pg.pincode ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pg.tanks.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tank = pg.tanks[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
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
                title: Text(
                  tank.tankNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${tank.tankTypeName} | ${tank.productName}'),
                trailing: Text(
                  '${tank.width} x ${tank.height} (${tank.unitName})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
