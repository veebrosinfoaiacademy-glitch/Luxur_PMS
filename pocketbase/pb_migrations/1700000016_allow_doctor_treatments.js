/// Treatments are created by the DOCTOR, not the Admin.
///
/// A treatment record is born inside the consultation: when the doctor
/// picks "Recommend Treatment" they choose the category and plan and enter
/// the package cost, so the create/update rules have to admit the doctor
/// role the same way `consultations` and `sessions` already do. Reading
/// stays as it was.
migrate(
  (app) => {
    const treatments = app.findCollectionByNameOrId('treatments');
    treatments.createRule =
      '@request.auth.role = "admin" || @request.auth.role = "doctor"';
    treatments.updateRule =
      '@request.auth.role = "admin" || @request.auth.role = "doctor"';
    app.save(treatments);
  },
  (app) => {
    const treatments = app.findCollectionByNameOrId('treatments');
    treatments.createRule = '@request.auth.role = "admin"';
    treatments.updateRule = '@request.auth.role = "admin"';
    app.save(treatments);
  },
);
