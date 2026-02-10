import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controllers/sidebar_provider.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final primaryColor = primary;

    return Container(
      width: isExpanded ? 260 : 80,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isExpanded ? 16 : 8,
            ),
            child: isExpanded
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/png/app_logo.png',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref.read(sidebarExpandedProvider.notifier).toggle(),
                        icon: Icon(
                          Icons.double_arrow_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/png/app_logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        onPressed: () =>
                            ref.read(sidebarExpandedProvider.notifier).toggle(),
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
          ),

          const Divider(height: 1),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSectionHeader('MAIN MENU', isExpanded),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  isSelected: true,
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('CONFIGURATION', isExpanded),
                _SidebarItem(
                  icon: Icons.local_florist_rounded,
                  label: 'Plant',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.storage_rounded,
                  label: 'Tank',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.settings_input_component_rounded,
                  label: 'Device',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Product',
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('USER', isExpanded),
                _SidebarItem(
                  icon: Icons.person_rounded,
                  label: 'User',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.groups_rounded,
                  label: 'Group',
                  isExpanded: isExpanded,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('EVENTS', isExpanded),
                _SidebarItem(
                  icon: Icons.gavel_rounded,
                  label: 'Rule',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.forum_rounded,
                  label: 'Message Format',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Roaster',
                  isExpanded: isExpanded,
                ),
                _SidebarItem(
                  icon: Icons.assessment_rounded,
                  label: 'Report',
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),

          // // Bottom Logout
          // const Divider(height: 1),
          // _SidebarItem(
          //   icon: Icons.power_settings_new_rounded,
          //   label: 'Logout',
          //   isExpanded: isExpanded,
          //   onTap: () {
          //     // Handle logout
          //   },
          // ),
          //const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExpanded) {
    if (!isExpanded) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.isExpanded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //final primaryColor = primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isExpanded ? 16 : 0,
          ),
          decoration: BoxDecoration(
            // color: isSelected
            //     ? primaryColor.withOpacity(0.1)
            //     : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                //color: isSelected ? primaryColor : Colors.grey[600],
                size: 24,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    // color: isSelected ? primaryColor : Colors.grey[800],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
