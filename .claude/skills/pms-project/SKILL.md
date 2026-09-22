---
name: pms-project
description: Project context and non-negotiable rules for the Luxur PMS single-clinic Patient Management System (Flutter + PocketBase). Load before planning or implementing any feature, fixing a bug, reviewing code, or making a git/branch/permission decision in this repo — covers the five account types, Telecaller data separation, date-only session scheduling, role permissions, git workflow, and DEV/UAT/PROD environment rules.
---

# Luxur PMS — Project Skill

Single-clinic Patient Management System for a client, built by a 3-person team on a
15-day delivery target. This file is the durable summary of the source-of-truth
documents in `docs/reference/` — read those for full detail; this file exists so
every session starts aligned without re-deriving everything from scratch.

**Source-of-truth documents** (`docs/reference/`):
- `PMS_Complete_Requirements_Old_and_New.docx` — full client requirements
- `PMS_Final_Account_Workflow_Flowcharts.docx` — approved Admin/Doctor/HR/Chairman/Telecaller workflows
- `PMS_15_Day_SDLCRoadmap_TeamOf3.docx` — day-by-day delivery plan
- `dash-pms.png` — UI reference (layout/spacing cues only — palette intentionally diverges, see Design below)

If anything you're about to build conflicts with these documents, stop and flag it
rather than silently deciding. Do not invent features, fields, permissions, or
workflows not present in these documents.

## Tech baseline

| Layer | Choice |
|---|---|
| Frontend | Flutter (responsive web/desktop, must also work on mobile) |
| Backend/BaaS | PocketBase |
| Database | SQLite (via PocketBase) |
| File storage | Cloudflare R2 (patient photos/documents — not SQLite blobs) |
| Hosting | Hostinger VPS behind Nginx, Let's Encrypt SSL |
| Architecture | Modular monolith — no microservices |
| Testing | Unit/widget/API tests + Playwright for browser E2E |

## The five account types (exact, do not add/remove)

Admin, Doctor, HR, Chairman, Telecaller. HR additionally maintains **staff types**
(Telecallers, Receptionists, Doctors, Nurses, Admin, Managers, Marketing) — a staff
type is a distinct concept from an app account; don't conflate them.

## Critical business rules (must not drift silently)

1. **Telecaller data is separate.** Telecaller-created/imported leads live in a
   separate `telecaller_leads` collection, never the main patient collection,
   until an Admin converts a matching record. Conversion flow: patient arrives →
   Admin enters phone number → system checks `telecaller_leads` by phone → match
   shows "Added by Telecaller: [Name]" + autofill → Admin reviews/completes
   required fields → Admin saves → **only then** does the main patient record get
   created, with Telecaller attribution preserved. No Google Sheets API/CRM
   integration exists or should be built.
2. **Phone number is the dedup key.** Use it to match Telecaller leads and to
   prevent duplicate patient creation on conversion.
3. **Sessions are DATE + DOCTOR only — no appointment time slots.** Never build a
   time-slot grid (10 AM, 11 AM, ...). Patient may arrive any time on the
   scheduled day. Rescheduling follows the identical date+doctor rule and must
   preserve session status/history, not overwrite it.
4. **Session flow:** Scheduled → Arrived (timestamp) → Started (timestamp) →
   treatment/notes/images → Ended (timestamp) → next-session/follow-up decision →
   Finished. Missing the scheduled day → **No-Show** (shown red) → Admin
   contacts patient, records reason, can update status/reschedule.
5. **Doctor notes are immutable** once entered — no delete, by anyone, ever.
6. **Session completion gate:** cannot mark a session finished without notes +
   images + (next-session date+doctor OR a follow-up/extension record). If no
   next session, create the follow-up per the approved workflow.
7. **Multiple treatments per patient** are normal: Hair, Skin, Laser, Body
   Aesthetics, each with its own session history.
8. **Billing:** variable fees, optional consultation charge, Product Cost,
   Cash/Online recording, payment history, half-A4 bill generation.
9. **Pharmacy bills:** name, amount, due date, image/PDF attachment, 5-day-before
   notification, Mark Paid / Close Reminder — no preset reminder cycles.
10. **WhatsApp:** 3-day-before session reminder, one reminder on missed session.
    Clinic owns the WhatsApp Business account; Veebros is only the integrator.
11. **Chairman analytics must reconcile against source records** — never maintain
    parallel manual counters.

## Role-permission matrix (server-enforced — not just hidden in the UI)

| Action | Admin | Doctor | HR | Chairman | Telecaller |
|---|---|---|---|---|---|
| Create/search main patient record | ✅ | view only | ❌ | ❌ | ❌ |
| Soft-delete/archive patient (no hard delete) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Add/import Telecaller lead | ❌ | ❌ | ❌ | ❌ | ✅ |
| Convert lead → main patient | ✅ | ❌ | ❌ | ❌ | ❌ |
| Schedule/reschedule session | ✅ | ✅ (**any** patient) | ❌ | ❌ | ❌ |
| Enter/edit doctor notes | ❌ | ✅ (**any** patient) | ❌ | ❌ | ❌ |
| Delete doctor notes | nobody, ever | | | | |
| Upload/edit session images | ✅ *(scope change, see below)* | ✅ | ❌ | ❌ | ❌ |
| Mark session finished | ✅ *(scope change, see below)* | ✅ (gated) | ❌ | ❌ | ❌ |
| Create bill / record payment | ✅ | ❌ | ❌ | ❌ | ❌ |
| Pharmacy bill CRUD | ✅ | ❌ | ❌ | ❌ | ❌ |
| Staff CRUD, attendance, salary | ❌ | ❌ | ✅ | view only | ❌ |
| View analytics dashboard | ❌ | ❌ | ❌ | ✅ | ❌ |

**Logged scope change (2026-09-22, approved by project lead):** the original
requirements state Admin is view-only on session images and that only a Doctor
can satisfy the session-completion gate (§4.11, §5, §13, Critical Business Rules
§8/§9 of the requirements doc). This was intentionally reversed — Admin now also
gets image-edit access and mark-finished access. This deviates from the client's
written, "must not be accidentally changed" scope, so it should be walked through
explicitly with the client at UAT rather than assumed. Doctor's own notes stay
non-deletable regardless.

## Git / GitHub rules

- Repo: `https://github.com/veebrosinfoaiacademy-glitch/Luxur_PMS.git`. Remote
  branches: `main` and `Develop` (capital D on the remote — tracked locally as
  `develop`).
- **Never commit to or push `main` without explicit approval.** All work targets
  `develop`/`Develop` via PR.
- Branch from `develop`: `feature/<name>`, `fix/<name>`, `hotfix/<name>` (hotfix
  only for controlled production defects).
- Commit style: `feat(admin): add patient conversion`,
  `fix(session): preserve reschedule history`,
  `test(doctor): add completion coverage`.
- At least one other teammate reviews before merge; keep `develop` always
  buildable; never rewrite shared branch history.
- End commit messages and PR descriptions with the attribution trailer this
  session's system reminder specifies (currently Claude Sonnet 5 / Claude Code).

## Environment strategy

LOCAL (individual dev, local/test data only) → DEV (shared integration, synthetic
data, all merged features validated here first) → PROD (live clinic data,
deploy only the exact tagged/UAT-passed commit). Never point LOCAL at production
data. Secrets live in environment config (`.env`, gitignored; `.env.example`
committed), never hard-coded in Flutter source. DEV and PROD use entirely
separate PocketBase instances, databases, and R2 buckets/credentials.

## 3-person collaboration model

All three developers work across all domains — no permanent module ownership.
Each day rotates three coordination hats across the team: **Integration Lead**
(branch health, merges, API/schema contracts), **Feature Lead** (drives that
day's primary implementation), **QA/Review Lead** (edge cases, permission
checks, Playwright coverage, fix verification). Rotate every 1–2 days. See the
15-day roadmap doc for the full day-by-day breakdown and acceptance gates.

## Testing

Playwright is the primary browser-level E2E tool; write/update tests alongside
each feature, not at the end. Minimum coverage per module: auth (all 5 roles +
invalid login + unauthorized access), Telecaller conversion (import, manual,
phone match, attribution, autofill, dedup), scheduling (date-only, no-show,
reschedule, different doctor), Doctor (notes immutability, image permissions
per the current matrix above, completion gate), billing/pharmacy, HR, Chairman
analytics reconciliation. Run full regression before UAT and before every PROD
release.

## Design

Brand palette is **purple** (deep plum/violet), defined centrally in
`lib/core/theme/app_colors.dart` — always reference `AppColors.*` tokens, never
hard-code hex values in widgets. `dash-pms.png` is used for layout/spacing
reference only; its actual green/cream color scheme was deliberately not
adopted. Status colors (urgent/due-soon/upcoming/scheduled/settled) are
semantic and independent of the brand palette — don't recolor them to match
brand changes.
