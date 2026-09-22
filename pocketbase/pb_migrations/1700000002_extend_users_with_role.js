/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const staff = app.findCollectionByNameOrId("staff");

  users.fields.add(
    new SelectField({
      name: "role",
      required: true,
      maxSelect: 1,
      values: ["admin", "doctor", "hr", "chairman", "telecaller"],
    }),
    new RelationField({
      name: "staff",
      collectionId: staff.id,
      maxSelect: 1,
    }),
    new BoolField({ name: "active" }),
  );

  users.listRule = "@request.auth.role = \"admin\" || @request.auth.role = \"hr\"";
  users.viewRule = "id = @request.auth.id || @request.auth.role = \"admin\" || @request.auth.role = \"hr\"";
  users.createRule = "@request.auth.role = \"admin\" || @request.auth.role = \"hr\"";
  users.updateRule = "id = @request.auth.id || @request.auth.role = \"admin\" || @request.auth.role = \"hr\"";
  users.deleteRule = "@request.auth.role = \"admin\" || @request.auth.role = \"hr\"";

  return app.save(users);
}, (app) => {
  const users = app.findCollectionByNameOrId("users");

  users.fields.removeByName("role");
  users.fields.removeByName("staff");
  users.fields.removeByName("active");

  users.listRule = "id = @request.auth.id";
  users.viewRule = "id = @request.auth.id";
  users.createRule = "";
  users.updateRule = "id = @request.auth.id";
  users.deleteRule = "id = @request.auth.id";

  return app.save(users);
})
