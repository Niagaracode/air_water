import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class RuleGroupMiddle extends ConsumerStatefulWidget {
  const RuleGroupMiddle({super.key});

  @override
  ConsumerState<RuleGroupMiddle> createState() => _RuleGroupMiddleState();
}

class _RuleGroupMiddleState extends ConsumerState<RuleGroupMiddle> {

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
          'Middle MANAGEMENT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(child: Text('TankNarrow')),
    );
  }
}
