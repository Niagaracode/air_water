import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
import '../controller/company_provider.dart';
import '../widgets/add_company_modal.dart';
import '../model/company_model.dart';

class CompanyWide extends ConsumerStatefulWidget {
  const CompanyWide({super.key});

  @override
  ConsumerState<CompanyWide> createState() => _CompanyWideState();
}

class _CompanyWideState extends ConsumerState<CompanyWide> {

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyNotifierProvider);
    final companyNotifier = ref.read(companyNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: companyState.isLoading ? Center(
        child: CircularProgressIndicator(),
      ) : SizedBox(
        child: Column(
          children: [
            _buildHeader(companyState, companyNotifier),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTableBody(companyState, companyNotifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CompanyState state, CompanyNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                    style: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
                  ),
                ],
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(CompanyState state,  CompanyNotifier notifier) {

    if (state.groupedCompanies.isEmpty && !state.isLoading) {
      return const AppTableEmptyState(icon: Icons.business_outlined, title: 'No companies found');
    }

    final List<({CompanyGroup group, CompanyAddress addr})> flatItems = [];
    for (var group in state.groupedCompanies) {
      for (var address in group.addresses) {
        flatItems.add((group: group, addr: address));
      }
    }

    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: (flatItems.length * 50) + 50,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        dataRowHeight: 50,
        headingRowHeight: 45,
        headingRowColor: WidgetStateProperty.all(primary.withValues(alpha: 0.1)),
        dividerThickness: 0.4,
        columns: [
          DataColumn2(
            label: Center(child: TableHeaderCell(label: 'SI.NO')),
            fixedWidth: 60,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Company'),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'City'),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'State'),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Country'),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Status'),
            fixedWidth: 100,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Address'),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Center(child: TableHeaderCell(label: 'Actions')),
            fixedWidth: 80,
          ),
        ],
        rows: List<DataRow>.generate(flatItems.length, (index) {

          final item = flatItems[index];

          return DataRow(
            cells: [
              DataCell(Center(child: TableDataCell(label: '${index + 1}'))),
              DataCell(TableDataCell(label: item.group.name, bold: true,)),
              DataCell(TableDataCell(label: item.addr.city ?? '—')),
              DataCell(TableDataCell(label: item.addr.state ?? '—')),
              DataCell(TableDataCell(label: item.addr.country ?? '—')),
              DataCell(AppStatusBadge(status: item.addr.status)),
              DataCell(TableDataCell(label: item.addr.fullAddress, maxLines: 2)),
              DataCell(SizedBox(
                width: 80,
                child: Row(
                  children: [
                    AppTableActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF2563EB),
                      bg: const Color(0xFFEFF6FF),
                      onTap: () => _showEditModal(item.group, item.addr),
                    ),
                    const SizedBox(width: 8),
                    AppTableActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEF2F2),
                      onTap: () => _confirmDelete(item.addr),
                    ),
                  ],
                ),
              )),
            ],
          );
        }),
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
