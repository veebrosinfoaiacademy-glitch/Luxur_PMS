/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const staff = app.findCollectionByNameOrId("staff");

  const hrListView = "@request.auth.role = \"hr\" || @request.auth.role = \"chairman\"";
  const hrWrite = "@request.auth.role = \"hr\"";

  const attendance = new Collection({
    type: "base",
    name: "attendance",
    listRule: hrListView,
    viewRule: hrListView,
    createRule: hrWrite,
    updateRule: hrWrite,
    fields: [
      { type: "relation", name: "staff", collectionId: staff.id, required: true, maxSelect: 1 },
      { type: "date", name: "date", required: true },
      { type: "date", name: "check_in" },
      { type: "date", name: "check_out" },
      { type: "text", name: "biometric_ref", max: 100 },
      { type: "select", name: "source", maxSelect: 1, values: ["biometric", "manual"] },
      { type: "autodate", name: "created", onCreate: true },
    ],
  });
  app.save(attendance);

  const salary = new Collection({
    type: "base",
    name: "salary_records",
    listRule: hrListView,
    viewRule: hrListView,
    createRule: hrWrite,
    updateRule: hrWrite,
    fields: [
      { type: "relation", name: "staff", collectionId: staff.id, required: true, maxSelect: 1 },
      { type: "text", name: "month", required: true, max: 7 }, // "YYYY-MM"
      { type: "number", name: "amount", required: true },
      { type: "date", name: "paid_on" },
      { type: "text", name: "notes", max: 500 },
      { type: "autodate", name: "created", onCreate: true },
    ],
  });
  app.save(salary);

  const incentives = new Collection({
    type: "base",
    name: "incentive_records",
    listRule: hrListView,
    viewRule: hrListView,
    createRule: hrWrite,
    updateRule: hrWrite,
    fields: [
      { type: "relation", name: "staff", collectionId: staff.id, required: true, maxSelect: 1 },
      { type: "text", name: "month", required: true, max: 7 },
      { type: "number", name: "amount", required: true },
      { type: "text", name: "reason", max: 500 },
      { type: "date", name: "paid_on" },
      { type: "autodate", name: "created", onCreate: true },
    ],
  });
  return app.save(incentives);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("incentive_records"));
  app.delete(app.findCollectionByNameOrId("salary_records"));
  return app.delete(app.findCollectionByNameOrId("attendance"));
})
