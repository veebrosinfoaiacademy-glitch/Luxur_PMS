/// <reference path="../pb_data/types.d.ts" />

// A consultation belongs to the doctor who performed it, and that
// attribution must survive everything that happens afterwards (Admin
// billing it, anyone editing its images, later sessions being handled by
// other doctors).
//
//  - On create by a doctor, `doctor` is stamped from the authenticated
//    session rather than trusted from the request body.
//  - Once set, `doctor` cannot be changed by a normal admin/doctor request.
//  - `completed_at` is stamped from this server's clock when the
//    consultation is completed; a client-supplied value is ignored.
onRecordCreateRequest((e) => {
  const requesterRole = e.auth ? e.auth.getString("role") : "";
  if (requesterRole === "doctor" && e.auth) {
    e.record.set("doctor", e.auth.id);
  }
  if (e.record.getString("status") === "completed") {
    e.record.set("completed_at", new Date());
  } else {
    e.record.set("completed_at", null);
  }
  e.next();
}, "consultations");

onRecordUpdateRequest((e) => {
  const original = e.record.original();
  const isPrivileged = e.hasSuperuserAuth();

  if (!isPrivileged && e.record.getString("doctor") !== original.getString("doctor")) {
    throw new ForbiddenError("A consultation's doctor attribution cannot be changed.");
  }

  const enteringCompleted =
    e.record.getString("status") === "completed" && original.getString("status") !== "completed";
  if (enteringCompleted) {
    e.record.set("completed_at", new Date());
  } else if (e.record.get("completed_at") !== original.get("completed_at")) {
    e.record.set("completed_at", original.get("completed_at"));
  }

  e.next();
}, "consultations");
