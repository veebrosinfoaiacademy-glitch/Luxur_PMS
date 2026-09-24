// Seeds LOCAL/DEV PocketBase with sample accounts, staff and patient data.
//
// This is intentionally NOT a pb_migrations file: migrations are shared
// through git and applied everywhere (including eventually PROD), but seed
// data must never touch production. Run this manually, on purpose, against
// a local or DEV instance only.
//
// Usage:
//   pocketbase/pocketbase.exe serve   (in one terminal, from pocketbase/)
//   node scripts/seed_dev_data.mjs    (in another terminal, from repo root)
//
// Env vars (all optional, default to local dev values):
//   PB_URL             default http://127.0.0.1:8090
//   PB_SUPERUSER_EMAIL default dev@local.test
//   PB_SUPERUSER_PASS  default DevPass123!

const PB_URL = process.env.PB_URL || "http://127.0.0.1:8090";
const SUPERUSER_EMAIL = process.env.PB_SUPERUSER_EMAIL || "dev@local.test";
const SUPERUSER_PASS = process.env.PB_SUPERUSER_PASS || "DevPass123!";
const DEV_PASSWORD = "DevPass123!";

if (/luxurpms\.in|luxurpms\.com|\.veebros\./.test(PB_URL)) {
  console.error(`Refusing to seed what looks like a production URL: ${PB_URL}`);
  process.exit(1);
}

async function api(path, { method = "GET", body, token } = {}) {
  const res = await fetch(`${PB_URL}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`${method} ${path} -> ${res.status}: ${JSON.stringify(data)}`);
  }
  return data;
}

async function findByFilter(collection, filter, token) {
  const q = new URLSearchParams({ filter, perPage: "1" });
  const data = await api(`/api/collections/${collection}/records?${q}`, { token });
  return data.items?.[0] || null;
}

async function upsert(collection, filter, payload, token) {
  const existing = await findByFilter(collection, filter, token);
  if (existing) {
    return api(`/api/collections/${collection}/records/${existing.id}`, {
      method: "PATCH",
      body: payload,
      token,
    });
  }
  return api(`/api/collections/${collection}/records`, {
    method: "POST",
    body: payload,
    token,
  });
}

async function main() {
  console.log(`Seeding ${PB_URL} as ${SUPERUSER_EMAIL} ...`);

  const auth = await api("/api/collections/_superusers/auth-with-password", {
    method: "POST",
    body: { identity: SUPERUSER_EMAIL, password: SUPERUSER_PASS },
  });
  const token = auth.token;

  // --- one login account per role, for auth/permission testing ---
  const roles = ["admin", "doctor", "hr", "chairman", "telecaller"];
  const accounts = {};
  for (const role of roles) {
    const email = `${role}@luxurpms.local`;
    accounts[role] = await upsert(
      "users",
      `email = "${email}"`,
      {
        email,
        password: DEV_PASSWORD,
        passwordConfirm: DEV_PASSWORD,
        name: `Dev ${role[0].toUpperCase()}${role.slice(1)}`,
        role,
        active: true,
        verified: true,
      },
      token,
    );
    console.log(`  account: ${email}`);
  }

  // --- a second doctor, to exercise "any doctor can act on any patient" ---
  accounts.doctor2 = await upsert(
    "users",
    `email = "doctor2@luxurpms.local"`,
    {
      email: "doctor2@luxurpms.local",
      password: DEV_PASSWORD,
      passwordConfirm: DEV_PASSWORD,
      name: "Dev Doctor Two",
      role: "doctor",
      active: true,
      verified: true,
    },
    token,
  );

  // --- staff records ---
  const staffSeed = [
    { name: "Dev Admin", staff_type: "Admin", phone: "9000000001", email: "admin@luxurpms.local" },
    { name: "Dev Doctor", staff_type: "Doctor", phone: "9000000002", email: "doctor@luxurpms.local" },
    { name: "Dev Doctor Two", staff_type: "Doctor", phone: "9000000003", email: "doctor2@luxurpms.local" },
    { name: "Dev HR", staff_type: "Admin", phone: "9000000004", email: "hr@luxurpms.local" },
    { name: "Dev Telecaller", staff_type: "Telecaller", phone: "9000000005", email: "telecaller@luxurpms.local" },
    { name: "Sample Receptionist", staff_type: "Receptionist", phone: "9000000006", email: "reception@luxurpms.local" },
  ];
  const staff = {};
  for (const s of staffSeed) {
    staff[s.email] = await upsert("staff", `email = "${s.email}"`, { ...s, active: true, joined_date: "2026-01-01" }, token);
  }

  // --- telecaller leads (separate table, not yet converted) ---
  // expected_arrival_date is computed relative to "now" (unlike the mostly-
  // fixed dates elsewhere in this file) so the four Follow-Up scenarios
  // below stay correct no matter which day this script is actually run —
  // see lib/features/telecaller/utils/follow_up.dart for the rule this
  // data is exercising.
  const isoDateDaysFromNow = (days) => {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() + days);
    return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`;
  };

  const lead1 = await upsert(
    "telecaller_leads",
    `phone = "9876543001"`,
    {
      // Scenario 4: already converted — must never show in Follow-Up,
      // regardless of how far in the past its expected arrival date is.
      name: "Priya Menon",
      phone: "9876543001",
      address: "Kochi",
      concern: "Laser hair reduction enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
      expected_arrival_date: isoDateDaysFromNow(-20),
    },
    token,
  );
  await upsert(
    "telecaller_leads",
    `phone = "9876543002"`,
    {
      // Scenario 3: past expected arrival, not converted — DOES show in
      // Follow-Up.
      name: "Arjun Nair",
      phone: "9876543002",
      address: "Ernakulam",
      concern: "Acne treatment enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
      expected_arrival_date: isoDateDaysFromNow(-3),
    },
    token,
  );
  await upsert(
    "telecaller_leads",
    `phone = "9876543003"`,
    {
      // Scenario 2: expected today — NOT yet overdue, must NOT show in
      // Follow-Up (only becomes eligible the day after).
      name: "Maya Pillai",
      phone: "9876543003",
      address: "Thrissur",
      concern: "Consultation enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
      expected_arrival_date: isoDateDaysFromNow(0),
    },
    token,
  );
  await upsert(
    "telecaller_leads",
    `phone = "9876543004"`,
    {
      // Scenario 1: future expected arrival — must NOT show in Follow-Up.
      name: "Rahul Krishnan",
      phone: "9876543004",
      address: "Kozhikode",
      concern: "Hair transplant enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
      expected_arrival_date: isoDateDaysFromNow(5),
    },
    token,
  );

  // --- treatment plans (Admin Settings configuration) ---
  // These are what a doctor picks from when recommending a treatment. One
  // is deactivated on purpose: it must stay out of new selections while the
  // treatment below that was sold under it keeps its name.
  const planSeed = [
    { category: "Skin", name: "Skin Rejuvenation - 6 sessions", active: true },
    { category: "Skin", name: "Chemical Peel - 3 sessions", active: true },
    { category: "Laser", name: "Laser Hair Reduction - 8 sessions", active: true },
    { category: "Hair", name: "Hair PRP - 6 sessions", active: true },
    { category: "Hair", name: "Hair PRP - legacy pricing", active: false },
    { category: "Body Aesthetics", name: "Body Contouring - 4 sessions", active: true },
  ];
  for (const plan of planSeed) {
    await upsert(
      "treatment_plans",
      `category = "${plan.category}" && name = "${plan.name}"`,
      { ...plan, created_by: accounts.admin.id },
      token,
    );
  }

  // --- patients ---
  // Note there is deliberately no assigned_doctor on any patient: doctor
  // attribution lives on each consultation and session instead.
  const patientDirect = await upsert(
    "patients",
    `patient_code = "PT-1001"`,
    {
      patient_code: "PT-1001",
      name: "Sneha Varghese",
      age: 29,
      gender: "Female",
      phone: "9876543010",
      address: "Kakkanad",
      source: "Direct Walk-in",
      concern: "Skin rejuvenation",
      status: "Joined",
      archived: false,
      created_by: accounts.admin.id,
    },
    token,
  );

  const patientFromLead = await upsert(
    "patients",
    `patient_code = "PT-1002"`,
    {
      patient_code: "PT-1002",
      name: lead1.name,
      phone: lead1.phone,
      address: lead1.address,
      source: "Telecalling",
      concern: lead1.concern,
      telecaller_lead: lead1.id,
      telecaller: accounts.telecaller.id,
      status: "Joined",
      archived: false,
      created_by: accounts.admin.id,
    },
    token,
  );

  // Registered today and not yet seen — this is the patient who should sit
  // at the top of the Doctor's "Today's Patients", waiting for consultation.
  const patientWaiting = await upsert(
    "patients",
    `patient_code = "PT-1003"`,
    {
      patient_code: "PT-1003",
      name: "Rahul Menon",
      age: 34,
      gender: "Male",
      phone: "9876543011",
      address: "Panampilly Nagar",
      source: "Google Ad",
      concern: "Hair fall",
      status: "Joined",
      archived: false,
      created_by: accounts.admin.id,
    },
    token,
  );
  await api(`/api/collections/telecaller_leads/records/${lead1.id}`, {
    method: "PATCH",
    body: { converted: true, converted_patient: patientFromLead.id },
    token,
  });

  // --- consultations ---
  // Each one records WHICH doctor saw the patient; the patient stays
  // unattached to any doctor.
  const consultation1 = await upsert(
    "consultations",
    `patient = "${patientDirect.id}"`,
    {
      patient: patientDirect.id,
      doctor: accounts.doctor.id,
      reason_for_visit: "Dull skin, uneven tone",
      notes: "Advised a rejuvenation course. No contraindications.",
      recommendation: "Recommend Treatment",
      consultation_fee: 500,
      suggested_product: "Vitamin C serum",
      status: "completed",
      created_by: accounts.doctor.id,
    },
    token,
  );

  // The second patient was seen by the OTHER doctor — deliberately, to show
  // that two doctors can treat the same clinic's patients freely.
  const consultation2 = await upsert(
    "consultations",
    `patient = "${patientFromLead.id}"`,
    {
      patient: patientFromLead.id,
      doctor: accounts.doctor2.id,
      reason_for_visit: "Laser hair reduction enquiry",
      notes: "Suitable for laser; started on a full course.",
      recommendation: "Recommend Treatment",
      status: "completed",
      created_by: accounts.doctor2.id,
    },
    token,
  );

  // --- treatments ---
  // package_cost is the denominator of the progress bar; sessions_total is
  // optional and deliberately left off treatment2.
  const treatment1 = await upsert(
    "treatments",
    `patient = "${patientDirect.id}" && treatment_type = "Skin"`,
    {
      patient: patientDirect.id,
      treatment_type: "Skin",
      package_name: "Skin Rejuvenation - 6 sessions",
      package_cost: 50000,
      sessions_total: 6,
      sessions_remaining: 5,
      consultation: consultation1.id,
      status: "Active",
      created_by: accounts.doctor.id,
    },
    token,
  );

  const treatment2 = await upsert(
    "treatments",
    `patient = "${patientFromLead.id}" && treatment_type = "Laser"`,
    {
      patient: patientFromLead.id,
      treatment_type: "Laser",
      package_name: "Laser Hair Reduction - 8 sessions",
      package_cost: 40000,
      consultation: consultation2.id,
      status: "Active",
      created_by: accounts.doctor2.id,
    },
    token,
  );

  // --- sessions ---
  // Dates are relative to "now" so the dashboard always has a real day to
  // show, whichever day this script is run. There is no started_at: the
  // workflow has no Start Session step.
  const isoDateTimeDaysFromNow = (days) => `${isoDateDaysFromNow(days)} 00:00:00`;

  const sessionDone = await upsert(
    "sessions",
    `patient = "${patientDirect.id}" && status = "completed"`,
    {
      patient: patientDirect.id,
      treatment: treatment1.id,
      doctor: accounts.doctor.id,
      scheduled_date: isoDateTimeDaysFromNow(-14),
      status: "completed",
      notes: "Session went well, mild redness expected for 24h.",
      created_by: accounts.doctor.id,
    },
    token,
  );

  // Today, already arrived — appears under "Waiting for Session".
  await upsert(
    "sessions",
    `patient = "${patientDirect.id}" && status = "arrived"`,
    {
      patient: patientDirect.id,
      treatment: treatment1.id,
      scheduled_date: isoDateTimeDaysFromNow(0),
      status: "arrived",
      created_by: accounts.admin.id,
    },
    token,
  );

  // Today, unassigned and not yet arrived — the front desk's "Patient
  // Arrived" button acts on this one.
  const sessionToday = await upsert(
    "sessions",
    `patient = "${patientFromLead.id}" && status = "scheduled" && scheduled_date >= "${isoDateTimeDaysFromNow(0)}"`,
    {
      patient: patientFromLead.id,
      treatment: treatment2.id,
      scheduled_date: isoDateTimeDaysFromNow(0),
      status: "scheduled",
      created_by: accounts.admin.id,
    },
    token,
  );

  // Missed — drives the red no-show section and its Call button.
  await upsert(
    "sessions",
    `patient = "${patientFromLead.id}" && status = "no_show"`,
    {
      patient: patientFromLead.id,
      treatment: treatment2.id,
      scheduled_date: isoDateTimeDaysFromNow(-4),
      status: "no_show",
      no_show_reason: "Patient travelling, will call to reschedule",
      created_by: accounts.admin.id,
    },
    token,
  );

  // --- billing ---
  // Consultation billing and session billing are separate documents. Every
  // amount is written explicitly, including the zeroes, so re-running this
  // script normalizes a bill left over from an earlier shape.
  //
  // Bills are seeded UNPAID and then settled through a second write, the
  // same way "Patient Paid" does it — that is what gets paid_at stamped by
  // pb_hooks/bills_payment.pb.js instead of faked here.
  const emptyAmounts = {
    consultation_charge: 0,
    treatment_fee: 0,
    product_name: "",
    product_cost: 0,
  };

  const settle = async (bill) => {
    if (bill.payment_status === "Paid" && bill.paid_at) return;
    await api(`/api/collections/bills/records/${bill.id}`, {
      method: "PATCH",
      body: { payment_status: "Paid" },
      token,
    });
  };

  const consultationBill = await upsert(
    "bills",
    `patient = "${patientDirect.id}" && bill_number = "BILL-1001"`,
    {
      ...emptyAmounts,
      patient: patientDirect.id,
      consultation: consultation1.id,
      session: "",
      treatment: "",
      bill_number: "BILL-1001",
      consultation_charge: 500,
      total_amount: 500,
      payment_method: "Cash",
      payment_status: "Pending",
      created_by: accounts.admin.id,
    },
    token,
  );
  await settle(consultationBill);

  // A PAID session bill: ₹10,000 of the ₹50,000 package, so the progress
  // bar reads 20%. The ₹850 product on it is billed but excluded from that.
  const paidSessionBill = await upsert(
    "bills",
    `patient = "${patientDirect.id}" && bill_number = "BILL-1002"`,
    {
      ...emptyAmounts,
      patient: patientDirect.id,
      consultation: "",
      session: sessionDone.id,
      treatment: treatment1.id,
      bill_number: "BILL-1002",
      treatment_fee: 10000,
      product_name: "Vitamin C serum",
      product_cost: 850,
      total_amount: 10850,
      payment_method: "Cash",
      payment_status: "Pending",
      created_by: accounts.admin.id,
    },
    token,
  );
  await settle(paidSessionBill);

  // Generated but NOT paid — contributes nothing to treatment progress
  // until Admin records "Patient Paid".
  await upsert(
    "bills",
    `patient = "${patientFromLead.id}" && bill_number = "BILL-1003"`,
    {
      ...emptyAmounts,
      patient: patientFromLead.id,
      consultation: "",
      session: sessionToday.id,
      treatment: treatment2.id,
      bill_number: "BILL-1003",
      treatment_fee: 5000,
      total_amount: 5000,
      payment_method: "Online",
      payment_status: "Pending",
      created_by: accounts.admin.id,
    },
    token,
  );

  await upsert(
    "pharmacy_bills",
    `patient = "${patientDirect.id}" && pharmacy_name = "City Pharmacy"`,
    {
      patient: patientDirect.id,
      pharmacy_name: "City Pharmacy",
      amount: 850,
      due_date: "2026-10-01 00:00:00",
      status: "Pending",
      reminder_closed: false,
      created_by: accounts.admin.id,
    },
    token,
  );

  // --- HR records ---
  await upsert(
    "attendance",
    `staff = "${staff["doctor@luxurpms.local"].id}" && date = "2026-09-22 00:00:00"`,
    {
      staff: staff["doctor@luxurpms.local"].id,
      date: "2026-09-22 00:00:00",
      check_in: "2026-09-22 09:00:00",
      check_out: "2026-09-22 18:00:00",
      source: "manual",
    },
    token,
  );

  await upsert(
    "salary_records",
    `staff = "${staff["doctor@luxurpms.local"].id}" && month = "2026-08"`,
    {
      staff: staff["doctor@luxurpms.local"].id,
      month: "2026-08",
      amount: 60000,
      paid_on: "2026-09-01 00:00:00",
    },
    token,
  );

  console.log(
    `\nToday's Schedule will show: ${patientWaiting.name} waiting for consultation, ` +
      `${patientDirect.name} waiting for a session, and ${patientFromLead.name} yet to arrive.`,
  );
  console.log("\nSeed complete. Dev logins (password for all: DevPass123!):");
  for (const role of roles) console.log(`  ${role}: ${role}@luxurpms.local`);
  console.log(`  doctor2: doctor2@luxurpms.local`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
