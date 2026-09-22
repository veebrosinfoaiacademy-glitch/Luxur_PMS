/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const patients = app.findCollectionByNameOrId("patients");
  const treatments = app.findCollectionByNameOrId("treatments");
  const sessions = app.findCollectionByNameOrId("sessions");

  const bills = new Collection({
    type: "base",
    name: "bills",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"chairman\"",
    createRule: "@request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"admin\"",
    fields: [
      { type: "relation", name: "patient", collectionId: patients.id, required: true, maxSelect: 1 },
      { type: "relation", name: "treatment", collectionId: treatments.id, maxSelect: 1 },
      { type: "relation", name: "session", collectionId: sessions.id, maxSelect: 1 },
      { type: "text", name: "bill_number", max: 40 },
      { type: "number", name: "consultation_charge" },
      { type: "number", name: "treatment_fee" },
      { type: "number", name: "product_cost" },
      { type: "number", name: "total_amount", required: true },
      { type: "select", name: "payment_method", maxSelect: 1, values: ["Cash", "Online"] },
      {
        type: "select",
        name: "payment_status",
        required: true,
        maxSelect: 1,
        values: ["Paid", "Pending", "Partial"],
      },
      { type: "text", name: "notes", max: 1000 },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });
  app.save(bills);

  const pharmacyBills = new Collection({
    type: "base",
    name: "pharmacy_bills",
    listRule: "@request.auth.role = \"admin\"",
    viewRule: "@request.auth.role = \"admin\"",
    createRule: "@request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"admin\"",
    fields: [
      { type: "relation", name: "patient", collectionId: patients.id, required: true, maxSelect: 1 },
      { type: "text", name: "pharmacy_name", required: true, max: 150 },
      { type: "number", name: "amount", required: true },
      { type: "date", name: "due_date", required: true },
      {
        type: "file",
        name: "attachment",
        maxSelect: 1,
        maxSize: 10485760,
        mimeTypes: ["image/jpeg", "image/png", "image/webp", "application/pdf"],
      },
      {
        type: "select",
        name: "status",
        required: true,
        maxSelect: 1,
        values: ["Pending", "Paid"],
      },
      { type: "bool", name: "reminder_closed" },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });
  return app.save(pharmacyBills);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("pharmacy_bills"));
  return app.delete(app.findCollectionByNameOrId("bills"));
})
