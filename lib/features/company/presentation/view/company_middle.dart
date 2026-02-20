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

class CompanyMiddle extends ConsumerStatefulWidget {
  const CompanyMiddle({super.key});

  @override
  ConsumerState<CompanyMiddle> createState() => _CompanyMiddleState();
}

class _CompanyMiddleState extends ConsumerState<CompanyMiddle> {
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
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard >> Company',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      _buildHeader(companyState, companyNotifier),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  Widget _buildHeader(CompanyState state, CompanyNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPANY MANAGEMENT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Centralize Company Information Including Identification, Locations, And Status Management',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildFilters(notifier, state),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing  ${state.totalEntries} entries',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLoader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Please wait loading new record',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(CompanyNotifier notifier, CompanyState state) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 250, // Slightly wider for middle
          child: RawAutocomplete<CompanyAutocompleteInfo>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<CompanyAutocompleteInfo>.empty();
              }
              return await notifier.searchCompanies(textEditingValue.text);
            },
            displayStringForOption: (CompanyAutocompleteInfo option) =>
                option.name,
            onSelected: (CompanyAutocompleteInfo selection) {
              _searchController.text = selection.name;
              notifier.setSearchName(selection.name);
              notifier.loadGroupedCompanies();
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
                      notifier.setSearchName(value);
                      notifier.loadGroupedCompanies();
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
                    width: 350,
                    constraints: const BoxConstraints(maxHeight: 250),
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
        ),
        SizedBox(
          width: 150,
          child: AppDropdown<int>(
            value: state.selectedStatus,
            items: const [1, 0],
            hint: 'Status',
            itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
            onChanged: (v) => notifier.setStatus(v),
          ),
        ),
        SizedBox(
          width: 180,
          child: AppDatePickerField(
            selectedDate: state.selectedDate != null
                ? DateTime.parse(state.selectedDate!)
                : null,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              if (date != null) {
                final formatted =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                notifier.setDate(formatted);
              } else {
                notifier.setDate(null);
              }
            },
          ),
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
          icon: const Icon(Icons.add, size: 16),
          label: const Text('ADD'),
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(CompanyState state, CompanyNotifier notifier) {
    if (state.groupedCompanies.isEmpty && !state.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                _tableHeaderCell('SI.NO', width: 60),
                _tableHeaderCell('City', flex: 2),
                _tableHeaderCell('Date', flex: 2),
                _tableHeaderCell('State', flex: 2),
                _tableHeaderCell('Country', flex: 2),
                _tableHeaderCell('Status', flex: 1),
                _tableHeaderCell('Address', flex: 3),
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

  Widget _tableHeaderCell(String text, {double? width, int? flex}) {
    final child = Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 60,
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 60),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.city ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.createdAt?.split('T').first ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.state ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.country ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: addr.status == 1
                                  ? Colors.green
                                  : Colors.grey,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              addr.status == 1 ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: addr.status == 1
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                addr.fullAddress,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
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
                            const SizedBox(width: 8),
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
