import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  @Deprecated('Use obscureText instead')
  final bool obscure;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onToggle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final int? maxLines;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Color? prefixIconColor;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.obscure = false,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.keyboardType,
    this.prefixIcon,
    this.prefixIconColor,
    this.suffixIcon,
    this.onToggle,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use_from_same_package
    final isObscured = obscure || obscureText;
    return TextField(
      controller: controller,
      obscureText: isObscured,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      focusNode: focusNode,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        prefixIcon: prefixIcon,
        prefixIconColor: prefixIconColor,
        suffixIcon: suffixIcon ?? (isPassword
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
                onPressed: onToggle,
              )
            : null),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF141E7A), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
