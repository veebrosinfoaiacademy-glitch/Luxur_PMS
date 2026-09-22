/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    type: "base",
    name: "staff",
    listRule: "@request.auth.role = \"admin\" || @request.auth.role = \"hr\" || @request.auth.role = \"chairman\"",
    viewRule: "@request.auth.role = \"admin\" || @request.auth.role = \"hr\" || @request.auth.role = \"chairman\"",
    createRule: "@request.auth.role = \"hr\"",
    updateRule: "@request.auth.role = \"hr\"",
    fields: [
      { type: "text", name: "name", required: true, max: 150 },
      {
        type: "select",
        name: "staff_type",
        required: true,
        maxSelect: 1,
        values: ["Telecaller", "Receptionist", "Doctor", "Nurse", "Admin", "Manager", "Marketing"],
      },
      { type: "text", name: "phone", max: 20 },
      { type: "email", name: "email" },
      { type: "bool", name: "active" },
      { type: "date", name: "joined_date" },
      { type: "text", name: "notes", max: 2000 },
      { type: "autodate", name: "created", onCreate: true },
      { type: "autodate", name: "updated", onCreate: true, onUpdate: true },
    ],
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("staff");
  return app.delete(collection);
})
