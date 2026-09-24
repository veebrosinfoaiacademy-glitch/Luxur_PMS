/// <reference path="../pb_data/types.d.ts" />

// Server-side enforcement of the finalized session workflow. There is NO
// Start Session and NO End Session step:
//
//   SCHEDULED -> ARRIVED -> COMPLETED
//
// The `sessions` updateRule only checks the caller's role, not which fields
// change or what they're set to, so the actual rules live here:
//
//  1. `arrived_at` is never taken from the client. It is stamped from this
//     server's clock the moment `status` becomes "arrived", and reset to
//     whatever it already was on every other request — a device with a
//     wrong clock (or a crafted request) cannot forge an arrival time.
//  2. `ended_at` works the same way for the transition to "completed".
//  3. Completing a session requires the clinical information to already be
//     on the record: notes and at least one image.
//  4. Doctor attribution is per session. If the session was left
//     unassigned, the doctor who completes it becomes that session's
//     doctor; an already-assigned doctor is preserved even when a
//     different doctor completes it.
onRecordUpdateRequest((e) => {
  const original = e.record.original();
  const oldStatus = original.getString("status");
  const newStatus = e.record.getString("status");
  const requesterRole = e.auth ? e.auth.getString("role") : "";
  const enteringArrived = newStatus === "arrived" && oldStatus !== "arrived";
  const enteringCompleted = newStatus === "completed" && oldStatus !== "completed";

  if (enteringArrived) {
    e.record.set("arrived_at", new Date());
  } else if (e.record.get("arrived_at") !== original.get("arrived_at")) {
    e.record.set("arrived_at", original.get("arrived_at"));
  }

  if (enteringCompleted) {
    if (oldStatus !== "arrived") {
      throw new BadRequestError("A session can only be completed once the patient has arrived.");
    }
    if (e.record.getString("notes").trim() === "") {
      throw new BadRequestError("Session notes are required before completing a session.");
    }
    if (e.record.get("images").length < 1) {
      throw new BadRequestError("At least one image is required before completing a session.");
    }
    e.record.set("ended_at", new Date());
    if (e.record.getString("doctor") === "" && requesterRole === "doctor" && e.auth) {
      e.record.set("doctor", e.auth.id);
    }
  } else if (e.record.get("ended_at") !== original.get("ended_at")) {
    e.record.set("ended_at", original.get("ended_at"));
  }

  e.next();
}, "sessions");
