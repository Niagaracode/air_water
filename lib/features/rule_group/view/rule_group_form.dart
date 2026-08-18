import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/rule_group/provider/rule_group_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/rule_group_model.dart';

class RuleGroupForm extends ConsumerStatefulWidget {
  final RuleGroupModel? initialRule;
  final bool isNarrow;

  const RuleGroupForm({
    super.key,
    this.initialRule, required this.isNarrow,
  });

  @override
  ConsumerState<RuleGroupForm> createState() => _RuleGroupFormState();
}

class _RuleGroupFormState extends ConsumerState<RuleGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _missingHourController = TextEditingController();
  final TextEditingController _missingMinuteController = TextEditingController();

  late Map<String, List<Map<String, dynamic>>> ruleData;

  @override
  void initState() {
    super.initState();
    _initializeRuleData();
  }

  void _initializeRuleData() {
    // Initialize with empty/default structure
    ruleData = {
      "Level": [
        {
          "description": "Full",
          "comparator": ">=",
          "value": "",
          "unit": "%",
          "icon": Icons.water_drop_outlined,
          "color": const Color(0xFF3B82F6),
        },
        {
          "description": "Reorder",
          "comparator": "<=",
          "value": "",
          "unit": "%",
          "icon": Icons.swap_horiz,
          "color": const Color(0xFFF59E0B),
        },
        {
          "description": "Critical",
          "comparator": "<=",
          "value": "",
          "unit": "%",
          "icon": Icons.warning_amber_rounded,
          "color": const Color(0xFFEF4444),
        },
        {
          "description": "Empty",
          "comparator": "<=",
          "value": "",
          "unit": "%",
          "icon": Icons.inbox,
          "color": const Color(0xFF6B7280),
        },
      ],
      "Pressure": [
        {
          "description": "High Pressure",
          "comparator": "<=",
          "value": "",
          "unit": "Bar",
          "icon": Icons.speed,
          "color": const Color(0xFF8B5CF6),
        },
        {
          "description": "Low Pressure",
          "comparator": "<=",
          "value": "",
          "unit": "Bar",
          "icon": Icons.speed,
          "color": const Color(0xFF8B5CF6),
        },
      ],
      "Battery": [
        {
          "description": "Low Voltage",
          "comparator": "<=",
          "value": "",
          "unit": "Volt",
          "icon": Icons.battery_alert,
          "color": const Color(0xFF10B981),
        },
      ],
      "Solar": [
        {
          "description": "Low Voltage",
          "comparator": "<=",
          "value": "",
          "unit": "Volt",
          "icon": Icons.solar_power,
          "color": const Color(0xFFF59E0B),
        },
      ],
    };

    // If editing existing rule, populate the data
    if (widget.initialRule != null) {
      _populateExistingData();
    }
  }

  void _populateExistingData() {
    // Set rule group name
    _ruleNameController.text = widget.initialRule!.ruleGroupName;

    // Populate rules data
    for (var rule in widget.initialRule!.rules) {
      if (ruleData.containsKey(rule.category)) {
        final eventsList = ruleData[rule.category]!;

        // Populate event values
        for (var event in rule.events) {
          final existingEvent = eventsList.cast<Map<String, dynamic>>().firstWhere(
                (e) => e["description"] == event.description,
            orElse: () => null as Map<String, dynamic>,
          );

          existingEvent["value"] = event.value.toString();
          existingEvent["comparator"] = event.comparator;
        }

        // Populate missing data for Level category
        if (rule.category.toLowerCase() == "level" && rule.missingData != null) {
          _missingHourController.text = rule.missingData!.hours.toString();
          _missingMinuteController.text = rule.missingData!.minutes.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _ruleNameController.dispose();
    _missingHourController.dispose();
    _missingMinuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        elevation: 24,
        shadowColor: Colors.black26,
        child: SizedBox(
          width: 900,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // Header with sticky behavior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialRule != null ? 'Edit Rule Group' : 'Create Rule Group',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Configure alert rules and thresholds',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding:  EdgeInsets.all(widget.isNarrow ? 16 : 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rule Group Name Card
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rule Group Name",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 400,
                              child: TextFormField(
                                controller: _ruleNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a rule group name';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hintText: "e.g., Tank Level Alerts",
                                  prefixIcon: Icons.label_outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Rule Sections
                        ...ruleData.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildRuleSection(entry.key, entry.value),
                        )),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                label: Text(
                                  "Cancel",
                                  style: GoogleFonts.outfit(),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _saveRules,
                                icon: const Icon(Icons.save, size: 18),
                                label: Text(
                                  widget.initialRule != null ? "Update Rules" : "Save Rules",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleSection(String title, List<Map<String, dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              "$title Events",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: widget.isNarrow? 10:20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: widget.isNarrow ? 2:3,
                  child: _tableHeader("Condition", Icons.info_outline),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeader("Operator", Icons.compare_arrows),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeader("Threshold", Icons.numbers),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeader("Unit", Icons.ad_units),
                ),
              ],
            ),
          ),
          // Rows
          ...rows.asMap().entries.map((entry) => _buildRuleRow(entry.value, entry.key)),
          // Missing Data Section for Level
          if (title == "Level") _buildMissingDataRow(),
        ],
      ),
    );
  }

  Widget _buildRuleRow(Map<String, dynamic> rule, int index) {
    final controller = TextEditingController(text: rule["value"].toString());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.isNarrow? 10:20, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          // Icon with color
          SizedBox(
            width: 40,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (rule["color"] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                rule["icon"],
                size: 18,
                color: rule["color"],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Description
          Expanded(
            flex: widget.isNarrow? 2:3,
            child: Text(
              rule["description"],
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          // Comparator Dropdown
          Expanded(
            flex: 2,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: rule["comparator"],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [">=", "<=", ">", "<"].map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, style: GoogleFonts.outfit(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => rule["comparator"] = v),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Value Input
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 100,
              child: TextFormField(
                controller: controller,
                onChanged: (v) => rule["value"] = v,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Enter value",
                  errorStyle: const TextStyle(fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.outfit(fontSize: 13),
              ),
            ),
          ),
          // Unit
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              rule["unit"],
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingDataRow() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: const Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                "Missing Data Configuration",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if(widget.isNarrow)...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    "Alert if no data received for:",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: TextFormField(
                            controller: _missingHourController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Optional field
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Hours",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Hour(s)", style: GoogleFonts.outfit(fontSize: 13)),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: TextFormField(
                            controller: _missingMinuteController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Optional field
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Minutes",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Min(s)", style: GoogleFonts.outfit(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ]else...[
            Row(
              children: [
                const SizedBox(width: 26),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Alert if no data received for:",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextFormField(
                          controller: _missingHourController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Optional field
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Hours",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: GoogleFonts.outfit(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Hour(s)", style: GoogleFonts.outfit(fontSize: 13)),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextFormField(
                          controller: _missingMinuteController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Optional field
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Minutes",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: GoogleFonts.outfit(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Min(s)", style: GoogleFonts.outfit(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],

        ],
      ),
    );
  }

  Widget _tableHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.grey.shade500) : null,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  Future<void> _saveRules() async {
    if (_formKey.currentState?.validate() ?? false) {
      bool hasEmptyValues = false;
      for (var entry in ruleData.entries) {
        for (var rule in entry.value) {
          if (rule["value"].toString().isEmpty) {
            hasEmptyValues = true;
            break;
          }
        }
      }

      if (hasEmptyValues) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all threshold values'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final payload = {
        "rule_group_name": _ruleNameController.text,
        "rules": ruleData.entries.map((entry) {
          return {
            "category": entry.key,
            "events": entry.value.map((e) {
              return {
                "description": e["description"],
                "comparator": e["comparator"],
                "value": num.tryParse(e["value"].toString()) ?? e["value"],
                "unit": e["unit"],
              };
            }).toList(),
            if (entry.key == "Level" &&
                (_missingHourController.text.isNotEmpty || _missingMinuteController.text.isNotEmpty))
              "missing_data": {
                "hours": int.tryParse(_missingHourController.text) ?? 0,
                "minutes": int.tryParse(_missingMinuteController.text) ?? 0,
              },
          };
        }).toList(),
      };

      debugPrint('Saving payload: $payload');

      final ruleGroupNotifier = ref.read(ruleGroupProvider.notifier);
      bool success;

      if (widget.initialRule != null) {
        success = await ruleGroupNotifier.updateRuleGroup(widget.initialRule!.id, payload);
      } else {
        success = await ruleGroupNotifier.createRuleGroup(payload);
        if (success) {
          // ... handled inside notifier if needed, or if we need the ID here later
        }
      }

      if (success && mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.initialRule != null
                  ? 'Rule group updated successfully'
                  : 'Rule group created successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        Navigator.pop(context);
      }

    }
  }
}