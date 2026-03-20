import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/widgets/roster_user_editor.dart';

class RosterEditView extends ConsumerStatefulWidget {
  final int rosterId;
  const RosterEditView({super.key, required this.rosterId});

  @override
  ConsumerState<RosterEditView> createState() => _RosterEditViewState();
}

class _RosterEditViewState extends ConsumerState<RosterEditView> {
  Roster? _roster;
  List<RosterMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _roster = await ref.read(roasterNotifierProvider.notifier).getRosterDetail(widget.rosterId);
    _members = await ref.read(roasterNotifierProvider.notifier).getRosterMembers(widget.rosterId);
    setState(() => _isLoading = false);
  }

  void _showUserEditor([RosterMember? member]) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: RosterUserEditor(rosterId: widget.rosterId, member: member),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_roster == null) return const Scaffold(body: Center(child: Text('Roster not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Roster',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildSummaryHeader(),
            const SizedBox(height: 32),
            _buildItemCount(_members.length),
            _buildMembersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildSummaryCard(
            label: 'DESCRIPTION',
            child: Text(
              _roster!.description,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            label: 'STATUS',
            child: Row(
              children: [
                Switch(
                  value: _roster!.enabled == 1,
                  onChanged: (v) {},
                  activeTrackColor: const Color(0xFF141E7A),
                  activeColor: Colors.white,
                ),
                Expanded(
                  child: Text(
                    _roster!.enabled == 1 ? 'Enabled' : 'Disabled',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _roster!.enabled == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'DATA CHANNELS',
            icon: Icons.sensors_rounded,
            child: Text(
              _roster!.dataChannels.toString(),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141E7A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'ACTIVE CONTACTS',
            icon: Icons.people_alt_rounded,
            child: Text(
              _roster!.activeContacts.toString(),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141E7A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String label, required Widget child, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }


  Widget _buildItemCount(int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '$total items',
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildMembersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1200,
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) => _buildTableRow(_members[index]),
                  ),
                ],
              ),
            ),
          ),
          _buildAddContactButton(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderText('CONTACT PERSON')),
          Expanded(flex: 2, child: _buildHeaderText('COMPANY')),
          Expanded(flex: 2, child: _buildHeaderText('ENABLED')),
          Expanded(flex: 2, child: _buildHeaderText('NOTIFICATION')),
          Expanded(flex: 2, child: _buildHeaderText('E2P')),
          Expanded(flex: 3, child: _buildHeaderText('MESSAGE TEMPLATE')),
          const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTableRow(RosterMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.firstName} ${member.lastName}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                Text(
                  member.username ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              member.companyName ?? '',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildStatusBadge(member.enabled == 1, 'Active', 'Inactive'),
          ),
          Expanded(
            flex: 2,
            child: _buildStatusBadge(member.emailNotif == 1, 'Email On', 'Email Off'),
          ),
          Expanded(
            flex: 2,
            child: _buildStatusBadge(member.emailToPhone == 1, 'E2P On', 'E2P Off'),
          ),
          Expanded(
            flex: 3,
            child: Text(
              member.messageTemplateName ?? '-',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),
          SizedBox(
            width: 80,
            child: IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF141E7A), size: 22),
              onPressed: () => _showUserEditor(member),
              tooltip: 'Edit Member',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, String activeText, String inactiveText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? activeText : inactiveText,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton.icon(
        onPressed: () => _showUserEditor(),
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Add New Contact'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF141E7A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
