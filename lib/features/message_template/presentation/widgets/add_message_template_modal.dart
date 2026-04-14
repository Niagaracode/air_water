import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/message_template_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/message_template_provider.dart';

class AddMessageTemplateModal extends ConsumerStatefulWidget {
  final MessageTemplate? initialTemplate;

  const AddMessageTemplateModal({super.key, this.initialTemplate});

  @override
  ConsumerState<AddMessageTemplateModal> createState() => _AddMessageTemplateModalState();
}

class _AddMessageTemplateModalState extends ConsumerState<AddMessageTemplateModal> {
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
  Map<String, dynamic> _templateConfig = {};
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
    // Simulate API call - replace with actual API call
    // final response = await apiService.getTemplateConfig();
    // setState(() {
    //   _templateConfig = response['data'];
    //   _dateFormats = List<String>.from(_templateConfig['Date Format'] ?? []);
    //   _subjectPlaceholders = List<String>.from(_templateConfig['Template Content Subject'] ?? []);
    //   _timeFormats = List<String>.from(_templateConfig['Time Format'] ?? []);
    //   _timeZoneTypes = List<String>.from(_templateConfig['Time Zone Type'] ?? []);
    //   _isLoading = false;
    // });

    // Mock data from your API response
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _templateConfig = {
        'Date Format': ['dd:mm:yyyy', 'dd:mm:yy', 'mm:dd:yyyy', 'mm:dd:yy', 'yyyy:mm:dd', 'yy:mm:dd', 'dd:mm', 'mm:dd'],
        'Template Content Subject': [
          'site name',
          'site address',
          'customer name',
          'customer address',
          'city',
          'state',
          'tank name',
          'unit',
          'Tank display level',
          'last reading time',
          'event message',
          'event rule value'
        ],
        'Time Format': ['hh:mm', 'hh:mm:ss'],
        'Time Zone Type': ['Tank location time zone', 'Domain Time Zone']
      };
      _dateFormats = List<String>.from(_templateConfig['Date Format'] ?? []);
      _subjectPlaceholders = List<String>.from(_templateConfig['Template Content Subject'] ?? []);
      _timeFormats = List<String>.from(_templateConfig['Time Format'] ?? []);
      _timeZoneTypes = List<String>.from(_templateConfig['Time Zone Type'] ?? []);
      _isLoading = false;
    });
  }

  void _insertPlaceholder(String placeholder, TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    String newText;
    int newCursorPos;

    if (cursorPos >= 0 && cursorPos <= text.length) {
      newText = text.substring(0, cursorPos) + placeholder + text.substring(cursorPos);
      newCursorPos = cursorPos + placeholder.length;
    } else {
      newText = text + placeholder;
      newCursorPos = newText.length;
    }

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _showPlaceholderMenu(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.data_usage, size: 24, color: Color(0xFF141E7A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insert Placeholder',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Click on any item to insert at cursor position',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _subjectPlaceholders.length,
                itemBuilder: (context, index) {
                  final placeholder = _subjectPlaceholders[index];
                  final formattedPlaceholder = '{${placeholder.replaceAll(' ', '_')}}';
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    child: InkWell(
                      onTap: () {
                        _insertPlaceholder(formattedPlaceholder, controller);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141E7A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconForPlaceholder(placeholder),
                                size: 16,
                                color: const Color(0xFF141E7A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    placeholder,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    formattedPlaceholder,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: const Color(0xFF6B7280),
                                      //fontFamily: 'monospace',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF141E7A)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPlaceholder(String placeholder) {
    if (placeholder.contains('site')) return Icons.location_city;
    if (placeholder.contains('customer')) return Icons.person;
    if (placeholder.contains('tank')) return Icons.water_drop;
    if (placeholder.contains('unit')) return Icons.speed;
    if (placeholder.contains('time')) return Icons.schedule;
    if (placeholder.contains('event')) return Icons.notifications;
    if (placeholder.contains('city')) return Icons.location_on;
    if (placeholder.contains('state')) return Icons.map;
    return Icons.code;
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
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'subject': _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
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
      _showSnackBar(widget.initialTemplate != null ? 'Template updated successfully' : 'Template created successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF141E7A),
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
        child: SizedBox(
          width: 780,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF141E7A), Color(0xFF2A3AA7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
                ),
              ),
              Expanded(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.initialTemplate != null ? 'Edit Template' : 'Create New Template',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
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
                            Container(
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
                            prefixIcon: const Icon(Icons.text_fields, size: 20, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DESCRIPTION
                        _buildLabelField(
                          'DESCRIPTION',
                          AppTextField(
                            controller: _descriptionController,
                            hint: 'Short description of the template purpose',
                            prefixIcon: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF6B7280)),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SUBJECT FIELD WITH PLACEHOLDER MENU
                        _buildTextFieldWithPlaceholders(
                          label: 'SUBJECT (WITH PLACEHOLDERS)',
                          controller: _subjectController,
                          hint: 'e.g., Alert: {site_name} - {customer_name} - {tank_name}',
                          icon: Icons.subject,
                        ),
                        const SizedBox(height: 24),

                        // BODY FIELD WITH PLACEHOLDER MENU
                        _buildTextFieldWithPlaceholders(
                          label: 'BODY CONTENT (HTML SUPPORTED)',
                          controller: _bodyController,
                          hint: 'Enter template body with HTML formatting...\n\nExample:\n<h2>{site_name} Alert</h2>\n<p>Dear {customer_name},</p>\n<p>Tank {tank_name} has reached {Tank_display_level} at {last_reading_time}</p>\n<p>Event: {event_message}</p>',
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
                                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
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
                                  backgroundColor: const Color(0xFF141E7A),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.initialTemplate != null ? 'Update Template' : 'Create Template',
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
            ],
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
    int maxLines = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                color: const Color(0xFF141E7A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Click 📎 to insert placeholders',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF141E7A),
                ),
              ),
            ),
          ],
        ),
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
                prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: InkWell(
                  onTap: () => _showPlaceholderMenu(controller),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Color(0xFF141E7A),
                    ),
                  ),
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
              colors: [const Color(0xFF141E7A).withOpacity(0.08), const Color(0xFF141E7A).withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                'ADVANCED CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141E7A),
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
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
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
              colors: [const Color(0xFF141E7A).withOpacity(0.08), const Color(0xFF141E7A).withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.toggle_on, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                'STATUS CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141E7A),
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
                  color: _isActive == 1 ? const Color(0xFF141E7A).withOpacity(0.1) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Switch(
                  value: _isActive == 1,
                  onChanged: (val) => setState(() => _isActive = val ? 1 : 0),
                  activeColor: const Color(0xFF141E7A),
                  inactiveThumbColor: Colors.red.shade300,
                  inactiveTrackColor: Colors.red.shade100,
                  activeTrackColor: const Color(0xFF141E7A).withOpacity(0.5),
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

/*class AddMessageTemplateModal extends ConsumerStatefulWidget {
  final MessageTemplate? initialTemplate;

  const AddMessageTemplateModal({super.key, this.initialTemplate});

  @override
  ConsumerState<AddMessageTemplateModal> createState() => _AddMessageTemplateModalState();
}

class _AddMessageTemplateModalState extends ConsumerState<AddMessageTemplateModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  int _isActive = 1;
  String _selectedDateFormat = 'DD/MM/YYYY';
  String _selectedTimeFormat = '24h';
  String _selectedTimeZone = 'UTC+05:30 (Chennai)';

  // Available placeholders from your screenshot
  final List<PlaceholderGroup> _placeholderGroups = [
    PlaceholderGroup('General', [
      PlaceholderItem('{current_value}', 'Current Value', Icons.electric_bolt),
      PlaceholderItem('{threshold_value}', 'Threshold Value', Icons.speed),
      PlaceholderItem('{timestamp}', 'Timestamp', Icons.timer),
      PlaceholderItem('{user_name}', 'User Name', Icons.account_circle),
      PlaceholderItem('{plant_name}', 'Plant Name', Icons.factory),
      PlaceholderItem('{device_id}', 'Device ID', Icons.sensors),
    ]),
    PlaceholderGroup('Asset', [
      PlaceholderItem('{Asset.Location.GPS}', 'Asset Location GPS', Icons.gps_fixed),
      PlaceholderItem('{Asset.Notes}', 'Asset Notes', Icons.note_alt),
      PlaceholderItem('{Asset.Title}', 'Asset Title', Icons.title),
    ]),
    PlaceholderGroup('Customer', [
      PlaceholderItem('{Customer.Address}', 'Customer Address', Icons.location_on),
      PlaceholderItem('{Customer.City}', 'Customer City', Icons.location_city),
      PlaceholderItem('{Customer.Name}', 'Customer Name', Icons.person),
      PlaceholderItem('{Customer.State}', 'Customer State', Icons.map),
    ]),
    PlaceholderGroup('Business', [
      PlaceholderItem('{Business Unit}', 'Business Unit', Icons.business),
      PlaceholderItem('{Custom Field3}', 'Custom Field 3', Icons.edit_note),
    ]),
    PlaceholderGroup('Data Channel', [
      PlaceholderItem('{DataChannel.Description}', 'Channel Description', Icons.description),
      PlaceholderItem('{DataChannel.DisplayLevel}', 'Display Level', Icons.visibility),
      PlaceholderItem('{DataChannel.DisplayUnits}', 'Display Units', Icons.ad_units),
      PlaceholderItem('{DataChannel.LastReadingTimestamp}', 'Last Reading Time', Icons.schedule),
      PlaceholderItem('{DataChannel.ScaledMax}', 'Scaled Max', Icons.trending_up),
      PlaceholderItem('{DataChannel.ScaledUnits}', 'Scaled Units', Icons.ad_units),
      PlaceholderItem('{DataChannel.ScaledValue}', 'Scaled Value', Icons.show_chart),
    ]),
    PlaceholderGroup('Event', [
      PlaceholderItem('{Event.CreateTimeStamp}', 'Event Create Time', Icons.event),
      PlaceholderItem('{Event.Description}', 'Event Description', Icons.description),
      PlaceholderItem('{Event.GeoAreaName}', 'Geo Area Name', Icons.map),
      PlaceholderItem('{Event.ImportanceLevel}', 'Importance Level', Icons.priority_high),
    ]),
    PlaceholderGroup('Tank', [
      PlaceholderItem('{tank_name}', 'Tank Name', Icons.water_drop),
      PlaceholderItem('{tank_id}', 'Tank ID', Icons.numbers),
      PlaceholderItem('{tank_capacity}', 'Tank Capacity', Icons.cyclone),
      PlaceholderItem('{tank_level}', 'Tank Level', Icons.water),
    ]),
    PlaceholderGroup('Alarm', [
      PlaceholderItem('{alarm_name}', 'Alarm Name', Icons.notifications_active),
      PlaceholderItem('{alarm_severity}', 'Alarm Severity', Icons.warning),
      PlaceholderItem('{alarm_threshold}', 'Alarm Threshold', Icons.trending_up),
    ])
  ];

  final List<String> _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
  final List<String> _timeFormats = ['12h (AM/PM)', '24h'];

  // Track which field is currently active for placeholder insertion
  TextEditingController? _activeFieldController;

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _nameController.text = t.name;
      _descriptionController.text = t.description ?? '';
      _subjectController.text = t.subject ?? '';
      _bodyController.text = t.body;
      _isActive = t.isActive;
      if (t.dateFormat != null) _selectedDateFormat = t.dateFormat!;
      if (t.timeFormat != null) _selectedTimeFormat = t.timeFormat!;
      if (t.timeZoneFixed != null) _selectedTimeZone = t.timeZoneFixed!;
    }
  }

  void _insertPlaceholder(String placeholder, TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.baseOffset;

    String newText;
    int newCursorPos;

    if (cursorPos >= 0 && cursorPos <= text.length) {
      newText = text.substring(0, cursorPos) + placeholder + text.substring(cursorPos);
      newCursorPos = cursorPos + placeholder.length;
    } else {
      newText = text + placeholder;
      newCursorPos = newText.length;
    }

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _showPlaceholderMenu(TextEditingController controller) {
    setState(() {
      _activeFieldController = controller;
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
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'subject': _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'date_format': _selectedDateFormat,
      'time_format': _selectedTimeFormat == '24h' ? 'H:i' : 'h:i A',
      'time_zone_type': 1,
      'time_zone_fixed': _selectedTimeZone,
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
      _showSnackBar(widget.initialTemplate != null ? 'Template updated successfully' : 'Template created successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF141E7A),
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
        child: SizedBox(
          width: 800,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF141E7A), Color(0xFF2A3AA7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
                ),
              ),
              Expanded(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.initialTemplate != null ? 'Edit Template' : 'Create New Template',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
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
                            Container(
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
                            prefixIcon: const Icon(Icons.text_fields, size: 20, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DESCRIPTION
                        _buildLabelField(
                          'DESCRIPTION',
                          AppTextField(
                            controller: _descriptionController,
                            hint: 'Short description of the template purpose',
                            prefixIcon: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF6B7280)),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SUBJECT FIELD WITH PLACEHOLDER MENU
                        _buildTextFieldWithPlaceholders(
                          label: 'SUBJECT (WITH PLACEHOLDERS)',
                          controller: _subjectController,
                          hint: 'e.g., Alert: {tank_name} - {Customer.Name}',
                          icon: Icons.subject,
                        ),
                        const SizedBox(height: 24),

                        // BODY FIELD WITH PLACEHOLDER MENU
                        _buildTextFieldWithPlaceholders(
                          label: 'BODY CONTENT (HTML SUPPORTED)',
                          controller: _bodyController,
                          hint: 'Enter template body with HTML formatting...\n\nExample:\n<h2>{Asset.Title} Alert</h2>\n<p>Dear {Customer.Name},</p>\n<p>{DataChannel.Description} has reached {DataChannel.ScaledValue} at {timestamp}</p>',
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
                                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
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
                                  backgroundColor: const Color(0xFF141E7A),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.initialTemplate != null ? 'Update Template' : 'Create Template',
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
            ],
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
    int maxLines = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                color: const Color(0xFF141E7A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Click 📎 to insert',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF141E7A),
                ),
              ),
            ),
          ],
        ),
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
                prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: PopupMenuButton<PlaceholderGroup>(
                  offset: const Offset(0, 40),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Color(0xFF141E7A),
                    ),
                  ),
                  onSelected: (PlaceholderGroup group) {
                    _showPlaceholderGroupDialog(group, controller);
                  },
                  itemBuilder: (context) => _placeholderGroups.map((group) {
                    return PopupMenuItem<PlaceholderGroup>(
                      value: group,
                      child: Row(
                        children: [
                          Icon(group.icon, size: 18, color: const Color(0xFFE8CB13)),
                          const SizedBox(width: 12),
                          Text(
                            group.name,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlaceholderGroupDialog(PlaceholderGroup group, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Icon(group.icon, size: 28, color: const Color(0xFF141E7A)),
                  const SizedBox(width: 12),
                  Text(
                    group.name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: group.items.length,
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  return ListTile(
                    leading: Icon(item.icon, color: const Color(0xFF141E7A)),
                    title: Text(
                      item.label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      item.value,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        //fontFamily: 'monospace',
                      ),
                    ),
                    trailing: Chip(
                      label: Text(
                        'Insert',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: const Color(0xFF141E7A).withOpacity(0.1),
                      side: BorderSide.none,
                    ),
                    onTap: () {
                      _insertPlaceholder(item.value, controller);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF141E7A).withOpacity(0.08), const Color(0xFF141E7A).withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                'ADVANCED CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141E7A),
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
          'TIME ZONE',
          _buildModernDropdown<String>(
            value: _selectedTimeZone,
            items: _timeZones,
            onChanged: (v) => setState(() => _selectedTimeZone = v!),
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
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
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
              colors: [const Color(0xFF141E7A).withOpacity(0.08), const Color(0xFF141E7A).withOpacity(0.02)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.toggle_on, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Text(
                'STATUS CONFIGURATION',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141E7A),
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
                  color: _isActive == 1 ? const Color(0xFF141E7A).withOpacity(0.1) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Switch(
                  value: _isActive == 1,
                  onChanged: (val) => setState(() => _isActive = val ? 1 : 0),
                  activeColor: const Color(0xFF141E7A),
                  inactiveThumbColor: Colors.red.shade300,
                  inactiveTrackColor: Colors.red.shade100,
                  activeTrackColor: const Color(0xFF141E7A).withOpacity(0.5),
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

// Helper class for placeholder groups
class PlaceholderGroup {
  final String name;
  final List<PlaceholderItem> items;
  final IconData icon;

  PlaceholderGroup(this.name, this.items, [this.icon = Icons.folder]);
}

// Helper class for placeholder items
class PlaceholderItem {
  final String value;
  final String label;
  final IconData icon;

  PlaceholderItem(this.value, this.label, this.icon);
}

// Extended time zones list
final List<String> _timeZones = [
  'UTC-12:00 (Baker Island)',
  'UTC-11:00 (American Samoa)',
  'UTC-10:00 (Honolulu)',
  'UTC-09:00 (Anchorage)',
  'UTC-08:00 (Los Angeles)',
  'UTC-07:00 (Denver)',
  'UTC-06:00 (Chicago)',
  'UTC-05:00 (New York)',
  'UTC-04:00 (Santiago)',
  'UTC-03:00 (Buenos Aires)',
  'UTC-02:00 (South Georgia)',
  'UTC-01:00 (Azores)',
  'UTC+00:00 (London)',
  'UTC+01:00 (Berlin)',
  'UTC+02:00 (Athens)',
  'UTC+03:00 (Moscow)',
  'UTC+04:00 (Dubai)',
  'UTC+05:00 (Karachi)',
  'UTC+05:30 (Chennai)',
  'UTC+06:00 (Dhaka)',
  'UTC+07:00 (Bangkok)',
  'UTC+08:00 (Singapore)',
  'UTC+09:00 (Tokyo)',
  'UTC+10:00 (Sydney)',
  'UTC+11:00 (Noumea)',
  'UTC+12:00 (Auckland)',
];*/

/*
class AddMessageTemplateModal extends ConsumerStatefulWidget {
  final MessageTemplate? initialTemplate;

  const AddMessageTemplateModal({super.key, this.initialTemplate});

  @override
  ConsumerState<AddMessageTemplateModal> createState() => _AddMessageTemplateModalState();
}

class _AddMessageTemplateModalState extends ConsumerState<AddMessageTemplateModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  int _isActive = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _nameController.text = t.name;
      _descriptionController.text = t.description ?? '';
      _subjectController.text = t.subject ?? '';
      _bodyController.text = t.body;
      _isActive = t.isActive;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Template Name')),
      );
      return;
    }
    if (_bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Template Body')),
      );
      return;
    }

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'subject': _subjectController.text.isEmpty ? null : _subjectController.text,
      'body': _bodyController.text,
      'date_format': null,
      'time_format': null,
      'time_zone_type': null,
      'time_zone_fixed': null,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.initialTemplate != null ? 'Template updated' : 'Template created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SizedBox(
          width: 700,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.initialTemplate != null ? 'Edit Message Template' : 'Create Message Template',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildLabelField(
                          'TEMPLATE NAME',
                          AppTextField(
                            controller: _nameController,
                            hint: 'e.g. Alarm Notification',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabelField(
                          'DESCRIPTION',
                          AppTextField(
                            controller: _descriptionController,
                            hint: 'Short description of the template purpose',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabelField(
                          'SUBJECT (WITH PLACEHOLDERS)',
                          AppTextField(
                            controller: _subjectController,
                            hint: 'e.g. Alert: {alarm_name} at {plant_name}',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabelField(
                          'BODY CONTENT (HTML SUPPORTED)',
                          AppTextField(
                            controller: _bodyController,
                            hint: 'Enter template body...',
                            maxLines: 8,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStatusSection(),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF141E7A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              widget.initialTemplate != null ? 'UPDATE TEMPLATE' : 'CREATE TEMPLATE',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS CONFIGURATION',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF141E7A),
            letterSpacing: 1.2,
          ),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildLabelField(
                'ACTIVE STATUS',
                AppDropdown<int>(
                  value: _isActive,
                  items: const [1, 0],
                  hint: 'Status',
                  itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
                  onChanged: (v) => setState(() => _isActive = v!),
                ),
              ),
            ),
          ],
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
            color: const Color(0xFF333333),
            letterSpacing: 0.5,
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
}*/
