/// <reference path="../pb_data/types.d.ts" />

// Fields the finalized Admin/Doctor workflow needs on top of the original
// treatment/billing schema:
//
//  treatments.package_cost   the financial baseline for the treatment
//                            progress bar. Progress is the sum of PAID
//                            session fees over this, so it needs its own
//                            field rather than being inferred.
//  treatments.consultation   which consultation recommended this treatment.
//
//  bills.consultation        consultation bills and session bills are
//                            separate records; a bill points at one or the
//                            other, never both.
//  bills.product_name        the product a bill charges for (its amount
//                            already exists as product_cost, and is
//                            deliberately excluded from treatment progress).
//  bills.paid_at             stamped server-side when Admin marks
//                            "Patient Paid" — generating a bill does NOT
//                            make it paid. See pb_hooks/bills_payment.pb.js.
migrate((app) => {
  const consultations = app.findCollectionByNameOrId("consultations");

  const treatments = app.findCollectionByNameOrId("treatments");
  treatments.fields.add(new NumberField({ name: "package_cost" }));
  treatments.fields.add(new RelationField({
    name: "consultation",
    collectionId: consultations.id,
    maxSelect: 1,
  }));
  app.save(treatments);

  const bills = app.findCollectionByNameOrId("bills");
  bills.fields.add(new RelationField({
    name: "consultation",
    collectionId: consultations.id,
    maxSelect: 1,
  }));
  bills.fields.add(new TextField({ name: "product_name", max: 200 }));
  bills.fields.add(new DateField({ name: "paid_at" }));
  return app.save(bills);
}, (app) => {
  const treatments = app.findCollectionByNameOrId("treatments");
  treatments.fields.removeByName("package_cost");
  treatments.fields.removeByName("consultation");
  app.save(treatments);

  const bills = app.findCollectionByNameOrId("bills");
  bills.fields.removeByName("consultation");
  bills.fields.removeByName("product_name");
  bills.fields.removeByName("paid_at");
  return app.save(bills);
})
