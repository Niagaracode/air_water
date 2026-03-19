import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/widgets/add_roaster_modal.dart';
import 'package:air_water/features/roaster/presentation/widgets/manage_parameters_modal.dart';

class RoasterWide extends ConsumerStatefulWidget {
  const RoasterWide({super.key});

  @override
  ConsumerState<RoasterWide> createState() => _RoasterWideState();
}

class _RoasterWideState extends ConsumerState<RoasterWide> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddModal([Roaster? roaster]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => AddRoasterModal(initialRoaster: roaster),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _showManageParameters(Roaster roaster) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => ManageParametersModal(roaster: roaster),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(state.roasters),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ROASTER MANAGEMENT', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF141E7A))),
              Text('Manage machine hardware and assign parameter permissions.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddModal(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('CREATE ROASTER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141E7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref.read(roasterNotifierProvider.notifier).setSearchName(v),
              decoration: InputDecoration(
                hintText: 'Search by machine name or serial...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Placeholder for more filters like Plant Autocomplete if needed
        ],
      ),
    );
  }

  Widget _buildTable(List<Roaster> roasters) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: roasters.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) => _buildTableRow(roasters[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderText('MACHINE NAME')),
          Expanded(flex: 2, child: _buildHeaderText('SERIAL/MODEL')),
          Expanded(flex: 2, child: _buildHeaderText('COMPANY / PLANT')),
          Expanded(flex: 1, child: _buildHeaderText('TANK')),
          Expanded(flex: 1, child: _buildHeaderText('STATUS')),
          const SizedBox(width: 200, child: Center(child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.2)))),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(text, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1.2));
  }

  Widget _buildTableRow(Roaster roaster) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(roaster.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roaster.serialNumber ?? 'N/A', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
                if (roaster.model != null) Text(roaster.model!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roaster.companyName ?? '-', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
                if (roaster.plantName != null) Text(roaster.plantName!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(roaster.tankNumber ?? '-', style: GoogleFonts.inter(fontSize: 13))),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roaster.status == 1 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roaster.status == 1 ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: roaster.status == 1 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIcon(Icons.edit_outlined, 'Edit', () => _showAddModal(roaster)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.settings_input_component, 'Params', () => _showManageParameters(roaster)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.delete_outline, 'Delete', () async {
                  final confirmed = await _showDeleteConfirm();
                  if (confirmed) ref.read(roasterNotifierProvider.notifier).deleteRoaster(roaster.id);
                }, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (color ?? const Color(0xFF141E7A)).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: color ?? const Color(0xFF141E7A)),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Roaster?'),
            content: const Text('This will remove the machine machine and all its parameter assignments.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE')),
            ],
          ),
        ) ??
        false;
  }
}