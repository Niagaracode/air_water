import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/event_provider.dart';
import '../model/event_model.dart';

class EventNarrow extends ConsumerStatefulWidget {
  const EventNarrow({super.key});

  @override
  ConsumerState<EventNarrow> createState() => _EventNarrowState();
}

class _EventNarrowState extends ConsumerState<EventNarrow> {
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
  Widget build(BuildContext context) {
    final state = ref.watch(eventProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Event Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF141E7A),
        actions: [
          IconButton(
            onPressed: () => ref.read(eventProvider.notifier).loadLogs(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.logs.isEmpty && !state.isLoading
          ? _buildEmptyState()
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.logs.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                return _buildEventCard(state.logs[index]);
              },
            ),
    );
  }

  Widget _buildEventCard(EventLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log.action,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF141E7A)),
                ),
                Text(
                  DateFormat('HH:mm').format(log.createdAt),
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'User: ${log.fullName}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              'Module: ${log.module}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
            ),
            if (log.details != null) ...[
              const SizedBox(height: 8),
              Text(
                log.details!,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note_rounded, size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No events found', style: GoogleFonts.outfit(color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
