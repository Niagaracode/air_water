import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/tank_provider.dart';
import '../widgets/add_tank_modal.dart';
import '../model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import 'dart:async';

class TankWide extends ConsumerStatefulWidget {
  const TankWide({super.key});

  @override
  ConsumerState<TankWide> createState() => _TankWideState();
}

class _TankWideState extends ConsumerState<TankWide> {
  final _plantSearchController = TextEditingController();
  final _tankSearchController = TextEditingController();
  int? _selectedStatus;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tankProvider.notifier).loadGroupedTanks());
  }

  void _onSearchChanged() {
    if (mounted) {
      ref
          .read(tankProvider.notifier)
          .loadGroupedTanks(
            plantName: _plantSearchController.text,
            tankName: _tankSearchController.text,
            status: _selectedStatus,
          );
    }
  }

  @override
  void dispose() {
    _plantSearchController.dispose();
    _tankSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tankProvider);
    final notifier = ref.read(tankProvider.notifier);

    return Scaffold(
      backgroundColor: cardBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildManagementCard(state, notifier)],
        ),
      ),
    );
  }

  Widget _buildManagementCard(TankState state, TankNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TANK MANAGEMENT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Centralize Tank Information Including Dimensions, Types, Products And Plant Associations',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildFilterRow(),
          const SizedBox(height: 16),
          _buildGroupedTable(state, notifier),
          if (state.hasMore && state.groupedTanks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => notifier.loadMore(
                          plantName: _plantSearchController.text,
                          tankName: _tankSearchController.text,
                          status: _selectedStatus,
                        ),
                        child: const Text('Load More'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildPlantAutocomplete()),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildTankAutocomplete()),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<int?>(
            value: _selectedStatus,
            items: const [null, 1, 0],
            itemLabel: (v) =>
                v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
            hint: 'Status',
            onChanged: (v) {
              setState(() => _selectedStatus = v);
              _onSearchChanged();
            },
          ),
        ),
        const SizedBox(width: 32),
        ElevatedButton.icon(
          onPressed: () => _showAddDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADD'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDeep,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<PlantAutocompleteInfo>(
          textEditingController: _plantSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty)
              return const Iterable<PlantAutocompleteInfo>.empty();
            return await ref
                .read(tankProvider.notifier)
                .searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
              option.plantName,
          onSelected: (option) => _onSearchChanged(),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Plant',
              onSubmitted: (v) => _onSearchChanged(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.plantName),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTankAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _tankSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty)
              return const Iterable<String>.empty();
            return await ref
                .read(tankProvider.notifier)
                .getTankNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          onSelected: (option) => _onSearchChanged(),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Tank',
              onSubmitted: (v) => _onSearchChanged(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupedTable(TankState state, TankNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: Row(
                children: [
                  _tableHeaderCell('SI.NO', width: 70),
                  _tableHeaderCell('Image', width: 80),
                  _tableHeaderCell('Tank Number', flex: 2),
                  _tableHeaderCell('Type', flex: 2),
                  _tableHeaderCell('Product', flex: 2),
                  _tableHeaderCell('Unit', flex: 1),
                  _tableHeaderCell('H / W / Dish', flex: 2),
                  _tableHeaderCell('Status', flex: 1),
                  _tableHeaderCell('Actions', width: 100),
                ],
              ),
            ),
            if (state.groupedTanks.isEmpty && !state.isLoading)
              Container(
                padding: const EdgeInsets.all(48),
                alignment: Alignment.center,
                child: const Text(
                  'No record found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            else
              ...List.generate(state.groupedTanks.length, (index) {
                return _buildGroupSection(
                  index,
                  state.groupedTanks[index],
                  notifier,
                );
              }),
            if (state.isLoading && state.groupedTanks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String text, {double? width, int? flex}) {
    final child = Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex ?? 1, child: child);
  }

  Widget _buildGroupSection(
    int groupIndex,
    TankGroup group,
    TankNotifier notifier,
  ) {
    return Column(
      children: [
        if (groupIndex > 0) Divider(height: 1, color: Colors.grey.shade200),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  (groupIndex + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.plantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1B1B4B),
                      ),
                    ),
                    if (group.fullAddress.isNotEmpty)
                      Text(
                        group.fullAddress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(flex: 9),
            ],
          ),
        ),
        ...group.tanks.map((tank) => _buildTankRow(tank, notifier)),
      ],
    );
  }

  Widget _buildTankRow(Tank tank, TankNotifier notifier) {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey.shade100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 70),
              SizedBox(
                width: 80,
                child: tank.tankImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          tank.tankImageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                'No Image',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                      )
                    : const Text(
                        'No Image',
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tank.tankNumber,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tank.tankTypeName ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tank.productName ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  tank.unitName ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${tank.height ?? 0} / ${tank.width ?? 0} / ${tank.dishHeight ?? 0}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(flex: 1, child: _buildStatusChip(tank)),
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      onPressed: () => _showAddDialog(tank),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                      onPressed: () => _showDeleteDialog(tank),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Tank tank) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: tank.status == 1 ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          tank.statusText,
          style: TextStyle(
            color: tank.status == 1 ? Colors.green : Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showAddDialog([Tank? tank]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddTank',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AddTankModal(initialTank: tank),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Tank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tank'),
        content: Text(
          'Are you sure you want to delete tank "${tank.tankNumber}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tankProvider.notifier).deleteTank(tank.tankId);
    }
  }
}
