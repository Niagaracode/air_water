import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RuleGroupNarrow extends ConsumerStatefulWidget {
  const RuleGroupNarrow({super.key});

  @override
  ConsumerState<RuleGroupNarrow> createState() => _RuleGroupNarrowState();
}

class _RuleGroupNarrowState extends ConsumerState<RuleGroupNarrow> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TANK MANAGEMENT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(child: Text('TankNarrow')),
    );
  }
}
