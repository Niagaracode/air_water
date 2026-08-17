import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/view_header.dart';
import '../controller/event_provider.dart';
import '../model/event_model.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 1000
                    ? constraints.maxWidth
                    : 1000.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        if (!state.isLoading || state.logs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: _buildFixedTableHeader(),
                          ),
                        Expanded(
                          child: state.isLoading && state.logs.isEmpty
                              ? const AppTableInitialLoader()
                              : _buildVirtualizedTable(state),
                        ),
                        if (state.isLoading && state.logs.isNotEmpty)
                          const AppTableLoadingMore(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'EVENT LOGS',
      subtitle: 'Track system activities and user actions in real-time.',
      buttonText: 'Refresh',
      buttonIcon: Icons.refresh,
      onPressed: () => ref.read(eventProvider.notifier).loadLogs(refresh: true),
    );
  }

  Widget _buildFixedTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 70),
          AppTableHeaderCell('Time', flex: 2),
          AppTableHeaderCell('User', flex: 2),
          AppTableHeaderCell('Action', flex: 2),
          AppTableHeaderCell('Module', flex: 2),
          AppTableHeaderCell('Details', flex: 4),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(EventState state) {
    if (state.logs.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: AppTableEmptyState(
          icon: Icons.event_note_rounded,
          title: 'No event logs found',
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: state.logs.length,
      itemBuilder: (context, index) {
        final isLast = index == state.logs.length - 1;
        return _buildEventRow(state.logs[index], index + 1, isLast);
      },
    );
  }

  Widget _buildEventRow(EventLog log, int index, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: isLast
              ? BorderSide(color: Colors.grey.shade300, width: 1)
              : const BorderSide(color: Color(0xFFF3F4F6)),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            AppTableCell(
              DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt),
              flex: 2,
              fontSize: 13,
            ),
            AppTableCell(
              log.fullName,
              flex: 2,
              bold: true,
              fontSize: 13,
            ),
            AppTableCell(
              log.action,
              flex: 2,
              fontSize: 13,
            ),
            AppTableCell(
              log.module,
              flex: 2,
              fontSize: 13,
            ),
            AppTableCell(
              log.details ?? '-',
              flex: 4,
              fontSize: 12,
              color: const Color(0xFF4B5563),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
