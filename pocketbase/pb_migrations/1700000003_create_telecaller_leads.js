/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");

  const collection = new Collection({
    type: "base",
    name: "telecaller_leads",
    // Separate from the main patient database by design — Admin conversion
    // is the only path into `patients`. See pms-project skill / requirements
    // §8 (Telecaller Account Requirements).
    listRule: "@request.auth.role = \"admin\" || (@request.auth.role = \"telecaller\" && telecaller = @request.auth.id)",
    viewRule: "@request.auth.role = \"admin\" || (@request.auth.role = \"telecaller\" && telecaller = @request.auth.id)",
    createRule: "@request.auth.role = \"telecaller\" && @request.body.telecaller = @request.auth.id",
    updateRule: "@request.auth.role = \"admin\" || (@request.auth.role = \"telecaller\" && telecaller = @request.auth.id)",
    fields: [
      { type: "text", name: "name", required: true, max: 150 },
      { type: "text", name: "phone", required: true, max: 20 },
      { type: "text", name: "address", max: 500 },
      { type: "text", name: "concern", max: 1000 },
      {
        type: "relation",
        name: "telecaller",
        collectionId: users.id,
        required: true,
        maxSelect: 1,
      },
      { type: "bool", name: "converted" },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });
  collection.addIndex("idx_telecaller_leads_phone", false, "phone", "");

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("telecaller_leads");
  return app.delete(collection);
})
