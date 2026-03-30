import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

class InternationalPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String labelText;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final void Function(String)? onChanged;

  const InternationalPhoneField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.labelText,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-\(\)]')),
        ],
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText ?? selectedCountry.example,
          errorText: errorText,
          prefixIcon: _CountrySelectorButton(
            country: selectedCountry,
            enabled: enabled,
            onTap: () => _showCountryPicker(context),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 116),
          labelStyle: const TextStyle(color: AppColors.textTeal, fontSize: 16),
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.error, width: 2.0),
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

  void _showCountryPicker(BuildContext context) {
    if (!enabled) {
      return;
    }

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      useSafeArea: true,
      onSelect: onCountryChanged,
      countryListTheme: CountryListThemeData(
        backgroundColor: const Color(0xFF052B32),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.72,
        textStyle: const TextStyle(color: AppColors.textPrimary),
        inputDecoration: InputDecoration(
          hintText: 'Search country or code',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CountrySelectorButton extends StatelessWidget {
  final Country country;
  final bool enabled;
  final VoidCallback onTap;

  const _CountrySelectorButton({
    required this.country,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '+${country.phoneCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: enabled ? AppColors.textSecondary : AppColors.grey500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
