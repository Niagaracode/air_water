import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tank_model.dart';
import '../../../site/presentation/model/site_model.dart';
import '../controller/tank_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
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
  final _tonnesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _siteAutocompleteController = TextEditingController();

  SiteAutocompleteInfo? _selectedSite;
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
      final tank = widget.initialTank!;
      _tankNumberController.text = tank.tankNumber;
      _tonnesController.text = tank.tonnes?.toString() ?? '';
      _descriptionController.text = tank.description ?? '';
      _siteAutocompleteController.text = tank.siteName ?? '';
      _status = tank.status;

      // Dynamic mapping of dimensions based on tank type
      final typeName = tank.tankTypeName ?? '';
      switch (typeName) {
        case 'Cyclinder':
          _heightController.text = tank.height?.toString() ?? '';
          _widthController.text = tank.width?.toString() ?? '';
          _dishHeightController.text = tank.dishHeight?.toString() ?? '';
          break;
        case 'Rectangle':
        case 'Rectangular':
          _heightController.text = tank.height?.toString() ?? '';
          _widthController.text = tank.width?.toString() ?? '';
          _dishHeightController.text = tank.depth?.toString() ?? '';
          break;
        case 'Horizontal with 2:1 Ellipsoidal Ends':
        case 'Horizontal with Hemispherical Ends':
        case 'None':
        case 'Spherical':
        case 'Vertical with 2:1 Ellipsoidal Ends':
        case 'Vertical with Flat Ends':
        case 'Vertical with Hemispherical Ends':
          _heightController.text = tank.canLength?.toString() ?? '';
          _widthController.text = tank.diameter?.toString() ?? '';
          break;
        case 'Horizontal with Flat Ends':
          _heightController.text = tank.length?.toString() ?? '';
          _widthController.text = tank.diameter?.toString() ?? '';
          break;
        case 'Horizontal with Variable Dished Ends':
        case 'Vertical with Variable Dished Ends':
          _heightController.text = tank.canLength?.toString() ?? '';
          _widthController.text = tank.diameter?.toString() ?? '';
          _dishHeightController.text = tank.dishDepth?.toString() ?? '';
          break;
        case 'Vertical with Conical Bottom End':
          _heightController.text = tank.canLength?.toString() ?? '';
          _widthController.text = tank.diameter?.toString() ?? '';
          _dishHeightController.text = tank.coneLength?.toString() ?? '';
          break;
        default:
          _heightController.text = tank.height?.toString() ?? '';
          _widthController.text = tank.width?.toString() ?? '';
          _dishHeightController.text = tank.dishHeight?.toString() ?? '';
      }
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

    if (_selectedSite == null && widget.initialTank?.siteId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Site')),
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
      height: null,
      width: null,
      dishHeight: null,
      canLength: null,
      diameter: null,
      length: null,
      dishDepth: null,
      depth: null,
      coneLength: null,
      tonnes: 0.0,
      description: '',
      siteId: _selectedSite?.siteId ?? widget.initialTank?.siteId,
      addressId: _selectedSite?.addressId ?? widget.initialTank?.addressId,
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
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 48,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.initialTank != null
                                          ? 'Edit Tank Instance'
                                          : 'Create New Tank',
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.initialTank != null
                                          ? 'Modify the existing tank configuration and properties.'
                                          : 'Fill in the information below to register a new tank unit.',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded, size: 22),
                                color: const Color(0xFF6B7280),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  padding: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildInfoBar(),
                          const SizedBox(height: 48),
                          _buildLabelField(
                            'TANK NAME',
                            _buildTankAutocomplete(),
                          ),
                          const SizedBox(height: 32),
                          _buildLabelField('SITE', _buildSiteAutocomplete()),
                          const SizedBox(height: 32),
                          _buildLabelField(
                            'ASSIGNED PRODUCT',
                            _isLoadingDropdowns
                                ? const LinearProgressIndicator(
                                    minHeight: 2,
                                  )
                                : AppDropdown<dynamic>(
                                    value: _selectedProduct,
                                    items: _products,
                                    itemLabel: (p) => p is TankProduct
                                        ? p.productName
                                        : p['product_name'],
                                    hint: 'Select Product',
                                    onChanged: (v) => setState(
                                      () => _selectedProduct = v,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 32),
                          // Status toggle - redesigned
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF3F4F6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STATUS',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: const Color(0xFF141E7A),
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Set the visibility of this tank record.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _buildStatusToggle(
                                  1,
                                  'Active',
                                  const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 12),
                                _buildStatusToggle(
                                  0,
                                  'Inactive',
                                  const Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 64),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF141E7A),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(
                                  0xFF141E7A,
                                ).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                widget.initialTank != null
                                    ? 'UPDATE TANK RECORD'
                                    : 'CREATE TANK RECORD',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tankState.isProcessing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black26,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF141E7A), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter The Tank Name And Basic Details To Create A New Tank.',
              style: TextStyle(color: Color(0xFF141E7A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 35,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
          color: _isDragging ? const Color(0xFF141E7A) : Colors.grey.shade300,
          strokeWidth: 2,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _isDragging
                  ? const Color(0xFF141E7A).withValues(alpha: 0.05)
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
                        color: _isDragging
                            ? const Color(0xFF141E7A)
                            : Colors.grey.shade300,
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

  Widget _buildStatusToggle(int value, String label, Color activeColor) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFD1D5DB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ],
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

  Widget _buildSiteAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<SiteAutocompleteInfo>(
          textEditingController: _siteAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty)
              return const Iterable<SiteAutocompleteInfo>.empty();
            return await ref
                .read(tankProvider.notifier)
                .searchSites(textEditingValue.text);
          },
          displayStringForOption: (SiteAutocompleteInfo option) =>
              option.displayName ?? option.siteName,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Site by Name',
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
                              option.siteName + " " + option.fullAddress,
                        ),
                          onTap: () {
                            onSelected(option);
                            setState(() {
                              _selectedSite = option;
                            });
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

  List<String> _getDimensionFields(String? typeName) {
    if (typeName == null) return ['HEIGHT', 'WIDTH'];

    switch (typeName) {
      case 'Cyclinder':
        return ['HEIGHT', 'WIDTH', 'DISH HEIGHT'];
      case 'Rectangle':
      case 'Rectangular':
        return ['HEIGHT', 'WIDTH'];
      case 'Horizontal with 2:1 Ellipsoidal Ends':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Horizontal with Flat Ends':
        return ['Length (L)', 'Diameter (D)'];
      case 'Horizontal with Hemispherical Ends':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Horizontal with Variable Dished Ends':
        return ['Can Length (L)', 'Diameter (D)', 'Dish Depth (DL)'];
      case 'None':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Spherical':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Vertical with 2:1 Ellipsoidal Ends':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Vertical with Conical Bottom End':
        return ['Can Length (L)', 'Diameter (D)', 'Cone Length (CL)'];
      case 'Vertical with Flat Ends':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Vertical with Hemispherical Ends':
        return ['Can Length (L)', 'Diameter (D)'];
      case 'Vertical with Variable Dished Ends':
        return ['Can Length (L)', 'Diameter (D)', 'Dish Depth (DL)'];
      default:
        return ['HEIGHT', 'WIDTH', 'DISH HEIGHT'];
    }
  }

  @override
  void dispose() {
    _tankNumberController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _dishHeightController.dispose();
    _descriptionController.dispose();
    _siteAutocompleteController.dispose();
    super.dispose();
  }
}
