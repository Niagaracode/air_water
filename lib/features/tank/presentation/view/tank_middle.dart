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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeader(state, notifier),
                  if (state.error != null) _buildErrorBanner(state.error!),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.groupedTanks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildHeader(TankState state, TankNotifier notifier) {
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
        _buildPlantAutocomplete(notifier),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTankAutocomplete(notifier)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _plantSearchController.clear();
                _tankSearchController.clear();
                notifier.clearFilters();
              },
              child: const Text('CLEAR'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppDropdown<int?>(
          value: state.selectedStatus,
          items: const [null, 1, 0],
          itemLabel: (v) =>
              v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
          hint: 'Select Status',
          onChanged: (v) => notifier.setStatus(v),
        ),
      ],
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

  Widget _buildVirtualizedList(TankState state, TankNotifier notifier) {
    if (state.isLoading && state.groupedTanks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && state.groupedTanks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
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
        return _buildGroupCard(state.groupedTanks[index], notifier);
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
    if (confirmed == true) {
      await ref.read(tankProvider.notifier).deleteTank(tank.tankId);
    }
  }
}
