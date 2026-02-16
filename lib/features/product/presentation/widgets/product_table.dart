import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../data/product_model.dart';
import 'header_style.dart';

class ProductTable extends StatelessWidget {
  final List<Product> list;
  const ProductTable(this.list, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 5, bottom: 8),
            child: const Text(
              'PRODUCT MANAGER',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: DataTable2(
                  columnSpacing: 30,
                  headingRowHeight: 45,
                  dataRowHeight: 44,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade300,
                  ),
                  columns: [
                    DataColumn2(
                      label: Text('ID', style: headerStyle),
                      size: ColumnSize.S,
                    ),
                    DataColumn2(
                      label: Text('PRODUCT NAME', style: headerStyle),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('DESCRIPTION', style: headerStyle),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text('SCM / M3', style: headerStyle),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                    DataColumn2(
                      label: Text('SPECIFIC GRAVITY', style: headerStyle),
                      size: ColumnSize.S,
                      numeric: true,
                    ),
                  ],

                  rows: list.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return DataRow2(
                      onTap: () {
                      },
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(p.name)),
                        DataCell(Text(
                          p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )),
                        DataCell(Text(p.scmM3.toStringAsFixed(2))),
                        DataCell(Text(p.specificGravity.toStringAsFixed(3))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}