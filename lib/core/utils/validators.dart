import 'package:country_picker/country_picker.dart';

import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static final CountryService _countryService = CountryService();
  static final Country _defaultPhoneCountry =
      _countryService.findByCode('MY') ?? Country.parse('MY');
  static final List<Country> _countriesByDialCodeLength = List<Country>.from(
    _countryService.getAll(),
  )..sort((left, right) => right.phoneCode.length - left.phoneCode.length);

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorEmptyField;
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return AppStrings.errorInvalidEmail;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorEmptyField;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorEmptyField;
    }
    if (value != password) {
      return AppStrings.errorPasswordMismatch;
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorEmptyField;
    }
    if (value.trim().length < 2) {
      return AppStrings.errorInvalidName;
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorEmptyField;
    }
    final trimmed = value.trim().toLowerCase();
    if (trimmed.length < 3 || trimmed.length > 20) {
      return AppStrings.errorInvalidUsername;
    }
    final usernameRegex = RegExp(r'^[a-z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return AppStrings.errorInvalidUsername;
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value.trim())) {
      return AppStrings.errorInvalidPhone;
    }
    return null;
  }

  static Country defaultPhoneCountry() => _defaultPhoneCountry;

  static Country countryFromPhone(String phone) {
    final canonicalPhone = canonicalizeStoredPhone(phone);
    if (canonicalPhone == null || canonicalPhone.isEmpty) {
      return _defaultPhoneCountry;
    }

    final digits = canonicalPhone.substring(1);
    for (final country in _countriesByDialCodeLength) {
      if (digits.startsWith(country.phoneCode)) {
        return country;
      }
    }

    return _defaultPhoneCountry;
  }

  static String nationalNumberForEditing(
    String phone, {
    Country? fallbackCountry,
  }) {
    final canonicalPhone = canonicalizeStoredPhone(phone);
    if (canonicalPhone == null || canonicalPhone.isEmpty) {
      return '';
    }

    final country = _countryForPhone(
      canonicalPhone,
      fallbackCountry: fallbackCountry,
    );
    if (country == null) {
      return canonicalPhone.substring(1);
    }

    final countryDigitsLength = country.phoneCode.length;
    return canonicalPhone.substring(countryDigitsLength + 1);
  }

  static String? normalizePhoneForStorage(String phone, {Country? country}) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final digits = phoneSearchDigits(trimmed);
    if (digits.isEmpty) {
      return '';
    }

    String candidate;
    if (trimmed.startsWith('+')) {
      candidate = '+$digits';
    } else {
      final selectedCountry = country ?? _defaultPhoneCountry;
      var nationalDigits = digits;

      if (nationalDigits.startsWith('0')) {
        nationalDigits = nationalDigits.substring(1);
      }

      candidate = '+${selectedCountry.phoneCode}$nationalDigits';
    }

    return validatePhone(candidate) == null ? candidate : null;
  }

  static String? canonicalizeStoredPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final digits = phoneSearchDigits(trimmed);
    if (digits.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('+')) {
      final canonical = '+$digits';
      return validatePhone(canonical) == null ? canonical : null;
    }

    final legacyMalaysiaCandidate = _legacyMalaysiaCandidate(digits);
    if (legacyMalaysiaCandidate != null) {
      return legacyMalaysiaCandidate;
    }

    final prefixed = '+$digits';
    return validatePhone(prefixed) == null ? prefixed : null;
  }

  static String phoneSearchDigits(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static String formatPhoneForDisplay(String phone) {
    final canonicalPhone = canonicalizeStoredPhone(phone);
    if (canonicalPhone == null || canonicalPhone.isEmpty) {
      return phone.trim();
    }

    final country = _countryForPhone(canonicalPhone);
    if (country == null) {
      return canonicalPhone;
    }

    final nationalNumber = canonicalPhone.substring(
      country.phoneCode.length + 1,
    );
    if (nationalNumber.isEmpty) {
      return canonicalPhone;
    }

    return '+${country.phoneCode} $nationalNumber';
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorEmptyField;
    }
    return null;
  }

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : AppStrings.errorEmptyField;
    }
    return null;
  }

  static Country? _countryForPhone(
    String canonicalPhone, {
    Country? fallbackCountry,
  }) {
    final digits = canonicalPhone.substring(1);
    final countries = fallbackCountry == null
        ? _countriesByDialCodeLength
        : [
            fallbackCountry,
            ..._countriesByDialCodeLength.where(
              (country) => country.countryCode != fallbackCountry.countryCode,
            ),
          ];

    for (final country in countries) {
      if (digits.startsWith(country.phoneCode)) {
        return country;
      }
    }

    return null;
  }

  static String? _legacyMalaysiaCandidate(String digits) {
    if (digits.startsWith('60') && digits.length >= 10 && digits.length <= 12) {
      final canonical = '+$digits';
      return validatePhone(canonical) == null ? canonical : null;
    }

    if (digits.startsWith('0') && digits.length >= 9 && digits.length <= 11) {
      final canonical = '+60${digits.substring(1)}';
      return validatePhone(canonical) == null ? canonical : null;
    }

    if (digits.length >= 9 && digits.length <= 10) {
      final canonical = '+60$digits';
      return validatePhone(canonical) == null ? canonical : null;
    }

    return null;
  }
}
