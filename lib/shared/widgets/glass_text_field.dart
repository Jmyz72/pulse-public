import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Glassmorphism text field following Pulse Cyber-Teal design system
///
/// Specs:
/// - Background: White at 5% opacity
/// - Border: 1.5px Electric Teal at 40% opacity
/// - Focused border: 2px Neon Cyan
/// - Error border: 1.5px Neon Red
/// - Border Radius: 24px
/// - Text: White (#FFFFFF)
/// - Label: Electric Teal (#008B9D)
/// - Hint: White at 60% opacity
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;

  const GlassTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        autofocus: autofocus,
        autovalidateMode: autovalidateMode,
        validator: validator,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          labelStyle: const TextStyle(
            color: AppColors.textTeal,
            fontSize: 16,
          ),
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          errorStyle: const TextStyle(
            color: AppColors.error,
            fontSize: 12,
          ),
          filled: true,
          fillColor: AppColors.glassBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2.0,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: AppColors.grey500.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
