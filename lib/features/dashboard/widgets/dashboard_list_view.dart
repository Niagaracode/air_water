import 'dart:ui';
import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../layout/provider/sidebar_provider.dart';
import '../../../core/helpers/app_colors_helper.dart';
import '../../../core/user_config/user_role.dart';
import '../data/models/site_group_model.dart';
import '../data/models/tank_data_model.dart';
import '../extensions/tank_filter_extension.dart';
import 'animated_pressure_gauge.dart';
import 'animated_tank_level.dart';


class DashboardListView extends ConsumerStatefulWidget {
  const DashboardListView({
    super.key,
    required this.groupedTanks,
    required this.filteredTanks,
    this.selectedRegion = 'All Regions',
    this.selectedStatus = 'All Status',
    this.selectedProduct = 'All Product',
    this.searchQuery = '',
    this.onTankTap,
    this.onSiteTap,
    this.emptyStateTitle = 'No devices found',
    this.emptyStateSubtitle = 'Try adjusting your filters',
    this.showHeader = true,
    this.userRole = UserRole.customer,
    this.isNarrow = false,
  });

  final List<SiteGroupModel> groupedTanks;
  final List<TankDataModel> filteredTanks;
  final String selectedRegion;
  final String selectedStatus;
  final String selectedProduct;
  final String searchQuery;
  final Function(TankDataModel)? onTankTap;
  final Function(SiteGroupModel)? onSiteTap;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final bool showHeader;
  final UserRole userRole;
  // When true, this list is rendered inside the narrow (phone) layout where
  // tapping a tank pushes a new screen rather than just "selecting" it.
  // Used to tweak visuals (chevron affordance, no persistent selection tint).
  final bool isNarrow;

  @override
  ConsumerState<DashboardListView> createState() => _DashboardListViewState();
}

class _DashboardListViewState extends ConsumerState<DashboardListView> {
  TankDataModel? _selectedTank;
  final TextEditingController _searchController = TextEditingController();
  String _localSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.filteredTanks.isNotEmpty) {
      _selectedTank = widget.filteredTanks.first;
    }
  }

  @override
  void didUpdateWidget(covariant DashboardListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredTanks != oldWidget.filteredTanks) {
      if (_selectedTank != null && !widget.filteredTanks.contains(_selectedTank)) {
        _selectedTank = widget.filteredTanks.isNotEmpty ? widget.filteredTanks.first : null;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Updated to use the extension
  List<SiteGroupModel> _getFilteredGroups() {
    final searchTerm = _localSearchQuery.isNotEmpty ? _localSearchQuery : widget.searchQuery;

    return widget.groupedTanks.applyFilters(
      selectedRegion: widget.selectedRegion,
      selectedStatus: widget.selectedStatus,
      selectedProduct: widget.selectedProduct,
      searchQuery: searchTerm,
    );
  }

  // Updated to use the extension
  int _getTotalTanksCount() {
    final searchTerm = _localSearchQuery.isNotEmpty ? _localSearchQuery : widget.searchQuery;

    return widget.groupedTanks.getTotalTanksCount(
      selectedRegion: widget.selectedRegion,
      selectedStatus: widget.selectedStatus,
      selectedProduct: widget.selectedProduct,
      searchQuery: searchTerm,
    );
  }

  // In DashboardListView's build method, simplify for customer view:
  @override
  Widget build(BuildContext context) {

    final filteredGroups = _getFilteredGroups();
    final totalTanks = _getTotalTanksCount();
    final isSplitView = totalTanks >= 1; // Show left panel when 1 or more tanks
    final mediaWidth = MediaQuery.of(context).size.width;
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final screenWidth = isExpanded ? mediaWidth - 300 : mediaWidth - 120;

    if (filteredGroups.isEmpty) {
      return _buildEmptyState();
    }

    // Admin View: Always show full list view (no split)
    if (widget.userRole == UserRole.superAdmin) {
      if(widget.isNarrow){
        return _buildOtherTankListPanel(filteredGroups);
      }
      return _buildAdminListView(filteredGroups, screenWidth);
    }

    // Customer View: Show split view when 1+ tanks
    if (!isSplitView) {
      // This case shouldn't happen with >=1, but kept for safety
      return SizedBox();
      return _buildCustomerFullView(filteredGroups, screenWidth);
    }

    // Customer View with 1+ tanks: Split view with left panel
    return _buildCustomerTankListPanel(filteredGroups);
  }

  // Add this new method
  Widget _buildOtherTankListPanel(List<SiteGroupModel> groups) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 350,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          for (final site in groups) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _SiteHeaderDelegate(
                site: site,
                onTap: widget.onSiteTap == null ? null : () => widget.onSiteTap!(site),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              sliver: SliverList.builder(
                itemCount: site.tanks.length,
                itemBuilder: (context, index) => _buildCustomerTankListItem(site.tanks[index]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }

// Add this new method
  Widget _buildCustomerTankListPanel(List<SiteGroupModel> groups) {
    return Column(
      children: [
        widget.isNarrow ? SizedBox(height: 0) : SizedBox(height: 5),
        _buildCustomerHeader(),
        // Scrollable tank list with sticky site headers - much better for
        // browsing many sites/tanks on a phone, and lazily builds rows.
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              for (final site in groups) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SiteHeaderDelegate(
                    site: site,
                    onTap: widget.onSiteTap == null ? null : () => widget.onSiteTap!(site),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  sliver: SliverList.builder(
                    itemCount: site.tanks.length,
                    itemBuilder: (context, index) => _buildCustomerTankListItem(site.tanks[index]),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerHeader() {
    final total = _getTotalTanksCount();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.propane_tank_outlined, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                'My Tanks',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (total > 5) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _localSearchQuery = value;
                });
              },
              style: GoogleFonts.outfit(fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'Search devices...',
                hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                suffixIcon: _localSearchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      _localSearchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                isDense: true,
                // Taller, thumb-friendly tap target on phones.
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ==================== ADMIN VIEW ====================
  Widget _buildAdminListView(List<SiteGroupModel> groups, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1200),
            child: SizedBox(
              width: screenWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showHeader) _buildAdminTableHeader(),
                  ...groups.map((site) => _buildAdminSiteGroup(site)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('SITE / TANK ID', style: _adminHeaderStyle())),
          SizedBox(width: 200, child: Text('DEVICE ID', style: _adminHeaderStyle())),
          Expanded(child: Text('LEVEL', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('PRESSURE', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('BATTERY', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('SOLAR', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('STATUS', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 160, child: Text('READING TIME', style: _adminHeaderStyle(), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildAdminSiteGroup(SiteGroupModel site) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onSiteTap?.call(site),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: primary.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  '${site.siteName} - ${site.city}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${site.tanks.length} tanks',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...site.tanks.map((tank) => _buildAdminTankRow(tank)),
      ],
    );
  }

  Widget _buildAdminTankRow(TankDataModel tank) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTankTap?.call(tank),
        hoverColor: Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColorsHelper.getGasTypeColor(tank.gasType),
                      child: Text(
                        tank.gasType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      tank.tankName,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Text(tank.deviceId, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${tank.level.toStringAsFixed(1)}%', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColorsHelper.getLevelColor(tank.level))),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: tank.level / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColorsHelper.getLevelColor(tank.level),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: tank.pressure.toStringAsFixed(1), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                        TextSpan(text: ' Bar', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Center(
                  child: Text(
                    tank.isBatteryEnabled ? '${tank.batteryV.toStringAsFixed(1)} v' : '--',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: tank.isBatteryEnabled ?
                    AppColorsHelper.getBatSolColor(tank.batteryV) : Colors.grey),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    tank.isSolarEnabled ? '${tank.solarV.toStringAsFixed(1)} v' : '--',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: tank.isSolarEnabled ?
                    AppColorsHelper.getBatSolColor(tank.solarV) : Colors.grey),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorsHelper.getStatusColor(tank.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColorsHelper.getStatusColor(tank.status), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(tank.status, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColorsHelper.getStatusColor(tank.status))),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Center(
                  child: Text(
                    _formatDateTime(tank.lastUpdate),
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CUSTOMER VIEW (MOBILE-OPTIMIZED) ====================

  Widget _buildCustomerTankListItem(TankDataModel tank) {
    final isSelected = !widget.isNarrow && _selectedTank?.deviceId == tank.deviceId;
    final levelColor = AppColorsHelper.getLevelColor(tank.level);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primary.withValues(alpha: 0.25) : Colors.grey.shade200,
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedTank = tank;
            });
            widget.onTankTap?.call(tank);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TOP ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColorsHelper.getGasTypeColor(tank.gasType),
                      child: Text(
                        tank.gasType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tank.tankName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tank.deviceId,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColorsHelper.getStatusColor(tank.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColorsHelper.getStatusColor(tank.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tank.status,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColorsHelper.getStatusColor(tank.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isNarrow) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                /// LEVEL (animated liquid-fill tank) + PRESSURE (animated gauge)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedTankLevel(
                            level: tank.level,
                            color: levelColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${tank.level.toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: levelColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Level',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedPressureGauge(
                            percentage: getMaxPressure(tank.thresholds, tank.pressure),
                            valueLabel: '${tank.pressure.toStringAsFixed(0)} bar',
                            color: AppColorsHelper.getBatSolColor(tank.pressure),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Pressure',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Divider(color: Colors.grey.shade200, height: 1),

                const SizedBox(height: 10),

                /// BOTTOM METRICS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildBottomMetric(
                        'Battery',
                        tank.isBatteryEnabled ? '${tank.batteryV.toStringAsFixed(1)} v' : '--',
                        Icons.battery_std,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildBottomMetric(
                        'Solar',
                        tank.isSolarEnabled ? '${tank.solarV.toStringAsFixed(1)} v' : '--',
                        Icons.solar_power,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildBottomMetric(
                        'Last Reading',
                        _formatDateTime(tank.lastUpdate),
                        Icons.access_time,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double getMaxPressure(String thresholds, double cVal) {
    final parts = thresholds.split('_');
    if (parts.length >= 4) {
      double maxPressure = double.tryParse(parts[3]) ?? 20.0;
      double percentage = (cVal / maxPressure) * 100;
      return percentage;
    }
    return 20.0;
  }

  Widget _buildBottomMetric(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerFullView(List<SiteGroupModel> groups, double screenWidth) {
    // Fallback for when no split view (shouldn't happen with >=1)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Select a device',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.emptyStateTitle,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptyStateSubtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time = DateFormat('hh:mm a').format(dateTime);

    if (messageDate == today) return 'Today at $time';
    if (messageDate == yesterday) return 'Yesterday at $time';
    return DateFormat('dd MMM yyyy \'at\' hh:mm a').format(dateTime);
  }

  TextStyle _adminHeaderStyle() {
    return GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.black54,
      letterSpacing: 1,
    );
  }
}

/// Sticky site header used inside the customer's mobile tank list.
/// Keeps the current site name visible while its tanks scroll underneath,
/// so users always know which site they're looking at.
class _SiteHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SiteHeaderDelegate({required this.site, this.onTap});

  final SiteGroupModel site;
  final VoidCallback? onTap;

  static const double _height = 44;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: const Color(0xFFF8FAFC),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: primary.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 15, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  site.siteName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${site.tanks.length}',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SiteHeaderDelegate oldDelegate) {
    return oldDelegate.site != site;
  }
}