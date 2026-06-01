import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class TankMiddle extends ConsumerStatefulWidget {
  const TankMiddle({super.key});

  @override
  ConsumerState<TankMiddle> createState() => _TankMiddleState();
}

class _TankMiddleState extends ConsumerState<TankMiddle> {


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
      body: Center(child: Text('TankMiddle')),
    );
  }

}
