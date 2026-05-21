import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class TankNarrow extends ConsumerStatefulWidget {
  const TankNarrow({super.key});

  @override
  ConsumerState<TankNarrow> createState() => _TankNarrowState();
}

class _TankNarrowState extends ConsumerState<TankNarrow> {

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
