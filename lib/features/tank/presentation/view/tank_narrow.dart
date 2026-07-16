import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/tank_provider.dart';
import '../widgets/add_tank_modal.dart';
import '../../data/model/tank_model.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../../shared/widgets/app_clear_button.dart';

class TankNarrow extends ConsumerStatefulWidget {
  const TankNarrow({super.key});

  @override
  ConsumerState<TankNarrow> createState() => _TankNarrowState();
}

class _TankNarrowState extends ConsumerState<TankNarrow> {
  final _siteSearchController = TextEditingController();
  final _tankSearchController = TextEditingController();
  final _siteFocusNode = FocusNode();
  final _tankFocusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _siteSearchController.dispose();
    _tankSearchController.dispose();
    _siteFocusNode.dispose();
    _tankFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tankState = ref.watch(tankNotifierProvider);
    final tankNotifier = ref.read(tankNotifierProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildHeader(tankState, tankNotifier),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            sliver: _buildVirtualizedTable(tankState, tankNotifier),
          ),
          if (tankState.isLoading && tankState.groupedTanks.isNotEmpty)
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
                    const Text(
                      'Please wait loading new record',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
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

  Widget _buildHeader(TankState tankState, TankNotifier tankNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'TANK MANAGEMENT',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RawAutocomplete<SiteAutocompleteInfo>(
          textEditingController: _siteSearchController,
          focusNode: _siteFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<SiteAutocompleteInfo>.empty();
            }
            return await tankNotifier.searchSites(textEditingValue.text);
          },
          displayStringForOption: (SiteAutocompleteInfo option) =>
              option.siteName,
          onSelected: (SiteAutocompleteInfo selection) {
            _siteSearchController.text = selection.siteName;
            tankNotifier.setSearchSite(selection.siteName);
            tankNotifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Site',
              onSubmitted: (value) {
                _siteSearchController.text = value;
                tankNotifier.setSearchSite(value);
                tankNotifier.loadGroupedTanks();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 24,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.siteName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: option.fullAddress.isNotEmpty
                            ? Text(
                                option.fullAddress,
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        RawAutocomplete<String>(
          textEditingController: _tankSearchController,
          focusNode: _tankFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await tankNotifier.getTankNameSuggestions(
              textEditingValue.text,
            );
          },
          displayStringForOption: (String option) => option,
          onSelected: (String selection) {
            _tankSearchController.text = selection;
            tankNotifier.setSearchTank(selection);
            tankNotifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Tank',
              onSubmitted: (value) {
                _tankSearchController.text = value;
                tankNotifier.setSearchTank(value);
                tankNotifier.loadGroupedTanks();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 24,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDropdown<int?>(
                value: tankState.selectedStatus,
                items: const [null, 1, 0],
                itemLabel: (v) =>
                    v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
                hint: 'Status',
                onChanged: (v) => tankNotifier.setStatus(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppClearButton(
              onPressed: () {
                _siteSearchController.clear();
                _tankSearchController.clear();
                tankNotifier.clearFilters();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Showing  ${tankState.totalEntries} entries',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(TankState tankState, TankNotifier notifier) {
    if (tankState.groupedTanks.isEmpty && !tankState.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No tanks found',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    if (tankState.isLoading && tankState.groupedTanks.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> items = [];
    for (int i = 0; i < tankState.groupedTanks.length; i++) {
      final group = tankState.groupedTanks[i];
      items.add({'type': 'header', 'group': group, 'index': i + 1});
      for (final tank in group.tanks) {
        items.add({'type': 'row', 'tank': tank, 'group': group});
      }
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        if (item['type'] == 'header') {
          return _buildGroupHeader(
            tankState,
            item['group'] as TankGroup,
            item['index'] as int,
            isLast,
          );
        } else {
          return _buildTankRow(
            item['tank'] as Tank,
            item['group'] as TankGroup,
            isLast,
          );
        }
      },
    );
  }

  Widget _buildGroupHeader(
    TankState state,
    TankGroup group,
    int index,
    bool isLast,
  ) {
    String headerText;
    int tanksCount = 0;
    try {
      final raw = group.siteName.trim();
      if (raw.isNotEmpty && raw != 'null') {
        headerText = raw;
      } else {
        String? foundSiteName;
        for (final t in group.tanks) {
          final sn = (t.siteName ?? '').trim();
          if (sn.isNotEmpty && sn != 'null') {
            foundSiteName = sn;
            break;
          }
        }
        headerText = foundSiteName ?? '';
      }
      tanksCount = group.tanks.length;
    } catch (e) {
      headerText = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          top: BorderSide.none,
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    '$tanksCount TANKS',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTankRow(Tank tank, TankGroup group, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: isLast
              ? BorderSide(color: Colors.grey.shade200)
              : BorderSide(color: Colors.grey.shade100),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 30),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tank.tankNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Site: ${tank.siteName ?? '—'}  |  Device: ${tank.deviceId ?? '—'}  |  Product: ${tank.productName ?? '—'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tank.fullAddress,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: primary, size: 14),
                    onPressed: () => _showAddDialog(tank),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade400,
                      size: 14,
                    ),
                    onPressed: () => _showDeleteDialog(tank),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog([Tank? tank]) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddTank',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AddTankModal(
        tank: tank,
        onSuccess: () {
          ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
        },
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Tank',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete tank "${tank.tankNumber}"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(tankNotifierProvider.notifier)
          .deleteTank(tank.tankId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tank deleted successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }
}
