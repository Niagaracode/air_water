import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/message_template_provider.dart';
import '../../../../core/app_theme/app_theme.dart';

class MessageTemplateForm extends ConsumerStatefulWidget {
  final MessageTemplate? initialTemplate;
  final bool isNarrow;

  const MessageTemplateForm({
    super.key,
    this.initialTemplate,
    required this.isNarrow,
  });

  @override
  ConsumerState<MessageTemplateForm> createState() =>
      _MessageTemplateFormState();
}

class _MessageTemplateFormState extends ConsumerState<MessageTemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  int _isActive = 1;
  String _selectedDateFormat = 'dd:mm:yyyy';
  String _selectedTimeFormat = 'hh:mm';
  String _selectedTimeZoneType = 'Tank location time zone';

  // Dynamic data from API
  List<String> _dateFormats = [];
  List<String> _subjectPlaceholders = [];
  List<String> _timeFormats = [];
  List<String> _timeZoneTypes = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplateConfig();
    if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _nameController.text = t.name;
      _descriptionController.text = t.description ?? '';
      _subjectController.text = t.subject ?? '';
      _bodyController.text = t.body;
      _isActive = t.isActive;
      if (t.dateFormat != null) _selectedDateFormat = t.dateFormat!;
      if (t.timeFormat != null) _selectedTimeFormat = t.timeFormat!;
      if (t.timeZoneType != null) _selectedTimeZoneType = t.timeZoneType!;
    }
  }

  Future<void> _loadTemplateConfig() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      final response = await repository.getMessageTemplatePlaceholders();
      debugPrint('Template Config Response: $response');
      final configData = response['data'] ?? response;
      debugPrint('Config Data: $configData');

      setState(() {
        _dateFormats = List<String>.from(configData['Date Format'] ?? []);

        _subjectPlaceholders = List<String>.from(
          configData['Template Content Subject'] ?? [],
        );

        _timeFormats = List<String>.from(configData['Time Format'] ?? []);

        _timeZoneTypes = List<String>.from(configData['Time Zone Type'] ?? []);

        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading template config: $e');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => _isLoading = false);
      _showSnackBar(
        'Failed to load template configuration: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _insertPlaceholder(
    String placeholder,
    TextEditingController controller,
  ) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    String newText;
    int newCursorPos;

    if (cursorPos >= 0 && cursorPos <= text.length) {
      newText =
          text.substring(0, cursorPos) +
          placeholder +
          text.substring(cursorPos);
      newCursorPos = cursorPos + placeholder.length;
    } else {
      newText = text + placeholder;
      newCursorPos = newText.length;
    }

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _showPlaceholderMenu(
    BuildContext buttonContext,
    TextEditingController controller,
  ) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;

    final RenderBox overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;

    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        overlay.size.width - offset.dx,
        overlay.size.height - offset.dy,
      ),
      items: _subjectPlaceholders.map((placeholder) {
        return PopupMenuItem(value: placeholder, child: Text(placeholder));
      }).toList(),
    ).then((value) {
      if (value != null) {
        final formatted = '{${value.replaceAll(' ', '_')}}';
        _insertPlaceholder(formatted, controller);
      }
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter Template Name', isError: true);
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      _showSnackBar('Please enter Template Body', isError: true);
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'subject': _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'date_format': _selectedDateFormat,
      'time_format': _selectedTimeFormat,
      'time_zone_type': _selectedTimeZoneType,
      'is_active': _isActive,
    };

    final notifier = ref.read(messageTemplateProvider.notifier);
    bool success;
    if (widget.initialTemplate != null) {
      success = await notifier.updateTemplate(widget.initialTemplate!.id, data);
    } else {
      success = await notifier.createTemplate(data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      _showSnackBar(
        widget.initialTemplate != null
            ? 'Template updated successfully'
            : 'Template created successfully',
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
        elevation: 24,
        shadowColor: Colors.black26,
        child: SafeArea(
          child: SizedBox(
            width: 780,
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.initialTemplate != null
                                    ? 'Edit Template'
                                    : 'Create New Template',
                                style: GoogleFonts.outfit(
                                  fontSize: widget.isNarrow ? 26 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                maxLines: 2,
                                widget.initialTemplate != null
                                    ? 'Modify your message template settings'
                                    : 'Design professional message templates with dynamic placeholders',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 24),
                            color: const Color(0xFF4B5563),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // TEMPLATE NAME
                    _buildLabelField(
                      'TEMPLATE NAME *',
                      AppTextField(
                        controller: _nameController,
                        hint: 'e.g., Alarm Notification, Welcome Email',
                        prefixIcon: const Icon(
                          Icons.text_fields,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // DESCRIPTION
                    _buildLabelField(
                      'DESCRIPTION',
                      AppTextField(
                        controller: _descriptionController,
                        hint: 'Short description of the template purpose',
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUBJECT FIELD WITH PLACEHOLDER MENU
                    _buildTextFieldWithPlaceholders(
                      label: 'SUBJECT (WITH PLACEHOLDERS)',
                      controller: _subjectController,
                      hint:
                          'e.g., Alert: {site_name} - {customer_name} - {tank_name}',
                      icon: Icons.subject,
                    ),
                    const SizedBox(height: 24),

                    // BODY FIELD WITH PLACEHOLDER MENU
                    _buildTextFieldWithPlaceholders(
                      label: 'BODY CONTENT (HTML SUPPORTED)',
                      controller: _bodyController,
                      hint:
                          'Enter template body with HTML formatting...\n\nExample:\n<h2>{site_name} Alert</h2>\n<p>Dear {customer_name},</p>\n<p>Tank {tank_name} has reached {Tank_display_level} at {last_reading_time}</p>',
                      icon: Icons.code,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 32),

                    // ADVANCED CONFIGURATION SECTION
                    _buildAdvancedConfigSection(),
                    const SizedBox(height: 32),

                    // STATUS CONFIGURATION
                    _buildStatusSection(),
                    const SizedBox(height: 48),

                    // ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B5563),
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.initialTemplate != null
                                  ? 'Update Template'
                                  : 'Create Template',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithPlaceholders({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isNarrow) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF374151),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Click 📎 to insert placeholders',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF374151),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Click 📎 to insert placeholders',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              AppTextField(
                controller: controller,
                hint: hint,
                maxLines: maxLines,
                prefixIcon: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Builder(
                  builder: (buttonContext) {
                    return InkWell(
                      onTap: () =>
                          _showPlaceholderMenu(buttonContext, controller),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.attach_file,
                          size: 18,
                          color: primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedConfigSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.08), primary.withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                'ADVANCED CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 24, color: Color(0xFFE5E7EB)),
        Row(
          children: [
            Expanded(
              child: _buildLabelField(
                'DATE FORMAT',
                _buildModernDropdown<String>(
                  value: _selectedDateFormat,
                  items: _dateFormats,
                  onChanged: (v) => setState(() => _selectedDateFormat = v!),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildLabelField(
                'TIME FORMAT',
                _buildModernDropdown<String>(
                  value: _selectedTimeFormat,
                  items: _timeFormats,
                  onChanged: (v) => setState(() => _selectedTimeFormat = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLabelField(
          'TIME ZONE TYPE',
          _buildModernDropdown<String>(
            value: _selectedTimeZoneType,
            items: _timeZoneTypes,
            onChanged: (v) => setState(() => _selectedTimeZoneType = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
            size: 20,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF111827),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
        icon: const SizedBox.shrink(),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.08), primary.withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.toggle_on, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(
                'STATUS CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 24, color: Color(0xFFE5E7EB)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Status',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable or disable this template for use',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _isActive == 1
                      ? primary.withOpacity(0.1)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Switch(
                  value: _isActive == 1,
                  onChanged: (val) => setState(() => _isActive = val ? 1 : 0),
                  activeColor: primary,
                  inactiveThumbColor: Colors.red.shade300,
                  inactiveTrackColor: Colors.red.shade100,
                  activeTrackColor: primary.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF374151),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
