/// <reference path="../pb_data/types.d.ts" />

// Clinic-configurable treatment plans (Admin Settings > Treatment Plans).
// The Doctor's consultation form offers the ACTIVE plans of a category;
// a treatment record snapshots the chosen plan's name into its own
// package_name, so deactivating a plan here never rewrites history.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");

  const collection = new Collection({
    type: "base",
    name: "treatment_plans",
    // Doctors read them while consulting; only Admin configures them.
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"doctor\"",
    createRule: "@request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"admin\"",
    fields: [
      // Same 4 values as treatments.treatment_type
      // (1700000006_create_treatments.js) so a configured plan always lines
      // up with a real treatment category.
      {
        type: "select",
        name: "category",
        required: true,
        maxSelect: 1,
        values: ["Hair", "Skin", "Laser", "Body Aesthetics"],
      },
      { type: "text", name: "name", required: true, max: 150 },
      { type: "bool", name: "active" },
      { type: "relation", name: "created_by", collectionId: users.id, maxSelect: 1 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("treatment_plans");
  return app.delete(collection);
})
