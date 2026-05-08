import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_table.dart';
import '../controller/company_provider.dart';
import '../widgets/add_company_modal.dart';
import '../model/company_model.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_clear_button.dart';

class CompanyWide extends ConsumerStatefulWidget {
  const CompanyWide({super.key});

  @override
  ConsumerState<CompanyWide> createState() => _CompanyWideState();
}

class _CompanyWideState extends ConsumerState<CompanyWide> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(companyNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyNotifierProvider);
    final companyNotifier = ref.read(companyNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHeader(companyState, companyNotifier),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            if (!companyState.isLoading || companyState.groupedCompanies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: _buildFixedTableHeader(),
                              ),
                            Expanded(
                              child: CustomScrollView(
                                controller: _scrollController,
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    sliver: _buildVirtualizedTable(
                                      companyState,
                                      companyNotifier,
                                    ),
                                  ),
                                  if (companyState.isLoading &&
                                      companyState.groupedCompanies.isNotEmpty)
                                    const SliverToBoxAdapter(child: AppTableLoadingMore()),
                                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (companyState.isProcessing)
            const AppLoader(message: 'Processing...'),
        ],
      ),
    );
  }

  Widget _buildHeader(CompanyState state, CompanyNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPANY MANAGEMENT',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Centralize company information including identification, locations, and status management.',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        _buildFilterRow(notifier, state),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFilterRow(CompanyNotifier notifier, CompanyState state) {
    return Row(
      children: [
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'AddCompany',
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) => const AddCompanyModal(),
              transitionBuilder: (context, anim1, anim2, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                      ),
                  child: child,
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'ADD COMPANY',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        border: Border(
          top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 70),
          AppTableHeaderCell('Company', flex: 2),
          AppTableHeaderCell('City', flex: 2),
          AppTableHeaderCell('State', flex: 2),
          AppTableHeaderCell('Country', flex: 2),
          AppTableHeaderCell('Status', flex: 2),
          AppTableHeaderCell('Address', flex: 4),
          AppTableHeaderCell('Actions', width: 80),

        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(CompanyState state, CompanyNotifier notifier) {
    if (state.groupedCompanies.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: AppTableEmptyState(
          icon: Icons.business_outlined,
          title: 'No companies found',
        ),
      );
    }

    // Flatten all addresses from all groups
    final List<({CompanyGroup group, CompanyAddress addr})> flatItems = [];
    for (var group in state.groupedCompanies) {
      for (var addr in group.addresses) {
        flatItems.add((group: group, addr: addr));
      }
    }

    return SliverList.builder(
      itemCount: flatItems.length,
      itemBuilder: (context, index) {
        final item = flatItems[index];
        final isLast = index == flatItems.length - 1;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              bottom: isLast
                  ? const BorderSide(color: Color(0xFFD1D5DB), width: 1.5)
                  : const BorderSide(color: Color(0xFFF3F4F6), width: 1),
            ),
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )
                : BorderRadius.zero,
          ),
          child: _buildFlatRow(
            index: index,
            group: item.group,
            addr: item.addr,
            isLast: isLast,
          ),
        );
      },
    );
  }

  Widget _buildFlatRow({
    required int index,
    required CompanyGroup group,
    required CompanyAddress addr,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
          AppTableCell(
            group.name,
            flex: 2,
            bold: true,
            color: const Color(0xFF1E40AF),
          ),

          AppTableCell(addr.city ?? '—', flex: 2),
          AppTableCell(addr.state ?? '—', flex: 2),
          AppTableCell(addr.country ?? '—', flex: 2),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(status: addr.status),
            ),
          ),
          AppTableCell(addr.fullAddress, flex: 4),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                AppTableActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => _showEditModal(group, addr),
                ),
                const SizedBox(width: 8),
                AppTableActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  onTap: () => _confirmDelete(addr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showEditModal(CompanyGroup group, CompanyAddress addr) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EditCompany',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          AddCompanyModal(companyGroup: group, initialAddress: addr),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  void _confirmDelete(CompanyAddress addr) {
    if (addr.companyId == null) return;

    final notifier = ref.read(companyNotifierProvider.notifier);
    final companyId = addr.companyId!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this company record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await notifier.deleteCompany(companyId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Company deleted successfully')),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
