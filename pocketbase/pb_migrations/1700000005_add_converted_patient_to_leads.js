/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const leads = app.findCollectionByNameOrId("telecaller_leads");
  const patients = app.findCollectionByNameOrId("patients");

  leads.fields.add(new RelationField({
    name: "converted_patient",
    collectionId: patients.id,
    maxSelect: 1,
  }));

  return app.save(leads);
}, (app) => {
  const leads = app.findCollectionByNameOrId("telecaller_leads");
  leads.fields.removeByName("converted_patient");
  return app.save(leads);
})
