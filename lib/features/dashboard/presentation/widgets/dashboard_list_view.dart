import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/tank_data_model.dart';
import '../model/site_group_model.dart';

class DashboardListView extends StatelessWidget {
  const DashboardListView({
    super.key,
    required this.groupedTanks,
    required this.filteredTanks,
    this.selectedRegion = 'All Regions',
    this.selectedStatus = 'All Status',
    this.searchQuery = '',
    this.onTankTap,
    this.onSiteTap,
    this.onMenuTap,
    this.emptyStateTitle = 'No devices found',
    this.emptyStateSubtitle = 'Try adjusting your filters',
    this.showHeader = true,
    this.tableHeaderHeight = 12,
    this.rowHeight = 60,
  });

  final List<SiteGroupModel> groupedTanks;
  final List<TankDataModel> filteredTanks;
  final String selectedRegion;
  final String selectedStatus;
  final String searchQuery;
  final Function(TankDataModel)? onTankTap;
  final Function(SiteGroupModel)? onSiteTap;
  final Function(TankDataModel, String)? onMenuTap;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final bool showHeader;
  final double tableHeaderHeight;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _getFilteredGroups();

    if (filteredGroups.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (showHeader) _buildTableHeader(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final site = filteredGroups[index];
              return _buildSiteGroup(site);
            },
          ),
        ],
      ),
    );
  }

  List<SiteGroupModel> _getFilteredGroups() {
    return groupedTanks.map((group) {
      final filteredTanks = group.tanks.where((tank) {
        // Region filter
        if (selectedRegion != 'All Regions' && tank.region != selectedRegion) {
          return false;
        }

        // Status filter
        if (selectedStatus != 'All Status' && tank.status != selectedStatus) {
          return false;
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          return tank.tankName.toLowerCase().contains(searchLower) ||
              tank.siteName.toLowerCase().contains(searchLower) ||
              tank.deviceId.toLowerCase().contains(searchLower);
        }

        return true;
      }).toList();

      return SiteGroupModel(
        siteName: group.siteName,
        siteLocation: group.siteLocation,
        tanks: filteredTanks,
      );
    }).where((group) => group.tanks.isNotEmpty).toList();
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
              emptyStateTitle,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyStateSubtitle,
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141E7A).withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text('SITE-TANK NAME', style: _headerStyle())),
          SizedBox(width: 200, child: Text('DEVICE ID', style: _headerStyle())),
          Expanded(child: Text('LEVEL', style: _headerStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('PRESSURE', style: _headerStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('BATTERY', style: _headerStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('SOLAR', style: _headerStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 130, child: Text('STATUS', style: _headerStyle(), textAlign: TextAlign.center)),
          SizedBox(width: 150, child: Text('LAST UPDATE', style: _headerStyle(), textAlign: TextAlign.center)),
          const SizedBox(width: 45),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 1,
    );
  }

  Widget _buildSiteGroup(SiteGroupModel site) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Site Header
        GestureDetector(
          onTap: () => onSiteTap?.call(site),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Color(0xFF141E7A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    site.siteName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E7A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${site.tanks.length} tanks',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF141E7A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tanks
        ...site.tanks.map((tank) => _buildTankRow(tank)),
      ],
    );
  }

  Widget _buildTankRow(TankDataModel tank) {
    return GestureDetector(
      onTap: () => onTankTap?.call(tank),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  tank.tankName,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  Icon(Icons.opacity, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    tank.deviceId,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${tank.level.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _getLevelColor(tank.level),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tank.level / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: _getLevelColor(tank.level),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Center(
                child: Text(
                  '${tank.pressure.toStringAsFixed(1)} bar',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getBatSolColor(tank.batteryV),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Center(
                child: Text(
                  '${tank.batteryV.toStringAsFixed(1)} v',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getBatSolColor(tank.batteryV),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  '${tank.solarV.toStringAsFixed(1)} v',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getBatSolColor(tank.solarV),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(tank.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(tank.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tank.status,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(tank.status),
                        ),
                      ),
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
            SizedBox(
              width: 45,
              child: PopupMenuButton(
                onSelected: (value) => onMenuTap?.call(tank, value.toString()),
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'alerts', child: Text('Set Alerts')),
                  const PopupMenuItem(value: 'history', child: Text('View History')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBatSolColor(double level) {
    if (level <= 3) return Colors.red;
    if (level <= 7) return Colors.orange;
    return Colors.green;
  }

  Color _getLevelColor(double level) {
    if (level <= 20) return Colors.red;
    if (level <= 40) return Colors.orange;
    return Colors.green;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      case 'out of order':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}