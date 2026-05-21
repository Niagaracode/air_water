import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/model/tank_model.dart';
import '../controller/tank_provider.dart';
import '../widgets/add_tank_modal.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import 'dart:async';

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
