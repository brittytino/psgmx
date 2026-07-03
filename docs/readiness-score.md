# PSGMX — Readiness Score

## Overview

The **Readiness Score** is a single number between 0 and 100 that summarises a student's placement preparation readiness across four measurable dimensions. It is computed automatically by the `compute-readiness-score` Supabase Edge Function whenever any contributing data changes, and is displayed in real time on the Flutter app's home screen gauge.

The score is **not self-reported** and **not gamed by individual actions in isolation**. It requires consistent effort across all four dimensions.

---

## The Four Inputs

| Component | Max Points | Data Source | Updated By |
|---|---|---|---|
| Daily Five | 30 | `daily_five_streaks` | Student (Flutter) |
| LeetCode | 25 | `leetcode_stats.batch_percentile` | Flutter auto-sync (6h) |
| Mock Exams | 35 | `mock_exam_results` | Student (Web) |
| Sessions | 10 | `placement_attendance` | Team Leader (Flutter) |
| **Total** | **100** | | |

---

## Exact Formula

```
-- DAILY FIVE SCORE (max 30 points)
daily_five_score = clamp(
  (running_accuracy_rate × 0.10 × 100) +
  (adherence_rate_last_90_days × 0.20 × 100),
  0, 30
)

  where:
    running_accuracy_rate = total_questions_correct / total_questions_answered
      (stored as a percentage 0–100 in daily_five_streaks.running_accuracy_rate)
    adherence_rate_last_90_days = total_days_completed in last 90 eligible days / 90


-- LEETCODE SCORE (max 25 points)
leetcode_score = clamp(
  batch_percentile × 0.25,
  0, 25
)

  where:
    batch_percentile = rank of this student's batch_weighted_score
                       among all students in the same batch, expressed as 0–100
    batch_weighted_score = batch_easy_solved × 1
                         + batch_medium_solved × 2
                         + batch_hard_solved × 3
    (only problems solved after batch start_date are counted)


-- MOCK EXAM SCORE (max 35 points)
mock_exam_score = clamp(
  weighted_avg_exam_score × 0.35,
  0, 35
)

  where weighted_avg_exam_score is the weighted average of all mock exam results:
    - weight = 1.0  if submitted within the last 30 days
    - weight = 0.7  if submitted 30–90 days ago
    - weight = 0.4  if submitted more than 90 days ago
    - score is 0–100 (normalised percentage, stored in mock_exam_results.score)
    - if no exams taken, mock_exam_score = 0


-- SESSION SCORE (max 10 points)
session_score = clamp(
  (sessions_attended / max(sessions_eligible, 1)) × 10,
  0, 10
)

  where:
    sessions_attended = count of placement_attendance rows
                        WHERE student_id = user_id
                        AND status IN ('present', 'excused')
    sessions_eligible = count of placement_sessions that targeted this student
                        (via batch scope or team scope)


-- TOTAL SCORE
total_score = daily_five_score + leetcode_score + mock_exam_score + session_score
```

---

## Score Bands

The score band is stored as a generated column in `readiness_scores.band` and is used for quick filtering and dashboard visualisation.

| Band | Score Range | Meaning |
|---|---|---|
| `strong` | 80–100 | Well-prepared across all dimensions |
| `building` | 60–79 | Good progress, some gaps to address |
| `needs_attention` | 40–59 | Consistent effort needed |
| `at_risk` | 0–39 | Significant preparation gaps |

---

## Update Latency

The score is recomputed within **60 seconds** of any of the following events:
- Student completes the Daily Five → `daily_five_streaks` updated
- Flutter app syncs LeetCode stats → `leetcode_stats` updated
- Student submits a mock exam → `mock_exam_results` inserted
- Team Leader marks attendance → `placement_attendance` inserted/updated

Database triggers on these four tables invoke the `compute-readiness-score` Edge Function via HTTP POST. The function upserts `readiness_scores` and also writes a daily snapshot to `readiness_score_history` for trend charts.

---

## Who Can See What

| Viewer | What They See |
|---|---|
| Student | Their own total score + all four component scores |
| Team Leader | Their own score only (no access to teammates' breakdown) |
| Coordinator | Their own score only |
| Placement Rep | All students in their batch — total score only |
| Faculty | All students — total score + all component scores |
| HOD | All students across all batches — total score + band |
| Alumni | Their own historical score (no current component breakdown) |

> **Note**: Students cannot see the score breakdown of their peers. Only faculty and HOD have access to the component-level breakdown for all students.

---

## Daily Five Accuracy Rate

`running_accuracy_rate` is stored as a **running calculation** — it is never recomputed from scratch. When a student completes a Daily Five session, the Edge Function receives the count of correct answers for that session (5 answers per session), adds them to `total_questions_correct` and `total_questions_answered`, and recomputes the rate:

```
new_rate = (total_questions_correct + session_correct) /
           (total_questions_answered + 5) × 100
```

This means the accuracy rate reflects all-time performance, not just recent sessions.

---

## LeetCode Batch Percentile Computation

Whenever any student's `leetcode_stats` is updated, the `compute-readiness-score` function also recomputes the `batch_percentile` for **all students in the same batch**, not just the student who triggered the update. This ensures percentiles remain accurate as the batch improves collectively.

Batch percentile is computed as:
```
percentile = (rank - 1) / (total_students - 1) × 100
```
where rank 1 = highest batch_weighted_score. A student at the 80th percentile has outperformed 80% of their batch.
