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
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMPANY MANAGEMENT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildFilters(companyNotifier, companyState),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Showing  ${companyState.totalEntries} entries',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                sliver: _buildVirtualizedTable(companyState, companyNotifier),
              ),
              if (companyState.isLoading &&
                  companyState.groupedCompanies.isNotEmpty)
                SliverToBoxAdapter(child: _buildBottomLoader()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
          if (companyState.isProcessing)
            const AppLoader(message: 'Processing...'),
        ],
      ),
    );
  }

  Widget _buildFilters(
    CompanyNotifier companyNotifier,
    CompanyState companyState,
  ) {
    return Column(
      children: [
        RawAutocomplete<CompanyAutocompleteInfo>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<CompanyAutocompleteInfo>.empty();
            }
            return await companyNotifier.searchCompanies(textEditingValue.text);
          },
          displayStringForOption: (CompanyAutocompleteInfo option) =>
              option.name,
          onSelected: (CompanyAutocompleteInfo selection) {
            _searchController.text = selection.name;
            companyNotifier.setSearchName(selection.name);
            companyNotifier.loadGroupedCompanies();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
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
            icon: const Icon(Icons.add, size: 16),
            label: const Text('ADD'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomLoader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Please wait loading new record',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(CompanyState state, CompanyNotifier notifier) {
    if (state.groupedCompanies.isEmpty && !state.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No record found',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.groupedCompanies.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Table header
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'SI.NO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'City',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        final groupIndex = index - 1;
        final group = state.groupedCompanies[groupIndex];
        final isExpanded = state.expandedGroups.contains(group.name);
        final isLast = groupIndex == state.groupedCompanies.length - 1;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
              right: BorderSide(color: Colors.grey.shade200),
              bottom: isLast
                  ? BorderSide(color: Colors.grey.shade200)
                  : BorderSide.none,
            ),
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : BorderRadius.zero,
          ),
          child: _buildGroupSection(
            index: groupIndex,
            group: group,
            isExpanded: isExpanded,
            notifier: notifier,
          ),
        );
      },
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
                              addr.city ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${addr.state ?? ''}, ${addr.country ?? ''}',
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
