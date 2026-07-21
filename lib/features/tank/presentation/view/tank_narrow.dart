import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
    }
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

  void _clearSiteSearch() {
    _siteSearchController.clear();
    _siteFocusNode.unfocus();
    ref.read(tankNotifierProvider.notifier).setSearchSite('');
    ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
  }

  void _clearTankSearch() {
    _tankSearchController.clear();
    _tankFocusNode.unfocus();
    ref.read(tankNotifierProvider.notifier).setSearchTank('');
    ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
  }

  static final List<Color> _groupColors = [
    const Color(0xFF6366F1), // indigo
    const Color(0xFF0EA5E9), // sky
    const Color(0xFF10B981), // emerald
    const Color(0xFFF59E0B), // amber
    const Color(0xFFEC4899), // pink
    const Color(0xFF8B5CF6), // violet
    const Color(0xFF14B8A6), // teal
  ];

  Color _colorForGroup(String key) {
    if (key.trim().isEmpty) return primary;
    final hash =
    key.toLowerCase().trim().codeUnits.fold<int>(0, (p, c) => p + c);
    return _groupColors[hash % _groupColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final tankState = ref.watch(tankNotifierProvider);
    final tankNotifier = ref.read(tankNotifierProvider.notifier);

    // Sync controllers
    if (tankState.searchSite != _siteSearchController.text &&
        tankState.searchSite.isEmpty) {
      _siteSearchController.text = '';
    }
    if (tankState.searchTank != _tankSearchController.text &&
        tankState.searchTank.isEmpty) {
      _tankSearchController.text = '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 2,
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add tank',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _buildHeader(tankState, tankNotifier),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: _buildVirtualizedList(tankState, tankNotifier),
          ),
          if (tankState.isLoading && tankState.groupedTanks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading more tanks…',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _buildHeader(TankState tankState, TankNotifier tankNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.propane_tank_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANK MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Showing ${tankState.totalEntries} entries',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Site Search with clear button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: RawAutocomplete<SiteAutocompleteInfo>(
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
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Filter by site',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                        onPressed: _clearSiteSearch,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                          : const SizedBox.shrink();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
                onFieldSubmitted: (value) {
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option.siteName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: option.fullAddress.isNotEmpty
                              ? Text(
                            option.fullAddress,
                            style: GoogleFonts.inter(fontSize: 12.5),
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
        ),
        const SizedBox(height: 12),
        // Tank Search with clear button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: RawAutocomplete<String>(
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
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Filter by tank',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                        onPressed: _clearTankSearch,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                          : const SizedBox.shrink();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
                onFieldSubmitted: (value) {
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
      ],
    );
  }

  Widget _buildVirtualizedList(TankState tankState, TankNotifier notifier) {
    if (tankState.groupedTanks.isEmpty && !tankState.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.propane_tank_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No tanks found',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (tankState.isLoading && tankState.groupedTanks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SliverList.builder(
      itemCount: tankState.groupedTanks.length,
      itemBuilder: (context, index) {
        final group = tankState.groupedTanks[index];
        return _buildGroupCard(group, index + 1);
      },
    );
  }

  Widget _buildGroupCard(TankGroup group, int index) {
    String headerText;
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
        headerText = foundSiteName ?? 'Untitled site';
      }
    } catch (e) {
      headerText = 'Untitled site';
    }

    final groupColor = _colorForGroup(headerText);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: groupColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerText,
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: groupColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${group.tanks.length} tanks',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(group.tanks.length, (i) {
            final isLast = i == group.tanks.length - 1;
            return _buildTankRow(group.tanks[i], isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTankRow(Tank tank, bool isLast) {
    final groupColor = _colorForGroup(tank.siteName ?? '');

    return InkWell(
      onTap: () => _showAddDialog(tank),
      borderRadius: BorderRadius.only(
        bottomLeft: isLast ? Radius.circular(16) : Radius.zero,
        bottomRight: isLast ? Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade100),
          ),
          borderRadius: isLast
              ? const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
              : BorderRadius.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tank.tankNumber,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          tank.siteName ?? '—',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.memory_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Device: ${tank.deviceId ?? '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.water_drop_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Product: ${tank.productName ?? '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          tank.fullAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Delete button only
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showDeleteDialog(tank),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Small chevron indicator
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog([Tank? tank]) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: AddTankModal(
                    tank: tank,
                    onSuccess: () {
                      ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(Tank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Tank',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to delete tank "${tank.tankNumber}"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }
}