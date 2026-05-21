import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/view/roster_edit_view.dart';

class RoasterNarrow extends ConsumerWidget {
  const RoasterNarrow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roasterNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Roster',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFBBF24)),
            onPressed: () => ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true),
          ),
        ],
      ),
      body: state.isLoading && state.rosters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rosters.length,
              itemBuilder: (context, index) {
                final roster = state.rosters[index];
                return _buildRosterCard(context, ref, roster);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add Roster logic
        },
        backgroundColor: const Color(0xFFFBBF24),
        child: const Icon(Icons.add, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, WidgetRef ref, Roster roster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RosterEditView(rosterId: roster.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      roster.description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  _buildStatusChip(roster.enabled == 1),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    onPressed: () => _deleteRoster(context, ref, roster),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   _buildInfoItem('Active Contacts', roster.activeContacts.toString()),
                   const SizedBox(width: 24),
                   _buildInfoItem('Data Channels', roster.dataChannels.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRoster(BuildContext context, WidgetRef ref, Roster roster) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Roster', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${roster.description}"?', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(roasterNotifierProvider.notifier).deleteRoaster(roster.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roster deleted successfully')),
        );
      }
    }
  }

  Widget _buildStatusChip(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        enabled ? 'Enabled' : 'Disabled',
        style: TextStyle(
          fontSize: 12,
          color: enabled ? const Color(0xFF166534) : const Color(0xFF991B1B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}