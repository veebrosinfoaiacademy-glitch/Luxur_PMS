import '../models/telecaller_lead.dart';

/// Calendar-date-only comparison (no time-of-day, no timezone conversion —
/// just the y/m/d the caller already has), matching the "date, not
/// timestamp" business rule for expected clinic arrival.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// True when [lead] is overdue for a Telecaller follow-up call:
/// not converted, has a known expected arrival date, and that date is
/// strictly before [now]'s calendar date (today's date is NOT yet overdue —
/// it only becomes overdue the day after).
///
/// Deliberately does NOT use `lead.created` — adding a lead must never by
/// itself put it in Follow-Up; only a missed expected arrival date does.
bool isFollowUpDue(TelecallerLead lead, {DateTime? now}) {
  if (lead.converted) return false;
  final expected = lead.expectedArrivalDate;
  if (expected == null) return false;
  return _dateOnly(expected).isBefore(_dateOnly(now ?? DateTime.now()));
}
