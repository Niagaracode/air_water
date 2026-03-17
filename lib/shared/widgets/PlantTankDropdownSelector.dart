import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
          Text(
            'No plants or tanks assigned',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _assignments.map((assignment) {
              return Chip(
                label: Text(
                  assignment.displayText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
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
          label: Text(
            'Add Plant & Tanks Access',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
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
          fullAddress: group.fullAddress,
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
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.factory_rounded,
                          color: Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Plants & Tanks',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select plants and their tanks that this user can access',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF4B5563),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        hoverColor: const Color(0xFFF3F4F6),
                      ),
                    ],
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
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141E7A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'SAVE',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFFF8FAFC),
          leading: Icon(
            Icons.factory_rounded,
            color: hasSelection
                ? const Color(0xFF475569)
                : const Color(0xFF9CA3AF),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection.plantName,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: const Color(0xFF111827),
                ),
              ),
              if (selection.fullAddress.isNotEmpty)
                Text(
                  selection.fullAddress,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            selection.allTanks
                ? 'All tanks selected'
                : selection.selectedTankIds.isEmpty
                ? 'No tanks selected'
                : '${selection.selectedTankIds.length} of ${selection.availableTankIds.length} tanks connected',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF4B5563),
            ),
          ),
          children: [
            const Divider(height: 1),

            // All Tanks Checkbox
            CheckboxListTile(
              value: selection.allTanks,
              onChanged: (value) => _togglePlantAllTanks(plantId, value),
              activeColor: const Color(0xFF475569),
              checkColor: Colors.white,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              title: Text(
                'All Tanks',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF374151),
                ),
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
                activeColor: const Color(0xFF475569),
                checkColor: Colors.white,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                title: Text(
                  tankName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                  ),
                ),
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
  final String fullAddress;
  bool allTanks;
  Set<int> selectedTankIds;
  final List<int> availableTankIds;
  final Map<int, String> availableTankNames;

  PlantSelection({
    required this.plantId,
    required this.plantName,
    required this.fullAddress,
    required this.allTanks,
    required this.selectedTankIds,
    required this.availableTankIds,
    required this.availableTankNames,
  });
}
