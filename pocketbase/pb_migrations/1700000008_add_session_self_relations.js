/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const sessions = app.findCollectionByNameOrId("sessions");

  sessions.fields.add(
    // preserves history across a reschedule instead of overwriting the row
    new RelationField({ name: "rescheduled_from", collectionId: sessions.id, maxSelect: 1 }),
    new RelationField({ name: "next_session", collectionId: sessions.id, maxSelect: 1 }),
  );

  return app.save(sessions);
}, (app) => {
  const sessions = app.findCollectionByNameOrId("sessions");
  sessions.fields.removeByName("rescheduled_from");
  sessions.fields.removeByName("next_session");
  return app.save(sessions);
})
