import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/features/user/presentation/model/user_model.dart';
import 'package:air_water/features/tank/presentation/model/tank_model.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';

/// Hierarchical Plant-Tank Dropdown Selector
/// Supports:
/// 1. Selecting a Plant
/// 2. Selecting all tanks in that plant
/// 3. Selecting specific tanks in that plant

class PlantTankDropdownSelector extends StatefulWidget {
  final List<PlantTankAssignment> initialAssignments;
  final Function(List<PlantTankAssignment>) onChanged;

  const PlantTankDropdownSelector({
    super.key,
    required this.initialAssignments,
    required this.onChanged,
  });

  @override
  State<PlantTankDropdownSelector> createState() =>
      _PlantTankDropdownSelectorState();
}

class _PlantTankDropdownSelectorState extends State<PlantTankDropdownSelector> {
  late List<PlantTankAssignment> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.initialAssignments);
  }

  void _showSelectorDialog() {
    showDialog(
      context: context,
      builder: (context) => PlantTankSelectorDialog(
        currentAssignments: _assignments,
        onSave: (newAssignments) {
          setState(() {
            _assignments = newAssignments;
          });
          widget.onChanged(_assignments);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_assignments.isEmpty)
          const Text(
            'No plants or tanks assigned',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _assignments.map((assignment) {
              return Chip(
                label: Text(
                  assignment.displayText,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: const Color(0xFFF5F6FA),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _assignments.remove(assignment);
                  });
                  widget.onChanged(_assignments);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showSelectorDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Plant & Tanks Access'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1B1B4B),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class PlantTankSelectorDialog extends ConsumerStatefulWidget {
  final List<PlantTankAssignment> currentAssignments;
  final Function(List<PlantTankAssignment>) onSave;

  const PlantTankSelectorDialog({
    super.key,
    required this.currentAssignments,
    required this.onSave,
  });

  @override
  ConsumerState<PlantTankSelectorDialog> createState() =>
      _PlantTankSelectorDialogState();
}

class _PlantTankSelectorDialogState
    extends ConsumerState<PlantTankSelectorDialog> {
  final Map<int, PlantSelection> _plantSelections = {};
  bool _isLoading = true;
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
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(limit: 100);
      debugPrint(
        'PlantTankDropdownSelector: Fetched ${response.data.length} grouped plants',
      );
      for (var group in response.data) {
        debugPrint(
          'Plant: ${group.plantName} (ID: ${group.plantId}), Tanks: ${group.tanks.length}',
        );
      }

      _plantSelections.clear();

      for (final group in response.data) {
        final plantId = group.plantId;
        final plantName = group.plantName;

        // Check if we already have assignments for this plant
        final existing = widget.currentAssignments.firstWhere(
          (a) => a.plantId == plantId,
          orElse: () => PlantTankAssignment(
            plantId: plantId,
            plantName: plantName,
            allTanks: false,
            tankIds: [],
          ),
        );

        final Map<int, String> tankNames = {};
        final List<int> availableTankIds = [];

        for (final tank in group.tanks) {
          tankNames[tank.tankId] = tank.tankNumber;
          availableTankIds.add(tank.tankId);
        }

        _plantSelections[plantId] = PlantSelection(
          plantId: plantId,
          plantName: plantName,
          allTanks: existing.allTanks,
          selectedTankIds: Set.from(existing.tankIds ?? []),
          availableTankIds: availableTankIds,
          availableTankNames: tankNames,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _togglePlantAllTanks(int plantId, bool? value) {
    if (value == null) return;

    setState(() {
      final selection = _plantSelections[plantId];
      if (selection != null) {
        selection.allTanks = value;
        if (value) {
          selection.selectedTankIds.addAll(selection.availableTankIds);
        } else {
          selection.selectedTankIds.clear();
        }
      }
    });
  }

  void _toggleTank(int plantId, int tankId) {
    setState(() {
      final selection = _plantSelections[plantId];
      if (selection != null) {
        if (selection.selectedTankIds.contains(tankId)) {
          selection.selectedTankIds.remove(tankId);
          // If no tanks selected, uncheck "all tanks"
          if (selection.selectedTankIds.isEmpty) {
            selection.allTanks = false;
          }
        } else {
          selection.selectedTankIds.add(tankId);
          // If all tanks selected, check "all tanks"
          if (selection.selectedTankIds.length ==
              selection.availableTankIds.length) {
            selection.allTanks = true;
          }
        }
      }
    });
  }

  void _save() {
    final assignments = <PlantTankAssignment>[];

    for (final entry in _plantSelections.entries) {
      final selection = entry.value;

      if (selection.selectedTankIds.isNotEmpty) {
        final assignment = PlantTankAssignment(
          plantId: entry.key,
          plantName: selection.plantName,
          allTanks: selection.allTanks,
          tankIds: selection.allTanks
              ? null
              : selection.selectedTankIds.toList(),
          tankNames: selection.allTanks
              ? null
              : selection.selectedTankIds
                    .map((id) => selection.availableTankNames[id] ?? 'Tank $id')
                    .toList(),
        );
        assignments.add(assignment);
      }
    }

    widget.onSave(assignments);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Plants & Tanks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Select plants and their tanks that this user can access',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Plant List with Tanks
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error loading data: $_error',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _plantSelections.length,
                            itemBuilder: (context, index) {
                              final plantId = _plantSelections.keys.elementAt(
                                index,
                              );
                              final selection = _plantSelections[plantId]!;

                              return _buildPlantCard(plantId, selection);
                            },
                          ),
                  ),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Footer Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1B4B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlantCard(int plantId, PlantSelection selection) {
    final hasSelection = selection.selectedTankIds.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.factory,
            color: hasSelection ? const Color(0xFF1B1B4B) : Colors.grey,
          ),
          title: Text(
            selection.plantName,
            style: TextStyle(
              fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            selection.allTanks
                ? 'All tanks selected'
                : selection.selectedTankIds.isEmpty
                ? 'No tanks selected'
                : '${selection.selectedTankIds.length} of ${selection.availableTankIds.length} tanks',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            const Divider(height: 1),

            // All Tanks Checkbox
            CheckboxListTile(
              value: selection.allTanks,
              onChanged: (value) => _togglePlantAllTanks(plantId, value),
              title: const Text(
                'All Tanks',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              dense: true,
            ),

            const Divider(height: 1),

            // Individual Tank Checkboxes
            ...selection.availableTankIds.map((tankId) {
              final tankName =
                  selection.availableTankNames[tankId] ?? 'Tank $tankId';
              return CheckboxListTile(
                value: selection.selectedTankIds.contains(tankId),
                onChanged: (value) => _toggleTank(plantId, tankId),
                title: Text(tankName, style: const TextStyle(fontSize: 13)),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Helper class to track plant selection state
class PlantSelection {
  final int plantId;
  final String plantName;
  bool allTanks;
  Set<int> selectedTankIds;
  final List<int> availableTankIds;
  final Map<int, String> availableTankNames;

  PlantSelection({
    required this.plantId,
    required this.plantName,
    required this.allTanks,
    required this.selectedTankIds,
    required this.availableTankIds,
    required this.availableTankNames,
  });
}
