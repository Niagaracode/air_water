import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/app_table.dart';
import '../controller/event_provider.dart';
import '../model/event_model.dart';
import '../../../../core/app_theme/app_theme.dart';

class EventWide extends ConsumerStatefulWidget {
  const EventWide({super.key});

  @override
  ConsumerState<EventWide> createState() => _EventWideState();
}

class _EventWideState extends ConsumerState<EventWide> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(eventProvider.notifier).loadLogs(refresh: true));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: _buildHeader(state)),
          ),
          if (state.logs.isEmpty && !state.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppTableEmptyState(
                icon: Icons.event_note_rounded,
                title: 'No events found',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _buildTableHeader()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildEventRow(state.logs[index], index + 1),
                  childCount: state.logs.length,
                ),
              ),
            ),
          ],
          if (state.isLoading)
            const SliverToBoxAdapter(child: AppTableLoadingMore()),
          const SliverToBoxAdapter(child: AppTableBottomCap()),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader(EventState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EVENT LOGS',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track system activities and user actions in real-time.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => ref.read(eventProvider.notifier).loadLogs(refresh: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'REFRESH',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 60),
          AppTableHeaderCell('Time', flex: 2),
          AppTableHeaderCell('User', flex: 2),
          AppTableHeaderCell('Action', flex: 2),
          AppTableHeaderCell('Module', flex: 2),
          AppTableHeaderCell('Details', flex: 4),
        ],
      ),
    );
  }

  Widget _buildEventRow(EventLog log, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          AppTableCell(
            DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt),
            flex: 2,
            fontSize: 13,
          ),
          AppTableCell(log.fullName, flex: 2, bold: true, fontSize: 13),
          AppTableCell(log.action, flex: 2, fontSize: 13),
          AppTableCell(log.module, flex: 2, fontSize: 13),
          AppTableCell(log.details ?? '-', flex: 4, fontSize: 12, color: const Color(0xFF6B7280)),
        ],
      ),
    );
  }
}
