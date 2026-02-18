import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../controller/company_provider.dart';
import '../widgets/add_company_modal.dart';
import '../model/company_model.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_loader.dart';

class CompanyNarrow extends ConsumerStatefulWidget {
  const CompanyNarrow({super.key});

  @override
  ConsumerState<CompanyNarrow> createState() => _CompanyNarrowState();
}

class _CompanyNarrowState extends ConsumerState<CompanyNarrow> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyNotifierProvider);
    final companyNotifier = ref.read(companyNotifierProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPANY MANAGEMENT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RawAutocomplete<CompanyAutocompleteInfo>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<CompanyAutocompleteInfo>.empty();
                    }
                    return await companyNotifier.searchCompanies(
                      textEditingValue.text,
                    );
                  },
                  displayStringForOption: (CompanyAutocompleteInfo option) =>
                      option.name,
                  onSelected: (CompanyAutocompleteInfo selection) {
                    _searchController.text = selection.name;
                    companyNotifier.setSearchName(selection.name);
                    companyNotifier.loadGroupedCompanies();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        if (_searchController.text != controller.text &&
                            _searchController.text.isNotEmpty &&
                            controller.text.isEmpty) {
                          controller.text = _searchController.text;
                        }

                        return AppTextField(
                          controller: controller,
                          focusNode: focusNode,
                          hint: 'Search By Name',
                          onSubmitted: (value) {
                            _searchController.text = value;
                            companyNotifier.setSearchName(value);
                            companyNotifier.loadGroupedCompanies();
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 24,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: option.organizationCode != null
                                    ? Text(
                                        option.organizationCode!,
                                        style: const TextStyle(fontSize: 11),
                                      )
                                    : null,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<int>(
                        value: companyState.selectedStatus,
                        items: const [1, 0],
                        hint: 'Status',
                        itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
                        onChanged: (v) => companyNotifier.setStatus(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDatePickerField(
                        selectedDate: companyState.selectedDate != null
                            ? DateTime.parse(companyState.selectedDate!)
                            : null,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            final formatted =
                                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                            companyNotifier.setDate(formatted);
                          } else {
                            companyNotifier.setDate(null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'AddCompany',
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) =>
                          const AddCompanyModal(),
                      transitionBuilder: (context, anim1, anim2, child) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim1,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: child,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('ADD'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Showing  ${companyState.totalEntries} entries',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGroupedTable(companyState, companyNotifier),
                if (companyState.hasMore &&
                    companyState.groupedCompanies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: companyState.isLoading
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: () => companyNotifier.loadMore(),
                              child: const Text('Load More'),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          if (companyState.isProcessing)
            const AppLoader(message: 'Processing...'),
        ],
      ),
    );
  }

  Widget _buildGroupedTable(
    CompanyState companyState,
    CompanyNotifier notifier,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'SI.NO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'City',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table body
                if (companyState.groupedCompanies.isEmpty &&
                    !companyState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'No record found',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  ...List.generate(companyState.groupedCompanies.length, (
                    index,
                  ) {
                    final group = companyState.groupedCompanies[index];
                    final isExpanded = companyState.expandedGroups.contains(
                      group.name,
                    );

                    return _buildGroupSection(
                      index: index,
                      group: group,
                      isExpanded: isExpanded,
                      notifier: notifier,
                    );
                  }),
                if (companyState.isLoading &&
                    companyState.groupedCompanies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        if (companyState.isLoading && companyState.groupedCompanies.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupSection({
    required int index,
    required CompanyGroup group,
    required bool isExpanded,
    required CompanyNotifier notifier,
  }) {
    return Column(
      children: [
        if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
        // Group header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Address rows
        if (isExpanded)
          ...group.addresses.map((addr) {
            return Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.city,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${addr.state}, ${addr.country}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 16,
                              ),
                              onPressed: () => _showEditModal(group, addr),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 16,
                              ),
                              onPressed: () => _confirmDelete(addr),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
      ],
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
