/// <reference path="../pb_data/types.d.ts" />

// A consultation is its own clinical record: the Doctor who performed it is
// recorded HERE (never on the patient — there is no permanent
// patient -> doctor relationship). A consultation either recommends a
// treatment or concludes that none is required; either way it may carry an
// optional consultation fee, which Admin later bills separately from any
// session billing.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const patients = app.findCollectionByNameOrId("patients");
  const treatments = app.findCollectionByNameOrId("treatments");

  const collection = new Collection({
    type: "base",
    name: "consultations",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    // Doctors record consultations. Admin can update one (e.g. to
    // add/replace images) but never to re-attribute it — see
    // pb_hooks/consultations_workflow.pb.js, which pins `doctor` to the
    // doctor who submitted it.
    createRule: "@request.auth.role = \"doctor\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"doctor\" || @request.auth.role = \"admin\"",
    fields: [
      { type: "relation", name: "patient", collectionId: patients.id, required: true, maxSelect: 1 },
      // The doctor who submitted/completed this consultation.
      { type: "relation", name: "doctor", collectionId: users.id, maxSelect: 1 },
      { type: "text", name: "reason_for_visit", max: 1000 },
      { type: "editor", name: "notes" },
      {
        type: "file",
        name: "images",
        maxSelect: 20,
        maxSize: 10485760,
        mimeTypes: ["image/jpeg", "image/png", "image/webp"],
      },
      {
        type: "select",
        name: "recommendation",
        maxSelect: 1,
        values: ["Recommend Treatment", "No Treatment Required"],
      },
      // Optional on BOTH the treatment and no-treatment paths. Billed
      // separately from sessions and never counted toward treatment
      // progress.
      { type: "number", name: "consultation_fee" },
      // Advisory only — deliberately never carried into session billing.
      { type: "text", name: "suggested_product", max: 200 },
      // Set when a "Recommend Treatment" consultation created a treatment.
      { type: "relation", name: "treatment", collectionId: treatments.id, maxSelect: 1 },
      {
        type: "select",
        name: "status",
        required: true,
        maxSelect: 1,
        values: ["draft", "completed"],
      },
      { type: "date", name: "completed_at" },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("consultations");
  return app.delete(collection);
})
