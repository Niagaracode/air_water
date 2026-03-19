import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/company/presentation/model/company_model.dart';
import 'package:air_water/features/company/presentation/controller/company_provider.dart';
import 'package:air_water/features/plant/presentation/model/plant_model.dart';
import 'package:air_water/features/plant/presentation/controller/plant_provider.dart';
import 'package:air_water/features/tank/presentation/model/tank_model.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_loader.dart';

class AddRoasterModal extends ConsumerStatefulWidget {
  final Roaster? initialRoaster;
  const AddRoasterModal({super.key, this.initialRoaster});

  @override
  ConsumerState<AddRoasterModal> createState() => _AddRoasterModalState();
}

class _AddRoasterModalState extends ConsumerState<AddRoasterModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();

  CompanyGroup? _selectedCompany;
  Plant? _selectedPlant;
  Tank? _selectedTank;
  int _status = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoaster != null) {
      _nameController.text = widget.initialRoaster!.name;
      _serialController.text = widget.initialRoaster!.serialNumber ?? '';
      _modelController.text = widget.initialRoaster!.model ?? '';
      _capacityController.text = widget.initialRoaster!.capacity?.toString() ?? '';
      _status = widget.initialRoaster!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Company')));
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'serial_number': _serialController.text.trim(),
      'model': _modelController.text.trim(),
      'capacity': double.tryParse(_capacityController.text.trim()),
      'company_id': _selectedCompany!.addresses.first.companyId,
      'plant_id': _selectedPlant?.id,
      'tank_id': _selectedTank?.tankId,
      'status': _status,
    };

    final success = widget.initialRoaster != null
        ? await ref.read(roasterNotifierProvider.notifier).updateRoaster(widget.initialRoaster!.id, data)
        : await ref.read(roasterNotifierProvider.notifier).createRoaster(data);

    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);
    final companies = ref.watch(companyNotifierProvider).groupedCompanies;
    final plants = ref.watch(plantNotifierProvider).plants;
    final groupedTanks = ref.watch(tankProvider).groupedTanks;
    final allTanks = groupedTanks.expand((g) => g.tanks).toList();

    List<Plant> filteredPlants = _selectedCompany == null 
        ? [] 
        : plants.where((p) => _selectedCompany!.addresses.any((a) => a.companyId == p.companyId)).toList();
    
    List<Tank> filteredTanks = _selectedPlant == null
        ? []
        : allTanks.where((t) => t.plantId == _selectedPlant!.id).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
        child: SizedBox(
          width: 600,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('BASIC INFORMATION'),
                            const SizedBox(height: 24),
                            _buildLabelField('ROASTER NAME', AppTextField(controller: _nameController, hint: 'e.g. Batch Master 5000')),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildLabelField('MODEL', AppTextField(controller: _modelController, hint: 'e.g. Ghibli R-15'))),
                                const SizedBox(width: 24),
                                Expanded(child: _buildLabelField('SERIAL NUMBER', AppTextField(controller: _serialController, hint: 'e.g. SN-9981'))),
                              ],
                            ),
                            const SizedBox(height: 48),
                            _buildSectionTitle('ASSET MAPPING'),
                            const SizedBox(height: 24),
                            _buildLabelField('COMPANY', AppDropdown<CompanyGroup>(
                              value: _selectedCompany,
                              items: companies,
                              itemLabel: (cg) => cg.name,
                              hint: 'Select Company',
                              onChanged: (cg) => setState(() {
                                _selectedCompany = cg;
                                _selectedPlant = null;
                                _selectedTank = null;
                              }),
                            )),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildLabelField('PLANT', AppDropdown<Plant>(
                                  value: _selectedPlant,
                                  items: filteredPlants,
                                  itemLabel: (p) => p.name,
                                  hint: 'Select Plant',
                                  onChanged: (p) => setState(() {
                                    _selectedPlant = p;
                                    _selectedTank = null;
                                  }),
                                ))),
                                const SizedBox(width: 24),
                                Expanded(child: _buildLabelField('TANK', AppDropdown<Tank>(
                                  value: _selectedTank,
                                  items: filteredTanks,
                                  itemLabel: (t) => t.tankNumber,
                                  hint: 'Select Tank',
                                  onChanged: (t) => setState(() => _selectedTank = t),
                                ))),
                              ],
                            ),
                            const SizedBox(height: 48),
                            _buildStatusSection(),
                          ],
                        ),
                      ),
                    ),
                    if (state.isProcessing) const AppLoader(message: 'Saving Roaster...'),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialRoaster == null ? 'Create Roaster' : 'Edit Roaster', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
              Text('Map machine hardware to plant assets.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF141E7A), letterSpacing: 1.2));
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECORD STATUS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('Active roasters are visible to users.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(value: _status == 1, onChanged: (v) => setState(() => _status = v ? 1 : 0), activeThumbColor: const Color(0xFF141E7A)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141E7A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: Text(widget.initialRoaster == null ? 'CREATE MACHINE' : 'UPDATE MACHINE'),
          ),
        ],
      ),
    );
  }
}
