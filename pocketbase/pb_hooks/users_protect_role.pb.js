/// <reference path="../pb_data/types.d.ts" />

// API rules are record-level only, so the "users" updateRule that lets an
// account edit its own profile (id = @request.auth.id) also lets it PATCH
// its own `role`/`active`/`staff` fields — a privilege-escalation hole.
// Requirements §13 explicitly require role restrictions enforced
// server-side, so this hook blocks changes to those three fields unless the
// requester is already admin or hr.
onRecordUpdateRequest((e) => {
  const protectedFields = ["role", "active", "staff"];
  const original = e.record.original();

  const requesterRole = e.auth ? e.auth.getString("role") : "";
  const isPrivileged = e.hasSuperuserAuth() || requesterRole === "admin" || requesterRole === "hr";

  if (!isPrivileged) {
    for (const field of protectedFields) {
      if (e.record.get(field) !== original.get(field)) {
        throw new ForbiddenError(`Only admin or hr may change '${field}' on a user account.`);
      }
    }
  }

  e.next();
}, "users");
