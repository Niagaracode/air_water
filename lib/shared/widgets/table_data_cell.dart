import 'package:flutter/material.dart';

class TableDataCell extends StatelessWidget {
  const TableDataCell({super.key, required this.label});
  final String  label;

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}