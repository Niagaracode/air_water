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
}
