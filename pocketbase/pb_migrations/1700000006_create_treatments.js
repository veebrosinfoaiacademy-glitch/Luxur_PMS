/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const patients = app.findCollectionByNameOrId("patients");

  const collection = new Collection({
    type: "base",
    name: "treatments",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    createRule: "@request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"admin\"",
    fields: [
      { type: "relation", name: "patient", collectionId: patients.id, required: true, maxSelect: 1 },
      {
        type: "select",
        name: "treatment_type",
        required: true,
        maxSelect: 1,
        values: ["Hair", "Skin", "Laser", "Body Aesthetics"],
      },
      { type: "text", name: "package_name", max: 150 },
      { type: "number", name: "sessions_total" },
      { type: "number", name: "sessions_remaining" },
      { type: "number", name: "consultation_charge" },
      {
        type: "select",
        name: "status",
        required: true,
        maxSelect: 1,
        values: ["Active", "Completed", "Discontinued"],
      },
      { type: "relation", name: "assigned_doctor", collectionId: users.id, maxSelect: 1 },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("treatments");
  return app.delete(collection);
})
