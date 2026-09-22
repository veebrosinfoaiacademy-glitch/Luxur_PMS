import '../../../core/utils/phone_utils.dart';
import '../models/telecaller_lead.dart';

/// Case-insensitive match on name, or digit-only match on phone. Pulled out
/// of LeadListView so the filter behavior itself is independently testable
/// without needing a live PocketBase connection.
List<TelecallerLead> filterLeads(List<TelecallerLead> leads, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return leads;

  // Stored phones are canonical 10-digit (see PhoneUtils) with no +91/91/0
  // prefix. A raw digit-strip of the query would keep that prefix if the
  // user typed one (e.g. "+91 98765 43001" -> "919876543001"), which would
  // then never match the stored "9876543001". Normalize first so a full
  // number with or without a prefix still matches; fall back to a plain
  // digit substring for partial in-progress searches that don't form a
  // complete, normalizable number yet.
  final digitsQuery = query.replaceAll(RegExp(r'[^0-9]'), '');
  final normalizedPhoneQuery = PhoneUtils.normalizeIndianMobile(query);

  return leads.where((lead) {
    final matchesName = lead.name.toLowerCase().contains(normalizedQuery);
    final matchesPhone = digitsQuery.isNotEmpty &&
        (lead.phone.contains(digitsQuery) ||
            (normalizedPhoneQuery != null && lead.phone == normalizedPhoneQuery));
    return matchesName || matchesPhone;
  }).toList();
}
