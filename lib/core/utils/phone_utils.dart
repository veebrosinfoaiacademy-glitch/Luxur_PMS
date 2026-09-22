/// Phone normalization shared across the app. No prior convention existed
/// in the codebase, so this defines one: canonical storage form is a plain
/// 10-digit Indian mobile number (matches the format already used by
/// pocketbase/pb_migrations and scripts/seed_dev_data.mjs).
class PhoneUtils {
  PhoneUtils._();

  /// Returns the normalized 10-digit number, or null if [raw] isn't a
  /// valid Indian mobile number. Accepts optional +91 / 91 / 0 prefixes
  /// and any spaces/dashes/parentheses.
  static String? normalizeIndianMobile(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 10) return null;
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digits)) return null;

    return digits;
  }

  static String display(String normalized) => '+91 $normalized';
}
