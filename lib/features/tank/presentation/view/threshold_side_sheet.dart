import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../data/model/tank_channel_model.dart';

class ThresholdSideSheet extends StatelessWidget {

  final List<TankChannelModel> channels;

  const ThresholdSideSheet({
    super.key,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {

    return Drawer(
      width: 1000,
      backgroundColor: Colors.white,

      child: Column(
        children: [

          /// BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: channels.map((channel) {

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 28),

                    child: _buildChannelSection(
                      title: channel.name,
                      channel: channel,
                    ),
                  );

                }).toList(),
              ),
            ),
          ),

          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildChannelSection({
    required String title,
    required TankChannelModel channel,
  }) {

    final rows = _buildRows(channel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: (rows.length * 58) + 70,

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),

            child: DataTable2(
              columnSpacing: 18,
              horizontalMargin: 16,
              minWidth: 900,
              headingRowHeight: 50,
              dataRowHeight: 60,

              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade100,
                ),

                verticalInside: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),

              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF5F5F5),
              ),

              columns: const [

                DataColumn2(
                  label: Text(''),
                  fixedWidth: 50,
                ),

                DataColumn2(
                  label: Text('EVENT'),
                  size: ColumnSize.L,
                ),

                DataColumn2(
                  label: Text('EVENT VALUES'),
                  size: ColumnSize.L,
                ),

                DataColumn2(
                  label: Text('ROSTER(S)'),
                  size: ColumnSize.L,
                ),
              ],

              rows: rows.map((item) {

                return DataRow(
                  cells: [

                    /// ICON
                    DataCell(
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.grey,

                        child: const Icon(
                          Icons.link,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    /// EVENT
                    DataCell(
                      Text(
                        item.event,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    /// VALUE
                    DataCell(
                      Row(
                        children: [

                          if (item.operator.isNotEmpty)
                            Container(
                              width: 50,
                              height: 46,
                              alignment: Alignment.center,

                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),

                              child: Text(item.operator),
                            ),

                          const SizedBox(width: 8),

                          SizedBox(
                            width: 190,

                            child: TextFormField(
                              initialValue: item.value,
                              decoration: _inputDecoration(),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(item.unit),
                        ],
                      ),
                    ),

                    /// ROSTER
                    DataCell(
                      DropdownButtonFormField<String>(
                        value: item.roster,

                        decoration: _inputDecoration(),

                        items: {
                          'Maintenance Team',
                          'Operations Team',
                          'Admin Team',
                        }
                            .map((e) {

                          return DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          );

                        }).toList(),

                        onChanged: (value) {},
                      ),
                    ),
                  ],
                );

              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  List<ThresholdRowData> _buildRows(TankChannelModel channel) {

    final List<ThresholdRowData> rows = [];

    final threshold = channel.threshold;

    if (threshold.reorder != null) {
      rows.add(
        ThresholdRowData(
          event: 'Reorder',
          operator: '<=',
          value: threshold.reorder!.value.toString(),
          unit: _getUnit(channel.name),
          roster: 'Operations Team',
        ),
      );
    }

    if (threshold.low != null) {
      rows.add(
        ThresholdRowData(
          event: 'Low',
          operator: '<=',
          value: threshold.low!.value.toString(),
          unit: _getUnit(channel.name),
          roster:  'Maintenance Team',
        ),
      );
    }

    if (threshold.critical != null) {
      rows.add(
        ThresholdRowData(
          event: 'Critical',
          operator: '<=',
          value: threshold.critical!.value.toString(),
          unit: _getUnit(channel.name),
          roster:  'Admin Team',
        ),
      );
    }

    if (threshold.dataInterval != null) {
      rows.add(
        ThresholdRowData(
          event: 'Data Interval',
          operator: '',
          value: threshold.dataInterval!.value.toString(),
          unit: 'Min',
          roster: 'Operations Team',
        ),
      );
    }

    if (threshold.missingInterval != null) {
      rows.add(
        ThresholdRowData(
          event: 'Missing Interval',
          operator: '',
          value: threshold.missingInterval!.value.toString(),
          unit: 'Min',
          roster: 'Operations Team',
        ),
      );
    }

    return rows;
  }

  String _getUnit(String name) {

    switch (name.toLowerCase()) {

      case 'level':
        return '%';

      case 'pressure':
        return 'Bar';

      case 'battery voltage':
        return 'Volts';

      case 'solar voltage':
        return 'Volts';

      default:
        return '';
    }
  }

  Widget _buildBottomActions(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,

        children: [

          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),

          const SizedBox(width: 14),

          ElevatedButton(
            onPressed: () {},
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {

    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
    );
  }
}

class ThresholdRowData {

  final String event;
  final String operator;
  final String value;
  final String unit;
  final String roster;

  ThresholdRowData({
    required this.event,
    required this.operator,
    required this.value,
    required this.unit,
    required this.roster,
  });
}