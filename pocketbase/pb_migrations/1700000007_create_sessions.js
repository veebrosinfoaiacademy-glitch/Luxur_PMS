/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const patients = app.findCollectionByNameOrId("patients");
  const treatments = app.findCollectionByNameOrId("treatments");

  const collection = new Collection({
    type: "base",
    name: "sessions",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\" || @request.auth.role = \"chairman\"",
    // Doctor access is role-based, not ownership-based: any doctor can act on
    // any patient's session, since multiple doctors may treat one patient
    // (2026-09-22 clarification). Admin also has image-edit/mark-finished
    // access as a logged scope change from the original requirements.
    createRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\"",
    updateRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\"",
    fields: [
      { type: "relation", name: "patient", collectionId: patients.id, required: true, maxSelect: 1 },
      { type: "relation", name: "treatment", collectionId: treatments.id, required: true, maxSelect: 1 },
      { type: "relation", name: "doctor", collectionId: users.id, required: true, maxSelect: 1 },
      { type: "date", name: "scheduled_date", required: true },
      {
        type: "select",
        name: "status",
        required: true,
        maxSelect: 1,
        values: ["scheduled", "arrived", "in_progress", "completed", "no_show", "rescheduled"],
      },
      { type: "date", name: "arrived_at" },
      { type: "date", name: "started_at" },
      { type: "date", name: "ended_at" },
      { type: "text", name: "no_show_reason", max: 1000 },
      // used when the Doctor extends/ends treatment with no next session booked
      { type: "date", name: "follow_up_date" },
      { type: "editor", name: "notes" },
      {
        type: "file",
        name: "images",
        maxSelect: 20,
        maxSize: 10485760,
        mimeTypes: ["image/jpeg", "image/png", "image/webp"],
      },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("sessions");
  return app.delete(collection);
})
