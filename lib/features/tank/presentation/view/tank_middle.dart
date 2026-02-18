import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/tank_provider.dart';
import '../widgets/add_tank_modal.dart';
import '../model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import 'dart:async';

class TankMiddle extends ConsumerStatefulWidget {
  const TankMiddle({super.key});

  @override
  ConsumerState<TankMiddle> createState() => _TankMiddleState();
}

class _TankMiddleState extends ConsumerState<TankMiddle> {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            ...state.groupedTanks.map(
              (group) => _buildGroupCard(group, notifier),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TANK MANAGEMENT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () => _showAddDialog(),
              child: const Text('ADD'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPlantAutocomplete(),
        const SizedBox(height: 12),
        _buildTankAutocomplete(),
        const SizedBox(height: 12),
        AppDropdown<int?>(
          value: _selectedStatus,
          items: const [null, 1, 0],
          itemLabel: (v) =>
              v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
          hint: 'Select Status',
          onChanged: (v) {
            setState(() => _selectedStatus = v);
            _onSearchChanged();
          },
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

  Widget _buildGroupCard(TankGroup group, TankNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.plantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1B4B),
                    fontSize: 14,
                  ),
                ),
                if (group.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.fullAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ...group.tanks.map((tank) => _buildTankItem(tank, notifier)),
        ],
      ),
    );
  }

  Widget _buildTankItem(Tank tank, TankNotifier notifier) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: tank.tankImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  tank.tankImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'No Image',
                      style: TextStyle(fontSize: 8, color: Colors.red),
                    ),
                  ),
                ),
              )
            : const Center(
                child: Text(
                  'No Image',
                  style: TextStyle(fontSize: 8, color: Colors.red),
                ),
              ),
      ),
      title: Text(tank.tankNumber),
      subtitle: Text(
        '${tank.tankTypeName ?? ''} | ${tank.productName ?? ''} | H:${tank.height ?? 0} W:${tank.width ?? 0} D:${tank.dishHeight ?? 0}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showAddDialog(tank),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(tank),
          ),
        ],
      ),
    );
  }

  void _showAddDialog([Tank? tank]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddTank',
      barrierColor: Colors.black54,
      pageBuilder: (context, anim1, anim2) => AddTankModal(initialTank: tank),
    );
  }

  Future<void> _showDeleteDialog(Tank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tank'),
        content: Text('Delete tank "${tank.tankNumber}"?'),
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
    if (confirmed == true)
      await ref.read(tankProvider.notifier).deleteTank(tank.tankId);
  }
}
