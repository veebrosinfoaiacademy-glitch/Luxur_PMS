/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const leads = app.findCollectionByNameOrId("telecaller_leads");

  // Date-only (no appointment time) — when the patient is expected to visit
  // the clinic. Drives Follow-Up eligibility (see follow_up.dart); not
  // required at the schema level because the existing Excel/CSV bulk-import
  // path has no source column for it and must keep working.
  leads.fields.add(new DateField({
    name: "expected_arrival_date",
  }));

  return app.save(leads);
}, (app) => {
  const leads = app.findCollectionByNameOrId("telecaller_leads");
  leads.fields.removeByName("expected_arrival_date");
  return app.save(leads);
})
