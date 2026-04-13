import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/user/presentation/model/user_model.dart';
import 'package:air_water/features/tank/presentation/model/tank_model.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';

/// Hierarchical Site-Tank Dropdown Selector
/// Supports:
/// 1. Selecting a Site
/// 2. Selecting all tanks in that site
/// 3. Selecting specific tanks in that site

class SiteTankDropdownSelector extends StatefulWidget {
  final List<SiteTankAssignment> initialAssignments;
  final Function(List<SiteTankAssignment>) onChanged;

  const SiteTankDropdownSelector({
    super.key,
    required this.initialAssignments,
    required this.onChanged,
  });

  @override
  State<SiteTankDropdownSelector> createState() =>
      _SiteTankDropdownSelectorState();
}

class _SiteTankDropdownSelectorState extends State<SiteTankDropdownSelector> {
  late List<SiteTankAssignment> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.initialAssignments);
  }

  void _showSelectorDialog() {
    showDialog(
      context: context,
      builder: (context) => SiteTankSelectorDialog(
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
            'No sites or tanks assigned',
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
            'Add Site & Tanks Access',
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

class SiteTankSelectorDialog extends ConsumerStatefulWidget {
  final List<SiteTankAssignment> currentAssignments;
  final Function(List<SiteTankAssignment>) onSave;

  const SiteTankSelectorDialog({
    super.key,
    required this.currentAssignments,
    required this.onSave,
  });

  @override
  ConsumerState<SiteTankSelectorDialog> createState() =>
      _SiteTankSelectorDialogState();
}

class _SiteTankSelectorDialogState
    extends ConsumerState<SiteTankSelectorDialog> {
  final Map<int, SiteSelection> _siteSelections = {};
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
        'SiteTankDropdownSelector: Fetched ${response.data.length} grouped sites',
      );
      for (var group in response.data) {
        debugPrint(
          'Site: ${group.siteName} (ID: ${group.siteId}), Tanks: ${group.tanks.length}',
        );
      }

      _siteSelections.clear();

      for (final group in response.data) {
        final siteId = group.siteId;
        final siteName = group.siteName;

        // Check if we already have assignments for this site
        final existing = widget.currentAssignments.firstWhere(
          (a) => a.siteId == siteId,
          orElse: () => SiteTankAssignment(
            siteId: siteId,
            siteName: siteName,
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

        _siteSelections[siteId] = SiteSelection(
          siteId: siteId,
          siteName: siteName,
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

  void _toggleSiteAllTanks(int siteId, bool? value) {
    if (value == null) return;

    setState(() {
      final selection = _siteSelections[siteId];
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

  void _toggleTank(int siteId, int tankId) {
    setState(() {
      final selection = _siteSelections[siteId];
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
    final assignments = <SiteTankAssignment>[];

    for (final entry in _siteSelections.entries) {
      final selection = entry.value;

      if (selection.selectedTankIds.isNotEmpty) {
        final assignment = SiteTankAssignment(
          siteId: entry.key,
          siteName: selection.siteName,
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
                              'Select Sites & Tanks',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select sites and their tanks that this user can access',
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

                  // Site List with Tanks
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
                            itemCount: _siteSelections.length,
                            itemBuilder: (context, index) {
                              final siteId = _siteSelections.keys.elementAt(
                                index,
                              );
                              final selection = _siteSelections[siteId]!;

                              return _buildSiteCard(siteId, selection);
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

  Widget _buildSiteCard(int siteId, SiteSelection selection) {
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
                selection.siteName,
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
              onChanged: (value) => _toggleSiteAllTanks(siteId, value),
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
                onChanged: (value) => _toggleTank(siteId, tankId),
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

/// Helper class to track site selection state
class SiteSelection {
  final int siteId;
  final String siteName;
  final String fullAddress;
  bool allTanks;
  Set<int> selectedTankIds;
  final List<int> availableTankIds;
  final Map<int, String> availableTankNames;

  SiteSelection({
    required this.siteId,
    required this.siteName,
    required this.fullAddress,
    required this.allTanks,
    required this.selectedTankIds,
    required this.availableTankIds,
    required this.availableTankNames,
  });
}
