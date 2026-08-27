# Supabase Dashboard Runbook — Identity Hardening and 26MX

Use this runbook when migrations `00` through `14` have already been executed.

Do **not** rerun `00_reset.sql`; it is destructive and is not required.

## 1. Run migration 15

Open Supabase Dashboard → SQL Editor → New query. Copy and run the complete contents of:

`supabase/migrations/15_identity_batch_team_hardening.sql`

The corrected migration:

- ignores aggregate and window routines while rewriting `auth.uid()` functions;
- runs inside a transaction;
- drops and recreates its policies safely;
- can be rerun after the previous failed attempt;
- preserves existing users, roster rows and operational data.

Expected final notice:

```text
15 complete: dual-email identity, canonical team mapping, batch boundaries, rollout controls.
```

## 2. Run migration 16

Create another SQL Editor query. Copy and run the complete contents of:

`supabase/migrations/16_seed_students_26mx.sql`

Expected final notice:

```text
16_seed_students_26mx.sql complete — 117 rostered, 116 OTP-ready.
```

The file is idempotent. Rerunning it updates the same register numbers and does not create duplicate students.

## 3. Verify the result

Create one final SQL Editor query. Copy and run:

`supabase/verification/17_verify_26mx_setup.sql`

Expected 26MX summary:

- status: `active_junior`;
- rostered students: `117`;
- G1 students: `59`;
- G2 students: `58`;
- OTP-ready students: `116`;
- email-required students: `1`;
- batch-boundary policies: `20`;
- all three identity readiness values: `true`.

The verification file is read-only. If an invariant is missing, it raises a descriptive exception without changing data.

## Files not required

- Do not rerun migrations `00`–`14` if they already completed.
- Do not run files under `supabase/tests` in the production dashboard.
- The only required new write files are migrations `15` and `16`; file `17` is the recommended read-only confirmation.
