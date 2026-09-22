import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils.normalizeIndianMobile', () {
    test('accepts a plain 10-digit number', () {
      expect(PhoneUtils.normalizeIndianMobile('9876543210'), '9876543210');
    });

    test('strips +91 prefix', () {
      expect(PhoneUtils.normalizeIndianMobile('+91 98765 43210'), '9876543210');
    });

    test('strips 91 prefix without plus', () {
      expect(PhoneUtils.normalizeIndianMobile('919876543210'), '9876543210');
    });

    test('strips leading 0 (STD-style entry)', () {
      expect(PhoneUtils.normalizeIndianMobile('09876543210'), '9876543210');
    });

    test('strips spaces, dashes and parentheses', () {
      expect(PhoneUtils.normalizeIndianMobile('(987) 654-3210'), '9876543210');
    });

    test('rejects a number that is too short', () {
      expect(PhoneUtils.normalizeIndianMobile('98765432'), isNull);
    });

    test('rejects a number that is too long after prefix stripping', () {
      expect(PhoneUtils.normalizeIndianMobile('99987654321011'), isNull);
    });

    test('rejects a landline-style prefix (starts with 1-5)', () {
      expect(PhoneUtils.normalizeIndianMobile('1234567890'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(PhoneUtils.normalizeIndianMobile('not a phone'), isNull);
    });

    test('rejects empty input', () {
      expect(PhoneUtils.normalizeIndianMobile(''), isNull);
    });
  });

  group('PhoneUtils.display', () {
    test('adds +91 prefix for display', () {
      expect(PhoneUtils.display('9876543210'), '+91 9876543210');
    });
  });
}
