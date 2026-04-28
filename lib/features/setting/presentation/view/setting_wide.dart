import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../../../../shared/widgets/app_table.dart';
import '../controller/setting_provider.dart';
import '../model/setting_model.dart';
import '../widgets/add_setting_modal.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../../core/user_config/user_role.dart';

class SettingWide extends ConsumerStatefulWidget {
  final String? title;
  final String? subTitle;
  const SettingWide({super.key, this.title, this.subTitle});

  @override
  ConsumerState<SettingWide> createState() => _SettingWideState();
}

class _SettingWideState extends ConsumerState<SettingWide> {
  final _scrollController = ScrollController();
  final _settingSearchController = TextEditingController();

  Color _getStatusLabelColor(String? statusLabel) {
    if (statusLabel == null) return const Color(0xFF6B7280);
    final val = statusLabel.trim().toLowerCase();
    if (val.contains('critical')) return const Color(0xFFDC2626);
    if (val.contains('reorder')) return const Color(0xFFD97706);
    if (val.contains('low')) return const Color(0xFFD97706);
    if (val.contains('high')) return const Color(0xFF2563EB);
    return const Color(0xFF6B7280);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(settingProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _settingSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingProvider);
    final notifier = ref.read(settingProvider.notifier);

    final roleAsync = ref.watch(userRoleProvider);
    final isCustomer = roleAsync.when(
      data: (role) => role == UserRole.customer,
      loading: () => true,
      error: (_, __) => true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHeader(state, notifier, isCustomer),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 1200
                    ? constraints.maxWidth
                    : 1200.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        if (state.groupedSettings.isNotEmpty ||
                            !state.isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildFixedTableHeader(isCustomer),
                          ),
                        Expanded(
                          child:
                              state.isLoading && state.groupedSettings.isEmpty
                              ? const AppTableInitialLoader()
                              : _buildVirtualizedTable(
                                  state,
                                  notifier,
                                  isCustomer,
                                ),
                        ),
                        if (state.isLoading && state.groupedSettings.isNotEmpty)
                          const AppTableLoadingMore(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(
    SettingState state,
    SettingNotifier notifier,
    bool isCustomer,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ??
                        (isCustomer ? 'SETTING MANAGEMENT' : 'RULE MANAGEMENT'),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subTitle ??
                        (isCustomer
                            ? 'Centralize device configuration, threshold management, and status monitoring.'
                            : 'Define and manage alarm conditions and automated notification rules.'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (!isCustomer)
                ElevatedButton.icon(
                  onPressed: () => _showAddModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141E7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'ADD RULE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildFilterRow(state, notifier, isCustomer),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.totalEntries} entries',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    SettingState state,
    SettingNotifier notifier,
    bool isCustomer,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RawAutocomplete<SettingAutocompleteInfo>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty)
                return const Iterable<SettingAutocompleteInfo>.empty();
              return await notifier.searchSettings(textEditingValue.text);
            },
            displayStringForOption: (option) => option.name,
            onSelected: (selection) {
              _settingSearchController.text = selection.name;
              notifier.setSearchName(selection.name);
              notifier.loadSettings(isReload: true);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  if (_settingSearchController.text != controller.text &&
                      _settingSearchController.text.isNotEmpty &&
                      controller.text.isEmpty) {
                    controller.text = _settingSearchController.text;
                  }
                  return AppTextField(
                    controller: controller,
                    focusNode: focusNode,
                    hint: isCustomer
                        ? 'Search By Setting Name'
                        : 'Search By Rule Name',
                    onSubmitted: (value) {
                      _settingSearchController.text = value;
                      notifier.setSearchName(value);
                      notifier.loadSettings(isReload: true);
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
                    width: 400,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            option.siteName ?? '—',
                            style: GoogleFonts.inter(fontSize: 12),
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
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<int>(
            value: state.selectedSiteId,
            items: ref
                .watch(siteNotifierProvider.select((s) => s.groupedSites))
                .where(
                  (e) =>
                      e.addresses.isNotEmpty &&
                      e.addresses.first.siteId != null,
                )
                .map((e) => e.addresses.first.siteId!)
                .toList(),
            hint: 'Site',
            itemLabel: (v) {
              final sites = ref.read(siteNotifierProvider).groupedSites;
              try {
                final group = sites.firstWhere(
                  (p) => p.addresses.any((a) => a.siteId == v),
                );
                return group.name;
              } catch (_) {
                return 'Unassigned';
              }
            },
            onChanged: (v) => notifier.setSiteId(v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<int>(
            value: state.selectedStatus,
            items: const [1, 0],
            hint: 'Status',
            itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
            onChanged: (v) => notifier.setSelectedStatus(v),
          ),
        ),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _settingSearchController.clear();
            notifier.clearFilters();
          },
        ),
      ],
    );
  }

  void _showAddModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddSetting',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const AddSettingModal(),
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

  Widget _buildFixedTableHeader(bool isCustomer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        border: Border(
          top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const AppTableHeaderCell('SI.NO', width: 60),
          if (isCustomer) ...[
            const AppTableHeaderCell('Tank Number', flex: 2),
            const AppTableHeaderCell('Device ID', flex: 2),
            const AppTableHeaderCell('Parameter', flex: 2),
            const AppTableHeaderCell('Condition', flex: 2),
          ] else ...[
            const AppTableHeaderCell('Rule Name', flex: 3),
            const AppTableHeaderCell('Site', width: 100),
            const AppTableHeaderCell('Tank', width: 100),
            const AppTableHeaderCell('Parameter', flex: 2),
            const AppTableHeaderCell('Condition', flex: 2),
            const SizedBox(width: 16),
            const AppTableHeaderCell('Status', width: 110),
          ],
          const SizedBox(width: 16),
          const AppTableHeaderCell('Action', width: 80),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(
    SettingState state,
    SettingNotifier notifier,
    bool isCustomer,
  ) {
    if (state.groupedSettings.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: AppTableEmptyState(
          icon: Icons.settings_suggest_outlined,
          title: 'No devices found',
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: state.groupedSettings.length,
      itemBuilder: (context, index) {
        final group = state.groupedSettings[index];
        return _buildGroupSection(index, group, notifier, isCustomer);
      },
    );
  }

  Widget _buildGroupSection(
    int groupIndex,
    SettingGroup group,
    SettingNotifier notifier,
    bool isCustomer,
  ) {
    final companyName = group.settings.isNotEmpty
        ? group.settings.first.companyName
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            border: Border(
              left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${groupIndex + 1}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCustomer)
                    Text(
                      (companyName ?? '—').toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    group.siteName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: isCustomer ? 13 : 11,
                      fontWeight: isCustomer
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isCustomer
                          ? const Color(0xFF111827)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildSettingCountBadge(group, isCustomer),
            ],
          ),
        ),
        for (final s in group.settings)
          _buildSettingRow(s, notifier, isCustomer),
      ],
    );
  }

  Widget _buildSettingCountBadge(SettingGroup group, bool isCustomer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${group.settings.length} ${group.settings.length == 1 ? (isCustomer ? 'Setting' : 'Rule') : (isCustomer ? 'Settings' : 'Rules')}',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF141E7A),
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    Setting setting,
    SettingNotifier notifier,
    bool isCustomer,
  ) {
    String conditionText = '—';
    final paramType = setting.parameterType?.toUpperCase().trim() ?? '';

    // Join all non-null thresholds with commas as the default display
    final activeThresholds = setting.thresholds
        .where((t) => t != null && t != 0)
        .map(
          (t) => t!.toString().replaceAll(RegExp(r'\.0$'), ''),
        ) // Remove trailing .0
        .toList();

    if (activeThresholds.isNotEmpty) {
      if (setting.conditionType == 'BETWEEN' && activeThresholds.length >= 2) {
        conditionText = '${activeThresholds[0]} - ${activeThresholds[1]}';
      } else if (paramType == 'CAL TANK' ||
          paramType == 'CAL KILO LITER' ||
          paramType == 'MFACTOR' ||
          paramType == 'M FACTOR' ||
          paramType == 'SENSOR' ||
          paramType == 'SENSOR RATING' ||
          paramType == 'DATA INTERVAL' ||
          paramType == 'SOLAR' ||
          paramType == 'CHART DATA') {
        conditionText = activeThresholds.join(', ');
      } else {
        conditionText = (setting.conditionType != null)
            ? '${setting.conditionType} ${activeThresholds.join(", ")}'
            : activeThresholds.join(', ');
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppTableCell('', width: 60), // Match SI.NO width
          if (isCustomer) ...[
            AppTableCell(setting.tankNumber ?? '—', flex: 2, bold: true),
            AppTableCell(setting.deviceId ?? '—', flex: 2),
            AppTableCell(setting.parameterType?.toUpperCase() ?? '—', flex: 2),
            AppTableCell(
              null,
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conditionText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  if (setting.statusLabel != null &&
                      setting.statusLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        setting.statusLabel!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusLabelColor(setting.statusLabel),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            AppTableCell(setting.name, flex: 3, bold: true),
            AppTableCell(setting.siteName ?? '—', width: 100),
            AppTableCell(setting.tankNumber ?? '—', width: 100),
            AppTableCell(setting.parameterType?.toUpperCase() ?? '—', flex: 2),
            AppTableCell(
              null,
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conditionText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  if (setting.statusLabel != null &&
                      setting.statusLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        setting.statusLabel!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusLabelColor(setting.statusLabel),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),
            AppTableCell(
              null,
              width: 110,
              child: AppStatusBadge(status: setting.isActive),
            ),
          ],
          const SizedBox(width: 16),
          AppTableCell(
            null,
            width: 80,
            child: Row(
              children: [
                AppTableActionButton(
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => _showEditModal(context, setting),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, Setting setting) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EditSetting',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          AddSettingModal(initialSetting: setting),
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
}
