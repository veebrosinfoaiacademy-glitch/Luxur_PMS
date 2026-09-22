import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/models/telecaller_lead.dart';
import 'package:pms_vbis/features/telecaller/utils/lead_search.dart';

TelecallerLead _lead(String name, String phone) => TelecallerLead(
      id: 'id-$name',
      name: name,
      phone: phone,
      address: '',
      concern: '',
      telecallerId: 'tc-1',
      converted: false,
      created: DateTime(2026, 1, 1),
    );

void main() {
  final leads = [
    _lead('Priya Menon', '9876543001'),
    _lead('Arjun Nair', '9876543002'),
    _lead('Sneha Varghese', '9123456789'),
  ];

  group('filterLeads', () {
    test('returns everything for an empty query', () {
      expect(filterLeads(leads, ''), hasLength(3));
    });

    test('matches by partial name, case-insensitively', () {
      final result = filterLeads(leads, 'priya');
      expect(result, hasLength(1));
      expect(result.first.name, 'Priya Menon');
    });

    test('matches by a full phone number', () {
      final result = filterLeads(leads, '9876543002');
      expect(result, hasLength(1));
      expect(result.first.name, 'Arjun Nair');
    });

    test('matches by a partial phone number', () {
      final result = filterLeads(leads, '98765430');
      expect(result, hasLength(2)); // Priya and Arjun share this prefix
    });

    test('ignores formatting characters when matching a phone query', () {
      final result = filterLeads(leads, '+91 98765 43001');
      expect(result, hasLength(1));
      expect(result.first.name, 'Priya Menon');
    });

    test('returns no results for a query that matches nothing', () {
      expect(filterLeads(leads, 'nonexistent'), isEmpty);
    });
  });
}
