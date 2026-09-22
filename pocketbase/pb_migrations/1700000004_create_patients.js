/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const telecallerLeads = app.findCollectionByNameOrId("telecaller_leads");

  const collection = new Collection({
    type: "base",
    name: "patients",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    createRule: "@request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"admin\"",
    // no deleteRule set -> hard delete locked to superuser only; patients are
    // soft-deleted via the `archived` flag instead (2026-09-22 decision).
    fields: [
      { type: "text", name: "patient_code", required: true, max: 30 },
      { type: "text", name: "name", required: true, max: 150 },
      { type: "number", name: "age" },
      { type: "date", name: "dob" },
      { type: "select", name: "gender", maxSelect: 1, values: ["Male", "Female", "Other"] },
      { type: "text", name: "phone", required: true, max: 20 },
      { type: "text", name: "address", max: 500 },
      {
        type: "select",
        name: "source",
        maxSelect: 1,
        values: ["Direct Walk-in", "Google Ad", "Meta Ad", "Doctor Recommendation", "Telecalling"],
      },
      // populated when source = "Doctor Recommendation"
      { type: "text", name: "referral_name", max: 150 },
      { type: "text", name: "concern", max: 1000 },
      { type: "relation", name: "assigned_doctor", collectionId: users.id, maxSelect: 1 },
      // attribution back to the originating lead when converted (§8.1/§8.2)
      { type: "relation", name: "telecaller_lead", collectionId: telecallerLeads.id, maxSelect: 1 },
      { type: "relation", name: "telecaller", collectionId: users.id, maxSelect: 1 },
      {
        type: "select",
        name: "status",
        required: true,
        maxSelect: 1,
        values: ["Not Joined", "Joined"],
      },
      { type: "bool", name: "archived" },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });
  collection.addIndex("idx_patients_code", true, "patient_code", "");
  // Not unique: phone is the dedup *lookup* key (requirement §8.2), but a
  // hard DB constraint would also block legitimate shared-household numbers.
  // Duplicate protection is an app-layer check at creation/conversion time.
  collection.addIndex("idx_patients_phone", false, "phone", "");

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("patients");
  return app.delete(collection);
})
