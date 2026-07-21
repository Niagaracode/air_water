import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../asset_group/presentation/controller/asset_group_provider.dart';
import '../../data/model/tank_channel_model.dart';

class ThresholdSideSheet extends ConsumerStatefulWidget {
  final List<TankChannelModel> channels;
  final Function(Map<String, dynamic>) onSave;
  final bool isNarrow;

  const ThresholdSideSheet({
    super.key,
    required this.channels,
    required this.onSave,
    required this.isNarrow,
  });

  @override
  ConsumerState<ThresholdSideSheet> createState() => _ThresholdSideSheetState();
}

class _ThresholdSideSheetState extends ConsumerState<ThresholdSideSheet> {
  late final Map<String, dynamic> selectedRostersMap;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    selectedRostersMap = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeSelectedRosters();
      _isInitialized = true;
    }
  }

  void _initializeSelectedRosters() {
    final rosterState = ref.read(rosterGroupProvider);
    if (rosterState.groups.isEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _initializeSelectedRosters();
        }
      });
      return;
    }

    for (var channel in widget.channels) {
      if (channel.threshold.full != null && channel.threshold.full!.rosterIds.isNotEmpty) {
        selectedRostersMap["${channel.id}_full"] = _getRosterFromIds(channel.threshold.full!.rosterIds);
      } else {
        selectedRostersMap["${channel.id}_full"] = null;
      }

      if (channel.threshold.reorder != null && channel.threshold.reorder!.rosterIds.isNotEmpty) {
        selectedRostersMap["${channel.id}_reorder"] = _getRosterFromIds(channel.threshold.reorder!.rosterIds);
      } else {
        selectedRostersMap["${channel.id}_reorder"] = null;
      }

      if (channel.threshold.critical != null && channel.threshold.critical!.rosterIds.isNotEmpty) {
        selectedRostersMap["${channel.id}_critical"] = _getRosterFromIds(channel.threshold.critical!.rosterIds);
      } else {
        selectedRostersMap["${channel.id}_critical"] = null;
      }

      if (channel.threshold.low != null && channel.threshold.low!.rosterIds.isNotEmpty) {
        selectedRostersMap["${channel.id}_low"] = _getRosterFromIds(channel.threshold.low!.rosterIds);
      } else {
        selectedRostersMap["${channel.id}_low"] = null;
      }

      if (channel.name == "Level" &&
          channel.threshold.missingInterval != null &&
          channel.threshold.missingInterval!.rosterIds.isNotEmpty) {
        selectedRostersMap["${channel.id}_missing_interval"] =
            _getRosterFromIds(channel.threshold.missingInterval!.rosterIds);
      } else {
        selectedRostersMap["${channel.id}_missing_interval"] = null;
      }
    }

    setState(() {});
  }

  dynamic _getRosterFromIds(List<String> rosterIds) {
    if (rosterIds.isEmpty) return null;

    try {
      final rosterState = ref.read(rosterGroupProvider);
      if (rosterState.groups.isEmpty) {
        return null;
      }

      for (var roster in rosterState.groups) {
        if (rosterIds.contains(roster.id.toString())) {
          return roster;
        }
      }
      return null;
    } catch (e) {
      print('Error getting roster from ID: $e');
      return null;
    }
  }

  void _saveAllData() {
    final Map<String, dynamic> updatedThresholdsData = {};

    for (var channel in widget.channels) {
      final Map<String, dynamic> channelThreshold = {};

      if (channel.threshold.full != null) {
        final roster = selectedRostersMap["${channel.id}_full"];
        final rosterIds = roster != null ? [roster.id.toString()] : [];

        channelThreshold['high'] = {
          'value': channel.threshold.full!.value,
          'comparator': channel.threshold.full!.comparator,
          'rosterIds': rosterIds,
        };
      }

      if (channel.threshold.reorder != null) {
        final roster = selectedRostersMap["${channel.id}_reorder"];
        final rosterIds = roster != null ? [roster.id.toString()] : [];

        channelThreshold['reorder'] = {
          'value': channel.threshold.reorder!.value,
          'comparator': channel.threshold.reorder!.comparator,
          'rosterIds': rosterIds,
        };
      }

      if (channel.threshold.critical != null) {
        final roster = selectedRostersMap["${channel.id}_critical"];
        final rosterIds = roster != null ? [roster.id.toString()] : [];

        channelThreshold['critical'] = {
          'value': channel.threshold.critical!.value,
          'comparator': channel.threshold.critical!.comparator,
          'rosterIds': rosterIds,
        };
      }

      if (channel.threshold.low != null) {
        final roster = selectedRostersMap["${channel.id}_low"];
        final rosterIds = roster != null ? [roster.id.toString()] : [];

        channelThreshold['low'] = {
          'value': channel.threshold.low!.value,
          'comparator': channel.threshold.low!.comparator,
          'rosterIds': rosterIds,
        };
      }

      if (channel.name == "Level" && channel.threshold.missingInterval != null) {
        final roster = selectedRostersMap["${channel.id}_missing_interval"];
        final rosterIds = roster != null ? [roster.id.toString()] : [];

        channelThreshold['missing_interval'] = {
          'value': channel.threshold.missingInterval!.value,
          'comparator': channel.threshold.missingInterval!.comparator,
          'rosterIds': rosterIds,
        };
      }

      updatedThresholdsData[channel.name] = channelThreshold;
    }

    final Map<String, dynamic> requestPayload = {
      'thresholds': updatedThresholdsData,
    };

    widget.onSave(requestPayload);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        width: widget.isNarrow ? MediaQuery.of(context).size.width : 900,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(widget.isNarrow ? 12 : 24),
                child: Column(
                  children: [
                    ...widget.channels.map((channel) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: widget.isNarrow ? 16 : 24),
                        child: _buildRuleSection(channel),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Bottom Save Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isNarrow ? 16 : 32,
        vertical: widget.isNarrow ? 12 : 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tank Events',
                  style: GoogleFonts.outfit(
                    fontSize: widget.isNarrow ? 22 : 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure roster alerts for each tank threshold condition',
                  maxLines: 2,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isNarrow) const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOTTOM BAR
  // =========================================================

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(widget.isNarrow ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: widget.isNarrow ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(width: widget.isNarrow ? 40 : 16),
          if(widget.isNarrow)...[
            Expanded(
              child: ElevatedButton(
                onPressed: _saveAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isNarrow ? 16 : 32,
                    vertical: widget.isNarrow ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: widget.isNarrow ? const Size(double.infinity, 40) : null,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(
                    fontSize: widget.isNarrow ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ]else...[
            ElevatedButton(
              onPressed: _saveAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isNarrow ? 16 : 32,
                  vertical: widget.isNarrow ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: widget.isNarrow ? const Size(double.infinity, 40) : null,
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.outfit(
                  fontSize: widget.isNarrow ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // RULE SECTION
  // =========================================================

  Widget _buildRuleSection(TankChannelModel channel) {
    if (!channel.channelEnable) {
      return const SizedBox.shrink();
    }

    final rules = [
      if (channel.threshold.full != null)
        {
          "title": "Full",
          "value": channel.threshold.full?.value,
          "icon": Icons.water_drop,
          "color": Colors.green,
          "comparator": channel.threshold.full?.comparator,
          "unit": "%",
          "selectedRoster": selectedRostersMap["${channel.id}_full"],
          "key": "${channel.id}_full",
        },
      if (channel.threshold.reorder != null)
        {
          "title": "Reorder",
          "value": channel.threshold.reorder?.value,
          "icon": Icons.inventory_2_outlined,
          "color": Colors.orange,
          "comparator": channel.threshold.reorder?.comparator,
          "unit": "%",
          "selectedRoster": selectedRostersMap["${channel.id}_reorder"],
          "key": "${channel.id}_reorder",
        },
      if (channel.threshold.critical != null)
        {
          "title": "Critical",
          "value": channel.threshold.critical?.value,
          "icon": Icons.warning_amber_rounded,
          "color": Colors.redAccent,
          "comparator": channel.threshold.critical?.comparator,
          "unit": "%",
          "selectedRoster": selectedRostersMap["${channel.id}_critical"],
          "key": "${channel.id}_critical",
        },
      if (channel.threshold.low != null)
        {
          "title": "Low",
          "value": channel.threshold.low?.value,
          "icon": Icons.arrow_downward,
          "color": Colors.red,
          "comparator": channel.threshold.low?.comparator,
          "unit": "%",
          "selectedRoster": selectedRostersMap["${channel.id}_low"],
          "key": "${channel.id}_low",
        },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isNarrow ? 16 : 20,
              vertical: widget.isNarrow ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              "${channel.name} Events",
              style: GoogleFonts.outfit(
                fontSize: widget.isNarrow ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Table Header - Hidden on narrow
          if (!widget.isNarrow)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: _tableHeader("Condition", Icons.info_outline),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: _tableHeader("Operator", Icons.compare_arrows),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: _tableHeader("Threshold", Icons.numbers),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 50,
                    child: _tableHeader("Unit", Icons.ad_units),
                  ),
                  const SizedBox(width: 26),
                  Expanded(
                    flex: 2,
                    child: _tableHeader("Roster(s)", Icons.supervised_user_circle),
                  ),
                ],
              ),
            ),

          // Rules
          ...List.generate(
            rules.length,
                (index) => _buildRuleRow(rules[index], index),
          ),

          // Missing Data
          if (channel.name == "Level" && channel.threshold.missingInterval != null)
            Padding(
              padding: EdgeInsets.all(widget.isNarrow ? 8 : 12),
              child: _buildMissingDataSection(
                channel.threshold.missingInterval!.value,
                selectedRostersMap["${channel.id}_missing_interval"],
                "${channel.id}_missing_interval",
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TABLE HEADER
  // =========================================================

  Widget _tableHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // RULE ROW
  // =========================================================

  Widget _buildRuleRow(Map<String, dynamic> rule, int index) {
    if (widget.isNarrow) {
      return _buildNarrowRuleRow(rule, index);
    }
    return _buildWideRuleRow(rule, index);
  }

  // Wide screen rule row
  Widget _buildWideRuleRow(Map<String, dynamic> rule, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          SizedBox(
            width: 40,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (rule["color"] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                rule["icon"],
                size: 18,
                color: rule["color"],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          SizedBox(
            width: 130,
            child: Text(
              rule["title"],
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Comparator
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                rule["comparator"] ?? ">=",
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Value
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                rule["value"]?.toString() ?? "-",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Unit
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                rule["unit"],
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 26),
          // Rosters
          Expanded(
            flex: 2,
            child: _buildRosterSelector(
              rule["selectedRoster"],
              rule["key"],
            ),
          ),
        ],
      ),
    );
  }

  // Narrow screen rule row
  Widget _buildNarrowRuleRow(Map<String, dynamic> rule, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (rule["color"] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  rule["icon"],
                  size: 16,
                  color: rule["color"],
                ),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Text(
                  rule["title"],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Value and Unit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${rule["value"] ?? "-"} ${rule["unit"]}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comparator and Roster in same row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rule["comparator"] ?? ">=",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRosterSelector(
                  rule["selectedRoster"],
                  rule["key"],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REUSABLE ROSTER SELECTOR
  // =========================================================

  Widget _buildRosterSelector(dynamic selectedRoster, String key) {
    final rosterState = ref.watch(rosterGroupProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isNarrow ? 8 : 12,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedRoster,
          hint: Text(
            'Select roster',
            style: GoogleFonts.outfit(
              fontSize: widget.isNarrow ? 12 : 13,
              color: Colors.grey,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700, size: widget.isNarrow ? 20 : 24),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text(
                'None',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ...rosterState.groups.map((roster) {
              return DropdownMenuItem(
                value: roster,
                child: Text(
                  roster.name,
                  style: GoogleFonts.outfit(
                    fontSize: widget.isNarrow ? 12 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (newValue) {
            setState(() {
              selectedRostersMap[key] = newValue;
            });
          },
        ),
      ),
    );
  }

  // =========================================================
  // MISSING DATA SECTION
  // =========================================================

  Widget _buildMissingDataSection(
      dynamic missingInterval,
      dynamic selectedRoster,
      String key,
      ) {
    final int totalMinutes = int.tryParse(missingInterval.toString()) ?? 0;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;

    if (widget.isNarrow) {
      return _buildNarrowMissingDataSection(hours, minutes, selectedRoster, key);
    }
    return _buildWideMissingDataSection(hours, minutes, selectedRoster, key);
  }

  // Wide missing data section
  Widget _buildWideMissingDataSection(int hours, int minutes, dynamic selectedRoster, String key) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFEF08A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: const Color(0xFFCA8A04),
          ),
          const SizedBox(width: 10),
          Text(
            'Missing Data:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFFEF08A),
              ),
            ),
            child: Text(
              '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCA8A04),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('- Alert when no data received',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 350,
            child: _buildRosterSelector(selectedRoster, key),
          ),
        ],
      ),
    );
  }

  // Narrow missing data section
  Widget _buildNarrowMissingDataSection(int hours, int minutes, dynamic selectedRoster, String key) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFEF08A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: const Color(0xFFCA8A04),
              ),
              const SizedBox(width: 8),
              Text(
                'Missing Data:',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFEF08A),
                  ),
                ),
                child: Text(
                  '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFCA8A04),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('- Alert when no data received',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          _buildRosterSelector(selectedRoster, key),
        ],
      ),
    );
  }
}