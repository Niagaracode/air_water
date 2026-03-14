import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/group_provider.dart';

class PlantGroupDetailView extends ConsumerWidget {
  final int plantId;

  const PlantGroupDetailView({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(plantGroupDetailsProvider(plantId));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'PLANT ACCESS DETAILS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        shape: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      body: detailsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF141E7A)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading details:\n$error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
        data: (data) {
          final plant = data.plant;
          final tanks = data.tanks;
          final users = data.users;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Plant Info Card
              _buildSectionHeader('Plant Information', Icons.factory_outlined),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Plant Name', plant.name, isBold: true),
                    if (plant.location != null &&
                        plant.location!.isNotEmpty) ...[
                      const Divider(height: 24, color: Color(0xFFE5E7EB)),
                      _buildDetailRow('Plant Location', plant.location!),
                    ],

                    if (plant.companyDetails != null &&
                        plant.companyDetails!.isNotEmpty) ...[
                      const Divider(height: 24, color: Color(0xFFE5E7EB)),
                      _buildDetailRow('Company', plant.companyDetails!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tanks & Devices
              _buildSectionHeader('Tanks & Devices', Icons.storage_outlined),
              const SizedBox(height: 12),
              if (tanks.isEmpty)
                _buildEmptyState('No tanks assigned to this plant.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tanks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = tanks[index];
                    return _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141E7A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.tankNumber,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (t.product != null)
                                Text(
                                  t.product!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                    fontSize: 14,
                                  ),
                                ),
                              const Spacer(),
                              if (t.tankType != null)
                                Text(
                                  t.tankType!,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          if (t.devices.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Associated Devices',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF374151),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...t.devices.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.memory_outlined,
                                            size: 16,
                                            color: Color(0xFF6B7280),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            d.deviceIdentifier,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF111827),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            d.macAddress,
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF6B7280),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Assigned Users
              _buildSectionHeader(
                'Assigned Users & Roles',
                Icons.group_outlined,
              ),
              const SizedBox(height: 12),
              if (users.isEmpty)
                _buildEmptyState('No users assigned to this plant.')
              else
                _buildCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      // Find which tanks they have access to
                      String accessDesc = '';
                      if (u.hasAllTanks) {
                        accessDesc = 'All Tanks Access';
                      } else {
                        final assignedTankNumbers = u.tankIds
                            .map(
                              (tid) => tanks
                                  .where((t) => t.id == tid)
                                  .firstOrNull
                                  ?.tankNumber,
                            )
                            .where((n) => n != null)
                            .join(', ');
                        accessDesc =
                            'Tanks: ${assignedTankNumbers.isEmpty ? 'None matched' : assignedTankNumbers}';
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(
                                u.username.isNotEmpty
                                    ? u.username[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        u.username,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      if (u.roleName != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Text(
                                            u.roleName!,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.security,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Via Group: ',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      Text(
                                        u.groupName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        u.hasAllTanks
                                            ? Icons.domain_verification
                                            : Icons.rule,
                                        size: 14,
                                        color: u.hasAllTanks
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          accessDesc,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: u.hasAllTanks
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFD97706),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4B5563)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
