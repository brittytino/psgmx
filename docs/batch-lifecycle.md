# PSGMX — Batch Lifecycle

## What is a Batch?

A **batch** is one MCA intake cohort. It is identified by a two-year batch code in the format `[year-digits]MX` — for example, `25MX` represents students who started in 2025. The MCA programme is two years long, so each batch spans from approximately June of year 1 to June of year 2.

Every student belongs to exactly one batch. Faculty and the HOD are not assigned to a batch.

---

## Batch Creation

A batch is created in the `batches` table by the system administrator (HOD or a super-admin). Creating a batch does not automatically enrol any students — students are added to the batch when their user accounts are created.

```sql
INSERT INTO batches (batch_code, start_date, end_date, status)
VALUES ('26MX', '2026-06-01', '2028-06-30', 'active_junior');
```

Fields:
- `batch_code`: Unique identifier (e.g., `26MX`)
- `start_date`: First day of the programme (typically June 1st of intake year)
- `end_date`: Last day of the programme (typically June 30th two years later)
- `status`: One of `active_junior`, `active_senior`, `graduated`

---

## Two Active Statuses

At any time, PSG Tech MCA has at most two active batches simultaneously:
- **`active_junior`**: The first-year cohort (currently in their first year of study)
- **`active_senior`**: The second-year cohort (in their final year, actively participating in placements)

When a new batch joins (June of year 1), the existing junior batch becomes the senior batch:

```
Before new intake:   25MX = active_senior,  (no junior)
After new intake:    25MX = active_senior,  26MX = active_junior
```

The status promotion from `active_junior` to `active_senior` happens inside the `batch-graduation` Edge Function when the senior batch graduates.

---

## Graduation

### Trigger

The `batch-graduation` Edge Function runs on a CRON schedule: **midnight on June 1st** (`0 0 1 6 *`). It is also invocable manually (e.g., for testing).

### Transaction Steps

When the function runs, it executes the following steps **atomically** (all succeed or all roll back):

1. **Find graduating batches**: Query `batches` where `status != 'graduated'` and `end_date <= CURRENT_DATE`.
2. **Graduate each batch**: Set `batches.status = 'graduated'` for each qualifying batch.
3. **Convert students to alumni**: For every user in each graduating batch, set `role = 'alumni'` and `app_role = 'student'`. (Alumni have no placement app_role.)
4. **Send graduation notifications**: Insert a `notifications` row of type `'graduation'` for every user in the graduating batch.
5. **Promote the junior batch**: Find the most recently created batch with `status = 'active_junior'`. Set it to `active_senior`.
6. **Audit log**: Write a row to `audit_logs` recording the batch codes that graduated and the number of users transitioned.

### What Happens to Each User on Graduation

| User type | `role` before | `role` after | `app_role` after | Effect |
|---|---|---|---|---|
| Student | `student` | `alumni` | `student` | Can no longer access placement features; gains alumni features |
| Team Leader | `student` | `alumni` | `student` | Team leadership role is cleared |
| Coordinator | `student` | `alumni` | `student` | Coordinator role is cleared |
| Placement Rep | `student` | `alumni` | `student` | All elevated permissions cleared |

### Alumni Defaults on Graduation

- `mentorship_open = false` — Alumni must actively opt in to mentorship. This is enforced by a database trigger (Trigger 7) that sets `mentorship_open = false` whenever `role` changes to `'alumni'`.
- The alumni's Flutter app shows the **Graduation Screen** on next open — displaying their final readiness score, longest streak, and LeetCode batch score. After tapping through, the app shows a read-only archive home screen.

---

## Lineage and Alumni Matching

When a student's user account is created (Trigger 6 — after `INSERT` on `users`), the database automatically builds lineage relationships. The process:

1. Extract the numeric suffix from the new user's `roll_no`. For example, `25MX223` → suffix = `223`.
2. Search the `users` table for other users whose `roll_no` ends in `MX223` but belongs to a prior batch.
3. For each match found (e.g., `24MX223`), insert a row into `lineage_map`:
   ```
   junior_user_id = new user (25MX223)
   senior_user_id = matched user (24MX223)
   roll_suffix = '223'
   ```

This means that when `24MX223` graduates and becomes an alumni, they are already linked to `25MX223` and `26MX223` in the lineage map. If the alumni enables mentorship, the junior students will see the **"Your Senior"** card in the Flutter app.

---

## Historical Data Retention

Graduated batches are **never deleted**. All data — readiness scores, attendance, exam results, placement log entries — is permanently retained. The HOD can view historical batch statistics for any past cohort.

The `readiness_score_history` table stores a daily snapshot per student, making it possible to chart how the entire batch's readiness evolved over the two-year programme.
