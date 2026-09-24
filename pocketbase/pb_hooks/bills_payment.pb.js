/// <reference path="../pb_data/types.d.ts" />

// Generating a bill does NOT mean it was paid — only Admin's explicit
// "Patient Paid" action does, and the moment that happened is stamped from
// this server's clock rather than taken from the client.
//
// This matters beyond bookkeeping: treatment progress is driven by the
// amounts on PAID session bills, so `payment_status` and `paid_at` are the
// integrity boundary for the progress bar.
onRecordCreateRequest((e) => {
  // A freshly generated bill is never already paid, whatever was posted.
  if (e.record.getString("payment_status") === "Paid") {
    e.record.set("paid_at", new Date());
  } else {
    e.record.set("paid_at", null);
  }
  e.next();
}, "bills");

onRecordUpdateRequest((e) => {
  const original = e.record.original();
  const wasPaid = original.getString("payment_status") === "Paid";
  const isPaid = e.record.getString("payment_status") === "Paid";

  if (isPaid && !wasPaid) {
    e.record.set("paid_at", new Date());
  } else if (!isPaid && wasPaid) {
    e.record.set("paid_at", null);
  } else if (e.record.get("paid_at") !== original.get("paid_at")) {
    // No payment-state transition — a client-supplied paid_at is ignored.
    e.record.set("paid_at", original.get("paid_at"));
  }

  e.next();
}, "bills");
