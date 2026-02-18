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

class TankNarrow extends ConsumerStatefulWidget {
  const TankNarrow({super.key});

  @override
  ConsumerState<TankNarrow> createState() => _TankNarrowState();
}

class _TankNarrowState extends ConsumerState<TankNarrow> {
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
      appBar: AppBar(
        title: const Text(
          'TANK MANAGEMENT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                _buildPlantAutocomplete(),
                const SizedBox(height: 8),
                _buildTankAutocomplete(),
                const SizedBox(height: 8),
                AppDropdown<int?>(
                  value: _selectedStatus,
                  items: const [null, 1, 0],
                  itemLabel: (v) => v == null
                      ? 'All Status'
                      : (v == 1 ? 'Active' : 'Inactive'),
                  hint: 'Select Status',
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _onSearchChanged();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ...state.groupedTanks.map((group) => _buildGroup(group, notifier)),
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroup(TankGroup group, TankNotifier notifier) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          group.plantName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: group.fullAddress.isNotEmpty
            ? Text(
                group.fullAddress,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            : null,
        children: group.tanks
            .map((tank) => _buildTankCard(tank, notifier))
            .toList(),
      ),
    );
  }

  Widget _buildTankCard(Tank tank, TankNotifier notifier) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
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
          '${tank.tankTypeName ?? ''} | ${tank.productName ?? ''} | ${tank.height ?? 0}/${tank.width ?? 0}/${tank.dishHeight ?? 0}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) {
            if (v == 'edit') _showAddDialog(tank);
            if (v == 'delete') _showDeleteDialog(tank);
          },
        ),
      ),
    );
  }

  void _showAddDialog([Tank? tank]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTankModal(initialTank: tank),
    );
  }

  Future<void> _showDeleteDialog(Tank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${tank.tankNumber}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed == true)
      await ref.read(tankProvider.notifier).deleteTank(tank.tankId);
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
}
