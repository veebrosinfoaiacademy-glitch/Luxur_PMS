/// <reference path="../pb_data/types.d.ts" />

// Automatic no-show: a scheduled session becomes NO-SHOW once its
// scheduled date is strictly before today and the patient never arrived.
//
// Deliberately NOT the Telecaller follow-up rule — that one is about
// un-converted leads whose expected arrival date has passed. This one is
// about booked sessions the patient didn't turn up for. They are separate
// business concepts and must not share logic.
//
// Runs on this server's clock once a day, so it never depends on a client
// opening a screen or on a device's local date. Date-only comparison:
// scheduled_date is always written as UTC midnight (see
// SessionRepository), so comparing against today's UTC midnight compares
// calendar dates with no time-of-day involved. Today is never a no-show;
// only strictly-earlier dates are.
cronAdd("sessions_no_show", "59 23 * * *", () => {
  const now = new Date();
  const todayUtcMidnight = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const todayIso = todayUtcMidnight.toISOString().replace("T", " ");

  const overdue = $app.findRecordsByFilter(
    "sessions",
    `status = "scheduled" && scheduled_date < "${todayIso}"`,
    "",
    0,
    0,
  );

  for (const session of overdue) {
    session.set("status", "no_show");
    $app.save(session);
  }

  console.log(`[sessions_no_show] marked ${overdue.length} overdue session(s) as no_show`);
});
