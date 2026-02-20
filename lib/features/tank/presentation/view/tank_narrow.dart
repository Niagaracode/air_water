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
  final _scrollController = ScrollController();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(tankProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _plantSearchController.dispose();
    _tankSearchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tankProvider);
    final notifier = ref.read(tankProvider.notifier);

    // Sync controllers
    if (state.searchPlant != _plantSearchController.text &&
        state.searchPlant.isEmpty) {
      _plantSearchController.text = '';
    }
    if (state.searchTank != _tankSearchController.text &&
        state.searchTank.isEmpty) {
      _tankSearchController.text = '';
    }

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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildErrorBanner(state.error!),
                    ),
                  _buildPlantAutocomplete(notifier),
                  const SizedBox(height: 8),
                  _buildTankAutocomplete(notifier),
                  const SizedBox(height: 8),
                  AppDropdown<int?>(
                    value: state.selectedStatus,
                    items: const [null, 1, 0],
                    itemLabel: (v) => v == null
                        ? 'All Status'
                        : (v == 1 ? 'Active' : 'Inactive'),
                    hint: 'Select Status',
                    onChanged: (v) => notifier.setStatus(v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _plantSearchController.clear();
                        _tankSearchController.clear();
                        notifier.clearFilters();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.groupedTanks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildVirtualizedList(TankState state, TankNotifier notifier) {
    if (state.isLoading && state.groupedTanks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && state.groupedTanks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No Record Found',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.groupedTanks.length,
      itemBuilder: (context, index) {
        return _buildGroup(state.groupedTanks[index], notifier);
      },
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
          style: const TextStyle(fontSize: 11),
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
    if (confirmed == true) {
      await ref.read(tankProvider.notifier).deleteTank(tank.tankId);
    }
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => ref.read(tankProvider.notifier).loadGroupedTanks(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantAutocomplete(TankNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<PlantAutocompleteInfo>(
          textEditingController: _plantSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<PlantAutocompleteInfo>.empty();
            }
            return await notifier.searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
              option.plantName,
          onSelected: (option) {
            notifier.setSearchPlant(option.plantName);
            notifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Plant',
              onSubmitted: (v) {
                notifier.setSearchPlant(v);
                notifier.loadGroupedTanks();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
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

  Widget _buildTankAutocomplete(TankNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _tankSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await notifier.getTankNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          onSelected: (option) {
            notifier.setSearchTank(option);
            notifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Tank',
              onSubmitted: (v) {
                notifier.setSearchTank(v);
                notifier.loadGroupedTanks();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
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
