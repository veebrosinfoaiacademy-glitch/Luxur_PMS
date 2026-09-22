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
  const lead1 = await upsert(
    "telecaller_leads",
    `phone = "9876543001"`,
    {
      name: "Priya Menon",
      phone: "9876543001",
      address: "Kochi",
      concern: "Laser hair reduction enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
    },
    token,
  );
  await upsert(
    "telecaller_leads",
    `phone = "9876543002"`,
    {
      name: "Arjun Nair",
      phone: "9876543002",
      address: "Ernakulam",
      concern: "Acne treatment enquiry",
      telecaller: accounts.telecaller.id,
      converted: false,
    },
    token,
  );

  // --- patients: one direct, one converted-from-lead ---
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
      assigned_doctor: accounts.doctor.id,
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
      assigned_doctor: accounts.doctor2.id,
      telecaller_lead: lead1.id,
      telecaller: accounts.telecaller.id,
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

  // --- treatments ---
  const treatment1 = await upsert(
    "treatments",
    `patient = "${patientDirect.id}" && treatment_type = "Skin"`,
    {
      patient: patientDirect.id,
      treatment_type: "Skin",
      package_name: "Skin Rejuvenation - 6 sessions",
      sessions_total: 6,
      sessions_remaining: 5,
      consultation_charge: 500,
      status: "Active",
      assigned_doctor: accounts.doctor.id,
      created_by: accounts.admin.id,
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
      sessions_total: 8,
      sessions_remaining: 8,
      consultation_charge: 0,
      status: "Active",
      assigned_doctor: accounts.doctor2.id,
      created_by: accounts.admin.id,
    },
    token,
  );

  // --- sessions: one completed, one scheduled (future), one no-show ---
  await upsert(
    "sessions",
    `patient = "${patientDirect.id}" && status = "completed"`,
    {
      patient: patientDirect.id,
      treatment: treatment1.id,
      doctor: accounts.doctor.id,
      scheduled_date: "2026-09-10 00:00:00",
      status: "completed",
      arrived_at: "2026-09-10 10:05:00",
      started_at: "2026-09-10 10:15:00",
      ended_at: "2026-09-10 10:45:00",
      notes: "Session went well, mild redness expected for 24h.",
      created_by: accounts.doctor.id,
    },
    token,
  );

  await upsert(
    "sessions",
    `patient = "${patientDirect.id}" && status = "scheduled"`,
    {
      patient: patientDirect.id,
      treatment: treatment1.id,
      doctor: accounts.doctor.id,
      scheduled_date: "2026-10-05 00:00:00",
      status: "scheduled",
      created_by: accounts.admin.id,
    },
    token,
  );

  await upsert(
    "sessions",
    `patient = "${patientFromLead.id}" && status = "no_show"`,
    {
      patient: patientFromLead.id,
      treatment: treatment2.id,
      doctor: accounts.doctor2.id,
      scheduled_date: "2026-09-15 00:00:00",
      status: "no_show",
      no_show_reason: "Patient travelling, will call to reschedule",
      created_by: accounts.admin.id,
    },
    token,
  );

  // --- billing ---
  await upsert(
    "bills",
    `patient = "${patientDirect.id}" && bill_number = "BILL-1001"`,
    {
      patient: patientDirect.id,
      treatment: treatment1.id,
      bill_number: "BILL-1001",
      consultation_charge: 500,
      treatment_fee: 3500,
      product_cost: 0,
      total_amount: 4000,
      payment_method: "Cash",
      payment_status: "Paid",
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

  console.log("\nSeed complete. Dev logins (password for all: DevPass123!):");
  for (const role of roles) console.log(`  ${role}: ${role}@luxurpms.local`);
  console.log(`  doctor2: doctor2@luxurpms.local`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
