import 'package:country_picker/country_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/constants/app_strings.dart';
import 'package:pulse/core/utils/validators.dart';

void main() {
  group('Validators.validatePassword', () {
    test('returns null for a non-empty password', () {
      expect(Validators.validatePassword('anything'), isNull);
    });

    test('rejects empty password', () {
      expect(Validators.validatePassword(''), AppStrings.errorEmptyField);
    });
  });

  group('Validators international phone helpers', () {
    test('accepts canonical E.164 phone numbers', () {
      expect(Validators.validatePhone('+14155552671'), isNull);
    });

    test('rejects invalid non-E.164 phone values', () {
      expect(
        Validators.validatePhone('4155552671'),
        AppStrings.errorInvalidPhone,
      );
    });

    test('normalizes local number to E.164 with selected country', () {
      expect(
        Validators.normalizePhoneForStorage(
          '415 555 2671',
          country: Country.parse('US'),
        ),
        '+14155552671',
      );
    });

    test('normalizes Malaysia local number with leading zero', () {
      expect(
        Validators.normalizePhoneForStorage(
          '012-345 6789',
          country: Country.parse('MY'),
        ),
        '+60123456789',
      );
    });

    test('canonicalizes legacy stored Malaysia phone numbers', () {
      expect(Validators.canonicalizeStoredPhone('0123456789'), '+60123456789');
    });

    test('keeps empty phone optional', () {
      expect(Validators.validatePhone(''), isNull);
      expect(Validators.normalizePhoneForStorage(''), '');
      expect(Validators.canonicalizeStoredPhone(''), '');
    });

    test('builds digits-only search value', () {
      expect(Validators.phoneSearchDigits('+1 (415) 555-2671'), '14155552671');
    });

    test('formats stored E.164 phone for display', () {
      expect(Validators.formatPhoneForDisplay('+14155552671'), '+1 4155552671');
    });

    test('extracts national number for editing from E.164', () {
      expect(
        Validators.nationalNumberForEditing(
          '+14155552671',
          fallbackCountry: Country.parse('US'),
        ),
        '4155552671',
      );
    });
  });
}
