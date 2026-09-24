/// <reference path="../pb_data/types.d.ts" />

// The telecaller_leads updateRule lets a telecaller edit their own lead
// (telecaller = @request.auth.id), but that rule is record-level only — it
// can't stop the same request from also changing `converted`,
// `converted_patient` or `telecaller` itself. Since the Telecaller "Edit
// Patient" flow only ever sends name/phone/address/concern/
// expected_arrival_date, this hook is defense-in-depth: it blocks a
// telecaller from self-converting a lead or reassigning its attribution via
// a direct API call that bypasses the app UI. Admin/superuser conversion
// (the real conversion workflow) is unaffected.
onRecordUpdateRequest((e) => {
  const protectedFields = ["converted", "converted_patient", "telecaller"];
  const original = e.record.original();

  const requesterRole = e.auth ? e.auth.getString("role") : "";
  const isPrivileged = e.hasSuperuserAuth() || requesterRole === "admin";

  if (!isPrivileged) {
    for (const field of protectedFields) {
      if (e.record.get(field) !== original.get(field)) {
        throw new ForbiddenError(`Only admin may change '${field}' on a telecaller lead.`);
      }
    }
  }

  e.next();
}, "telecaller_leads");
