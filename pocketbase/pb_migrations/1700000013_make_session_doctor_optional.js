/// <reference path="../pb_data/types.d.ts" />

// A session's doctor is OPTIONAL at scheduling and at arrival: Admin may
// assign one or leave it unassigned for any authorized doctor to pick up,
// and the doctor who completes an unassigned session becomes that
// session's doctor (see pb_hooks/sessions_workflow.pb.js). The original
// `required: true` on `doctor` contradicted that.
//
// There is deliberately no permanent patient -> doctor relationship;
// attribution lives on each clinical record (consultation / session).
migrate((app) => {
  const sessions = app.findCollectionByNameOrId("sessions");
  const doctorField = sessions.fields.getByName("doctor");
  doctorField.required = false;
  return app.save(sessions);
}, (app) => {
  const sessions = app.findCollectionByNameOrId("sessions");
  const doctorField = sessions.fields.getByName("doctor");
  doctorField.required = true;
  return app.save(sessions);
})
