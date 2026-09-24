import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/models/telecaller_lead.dart';
import 'package:pms_vbis/features/telecaller/utils/follow_up.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  TelecallerLead lead({
    required bool converted,
    DateTime? expectedArrivalDate,
  }) {
    return TelecallerLead(
      id: 'lead-1',
      name: 'Test Lead',
      phone: '9876543210',
      address: '',
      concern: '',
      telecallerId: 'tc-1',
      converted: converted,
      created: DateTime(2026, 9, 1),
      expectedArrivalDate: expectedArrivalDate,
    );
  }

  group('isFollowUpDue', () {
    // TEST 1
    test('a future expected arrival date is not due for follow-up', () {
      final l = lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 28));
      expect(isFollowUpDue(l, now: today), isFalse);
    });

    // TEST 2
    test("today's expected arrival date is not yet overdue", () {
      final l = lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 23));
      expect(isFollowUpDue(l, now: today), isFalse);
    });

    // TEST 3
    test('yesterday\'s expected arrival date is due for follow-up', () {
      final l = lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 22));
      expect(isFollowUpDue(l, now: today), isTrue);
    });

    // TEST 4
    test('an older expected arrival date is due for follow-up', () {
      final l = lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 3));
      expect(isFollowUpDue(l, now: today), isTrue);
    });

    // TEST 5
    test('a converted lead is never due, even with a past expected arrival date', () {
      final l = lead(converted: true, expectedArrivalDate: DateTime(2026, 9, 3));
      expect(isFollowUpDue(l, now: today), isFalse);
    });

    // TEST 6: same lead, only the reference date changes — demonstrates
    // eligibility is driven purely by the calendar date comparison, not by
    // anything baked into the lead itself.
    test('the same lead becomes eligible once its expected date passes', () {
      final l = lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 23));
      expect(isFollowUpDue(l, now: DateTime(2026, 9, 23)), isFalse);
      expect(isFollowUpDue(l, now: DateTime(2026, 9, 24)), isTrue);
    });

    // TEST 7
    test('only overdue, non-converted leads are selected from a mixed batch', () {
      final leads = [
        lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 28)), // future
        lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 23)), // today
        lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 22)), // yesterday
        lead(converted: false, expectedArrivalDate: DateTime(2026, 9, 3)), // old
        lead(converted: true, expectedArrivalDate: DateTime(2026, 9, 3)), // converted
      ];
      final due = leads.where((l) => isFollowUpDue(l, now: today)).toList();
      expect(due, hasLength(2));
      expect(due.every((l) => !l.converted), isTrue);
    });

    test('a lead with no expected arrival date is never due (unknown, not overdue)', () {
      final l = lead(converted: false, expectedArrivalDate: null);
      expect(isFollowUpDue(l, now: today), isFalse);
    });

    test('created date has no bearing on follow-up eligibility', () {
      // A lead created long ago but with a future expected arrival date
      // must not be due — created date is deliberately not read at all by
      // isFollowUpDue.
      final l = TelecallerLead(
        id: 'lead-2',
        name: 'Old Record',
        phone: '9876500000',
        address: '',
        concern: '',
        telecallerId: 'tc-1',
        converted: false,
        created: DateTime(2020, 1, 1),
        expectedArrivalDate: DateTime(2026, 9, 28),
      );
      expect(isFollowUpDue(l, now: today), isFalse);
    });
  });
}
