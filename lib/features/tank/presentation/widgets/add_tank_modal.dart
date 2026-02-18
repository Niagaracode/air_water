import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../controller/tank_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../core/app_theme/app_theme.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AddTankModal extends ConsumerStatefulWidget {
  final Tank? initialTank;
  const AddTankModal({super.key, this.initialTank});

  @override
  ConsumerState<AddTankModal> createState() => _AddTankModalState();
}

class _AddTankModalState extends ConsumerState<AddTankModal> {
  final _tankNumberController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _dishHeightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plantAutocompleteController = TextEditingController();

  PlantAutocompleteInfo? _selectedPlant;
  Map<String, dynamic>? _dropdownData;
  List<TankProduct> _products = [];
  bool _isLoadingDropdowns = false;

  dynamic _selectedUnit;
  dynamic _selectedTankType;
  dynamic _selectedProduct;
  XFile? _imageFile;
  Uint8List? _previewBytes;
  bool _isDragging = false;
  int _status = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialTank != null) {
      _tankNumberController.text = widget.initialTank!.tankNumber;
      _heightController.text = widget.initialTank!.height?.toString() ?? '';
      _widthController.text = widget.initialTank!.width?.toString() ?? '';
      _dishHeightController.text =
          widget.initialTank!.dishHeight?.toString() ?? '';
      _descriptionController.text = widget.initialTank!.description ?? '';
      _plantAutocompleteController.text = widget.initialTank!.plantName ?? '';
      _status = widget.initialTank!.status;
    }
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final results = await Future.wait([
        ref.read(tankProvider.notifier).getDropdowns(),
        ref.read(tankProvider.notifier).getProducts(),
      ]);

      final data = results[0] as Map<String, dynamic>;
      final products = results[1] as List<TankProduct>;

      setState(() {
        _dropdownData = data;
        _products = products;
        if (widget.initialTank != null) {
          _selectedUnit = (data['units'] as List).firstWhere(
            (u) => u['id'] == widget.initialTank!.unitId,
            orElse: () => null,
          );
          _selectedTankType = (data['tank_types'] as List).firstWhere(
            (tt) => tt['id'] == widget.initialTank!.tankTypeId,
            orElse: () => null,
          );
          final foundProducts = products.where(
            (p) => p.productId == widget.initialTank!.productId,
          );
          _selectedProduct = foundProducts.isNotEmpty
              ? foundProducts.first
              : null;
        }
      });
    } catch (e) {
      debugPrint('Error loading dropdowns: $e');
    } finally {
      setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_tankNumberController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter Tank Name')),
      );
      return;
    }

    if (_selectedPlant == null && widget.initialTank?.plantId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Plant')),
      );
      return;
    }

    if (_selectedUnit == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Unit')),
      );
      return;
    }

    if (_selectedTankType == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Tank Type')),
      );
      return;
    }

    if (_selectedProduct == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Product')),
      );
      return;
    }

    final request = TankCreateRequest(
      tankNumber: _tankNumberController.text,
      height: double.tryParse(_heightController.text),
      width: double.tryParse(_widthController.text),
      dishHeight: double.tryParse(_dishHeightController.text),
      description: _descriptionController.text,
      plantId: _selectedPlant?.plantId ?? widget.initialTank?.plantId,
      unitId: _selectedUnit?['id'],
      tankTypeId: _selectedTankType?['id'],
      productId: _selectedProduct is TankProduct
          ? _selectedProduct.productId
          : _selectedProduct?['id'],
      imageFile: _imageFile,
      status: _status,
    );

    final success = widget.initialTank != null
        ? await ref
              .read(tankProvider.notifier)
              .updateTank(widget.initialTank!.tankId, request)
        : await ref.read(tankProvider.notifier).createTank(request);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.initialTank != null ? 'Tank updated' : 'Tank created',
          ),
        ),
      );
    } else {
      final error = ref.read(tankProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Action failed: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tankState = ref.watch(tankProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Stack(
          children: [
            Container(
              width: 600,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ADD TANK',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoBar(),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLabelField(
                            'Tank Name*',
                            _buildTankAutocomplete(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildLabelField(
                            'Unit*',
                            _isLoadingDropdowns
                                ? const LinearProgressIndicator(minHeight: 2)
                                : AppDropdown<dynamic>(
                                    value: _selectedUnit,
                                    items: _dropdownData?['units'] ?? [],
                                    itemLabel: (u) => u['name'],
                                    hint: 'Select Unit',
                                    onChanged: (v) =>
                                        setState(() => _selectedUnit = v),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLabelField('Plant Name*', _buildPlantAutocomplete()),
                    // if (_selectedPlant != null) ...[
                    //   const SizedBox(height: 16),
                    //   Container(
                    //     padding: const EdgeInsets.all(12),
                    //     decoration: BoxDecoration(
                    //       color: Colors.grey.shade50,
                    //       borderRadius: BorderRadius.circular(8),
                    //       border: Border.all(color: Colors.grey.shade200),
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         const Icon(
                    //           Icons.location_on,
                    //           color: Colors.grey,
                    //           size: 16,
                    //         ),
                    //         const SizedBox(width: 8),
                    //         Expanded(
                    //           child: Text(
                    //             '${_selectedPlant!.fullAddress}${_selectedPlant!.pincode != null ? ' - ${_selectedPlant!.pincode}' : ''}',
                    //             style: const TextStyle(
                    //               fontSize: 12,
                    //               color: Colors.grey,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ],
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageUploadArea(),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabelField(
                                      'Height*',
                                      AppTextField(
                                        controller: _heightController,
                                        hint: 'Enter Height',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildLabelField(
                                      'Width*',
                                      AppTextField(
                                        controller: _widthController,
                                        hint: 'Enter Width',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabelField(
                                      'Dish Height*',
                                      AppTextField(
                                        controller: _dishHeightController,
                                        hint: 'Enter Dish Height',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildLabelField(
                                      'Tank Type*',
                                      _isLoadingDropdowns
                                          ? const LinearProgressIndicator(
                                              minHeight: 2,
                                            )
                                          : AppDropdown<dynamic>(
                                              value: _selectedTankType,
                                              items:
                                                  _dropdownData?['tank_types'] ??
                                                  [],
                                              itemLabel: (tt) => tt['name'],
                                              hint: 'Select Tank',
                                              onChanged: (v) => setState(
                                                () => _selectedTankType = v,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildLabelField(
                      'Product*',
                      _isLoadingDropdowns
                          ? const LinearProgressIndicator(minHeight: 2)
                          : AppDropdown<dynamic>(
                              value: _selectedProduct,
                              items: _products,
                              itemLabel: (p) => p is TankProduct
                                  ? p.productName
                                  : p['product_name'],
                              hint: 'Select Product',
                              onChanged: (v) =>
                                  setState(() => _selectedProduct = v),
                            ),
                    ),
                    const SizedBox(height: 32),
                    _buildLabelField(
                      'Description*',
                      AppTextField(
                        controller: _descriptionController,
                        hint: 'Enter Description',
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabelField(
                      'Status*',
                      Row(
                        children: [
                          Row(
                            children: [
                              Radio<int>(
                                value: 1,
                                groupValue: _status,
                                activeColor: const Color(0xFF1B1B4B),
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                              const Text('Active'),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              Radio<int>(
                                value: 0,
                                groupValue: _status,
                                activeColor: const Color(0xFF1B1B4B),
                                onChanged: (v) => setState(() => _status = v!),
                              ),
                              const Text('Inactive'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text(
                            'SAVE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tankState.isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Color(0xFF1B1B4B), size: 20),
          SizedBox(width: 12),
          Text(
            'Enter The Tank Name And Basic Details To Create A New Tank.',
            style: TextStyle(color: Color(0xFF1B1B4B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildImageUploadArea() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickImage,
      child: DropTarget(
        onDragDone: (detail) async {
          if (detail.files.isNotEmpty) {
            final file = detail.files.first;
            final bytes = await file.readAsBytes();
            setState(() {
              _imageFile = file;
              _previewBytes = bytes;
            });
          }
        },
        onDragEntered: (detail) => setState(() => _isDragging = true),
        onDragExited: (detail) => setState(() => _isDragging = false),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          dashPattern: const [6, 3],
          color: _isDragging ? Theme.of(context).colorScheme.surface : Colors.grey.shade300,
          strokeWidth: 2,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _isDragging
                  ? Theme.of(context).colorScheme.surface.withOpacity(0.05)
                  : Colors.grey.shade50,
            ),
            child: _previewBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _previewBytes!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => setState(() {
                            _imageFile = null;
                            _previewBytes = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: _isDragging ? Theme.of(context).colorScheme.surface : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Drag And Drop The Image Or Browse Files',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageFile = image;
        _previewBytes = bytes;
      });
    }
  }

  Widget _buildTankAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _tankNumberController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty)
              return const Iterable<String>.empty();
            return await ref
                .read(tankProvider.notifier)
                .getTankNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Enter Tank Name',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlantAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<PlantAutocompleteInfo>(
          textEditingController: _plantAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty)
              return const Iterable<PlantAutocompleteInfo>.empty();
            return await ref
                .read(tankProvider.notifier)
                .searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
              option.displayName ?? option.plantName,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Plant by Name',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.displayName ??
                              option.plantName + " " + option.fullAddress,
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(() => _selectedPlant = option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tankNumberController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _dishHeightController.dispose();
    _descriptionController.dispose();
    _plantAutocompleteController.dispose();
    super.dispose();
  }
}
