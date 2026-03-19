import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/widgets/add_roaster_modal.dart';
import 'package:air_water/features/roaster/presentation/widgets/manage_parameters_modal.dart';

class RoasterNarrow extends ConsumerStatefulWidget {
  const RoasterNarrow({super.key});

  @override
  ConsumerState<RoasterNarrow> createState() => _RoasterNarrowState();
}

class _RoasterNarrowState extends ConsumerState<RoasterNarrow> {
  void _showAddModal([Roaster? roaster]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: AddRoasterModal(initialRoaster: roaster),
      ),
    );
  }

  void _showManageParameters(Roaster roaster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ManageParametersModal(roaster: roaster),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Roasters', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(roasterNotifierProvider.notifier).loadRoasters(isReload: true),
            icon: const Icon(Icons.refresh, color: Color(0xFF141E7A)),
          ),
        ],
      ),
      body: state.isLoading && state.roasters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.roasters.length,
              itemBuilder: (context, index) => _buildRoasterCard(state.roasters[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(),
        backgroundColor: const Color(0xFF141E7A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRoasterCard(Roaster roaster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(roaster.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                _buildStatusBadge(roaster.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('SN: ${roaster.serialNumber ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            const Divider(height: 24),
            _buildInfoRow(Icons.business, roaster.companyName ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.factory_outlined, roaster.plantName ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.storage_outlined, 'Tank: ${roaster.tankNumber ?? '-'}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddModal(roaster),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showManageParameters(roaster),
                    icon: const Icon(Icons.settings_input_component, size: 18, color: Colors.white),
                    label: const Text('Params'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141E7A), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 1 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 1 ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: status == 1 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)))),
      ],
    );
  }
}