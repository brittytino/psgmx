# PSGMX — User Flows by Role

## First-Year Student (Junior Batch)

A first-year MCA student at PSG Tech is in their first year of the two-year programme. They are assigned to a batch (e.g., `26MX`) when their account is created by the Placement Rep.

**Daily routine (Mobile App)**:
1. Open the Flutter app each morning.
2. Complete the **Daily Five** — five MCQ questions drawn from the question bank. Topics rotate across aptitude, verbal, DSA, DBMS, OS, networks, OOP, Python, Java, and HR behavioural.
3. Their streak increments if they complete by midnight. Missing a day breaks the streak unless they use a **freeze** (2 per month, auto-reset on the 1st).
4. Check their **Readiness Score gauge** on the home screen. The score updates automatically within 60 seconds of any contributing event.
5. View the **daily task** published by their Coordinator — either a LeetCode problem or a core-subject reading.
6. Mark the task complete. The Team Leader verifies completions for their team members.

**At placement sessions**:
- Their Team Leader marks them present, absent, or excused after each session.
- They do not mark their own attendance.

**On the web platform** (less frequent):
- Take mock exams scheduled by faculty. Exams are on a desktop browser only.
- Browse the Knowledge Brain — approved articles and interview experiences from seniors and alumni.
- Chat with the **AI Senior** — an RAG chatbot grounded in the Knowledge Brain.

---

## Second-Year Student (Senior Batch)

A second-year student has all the same daily habits as a junior but with additional responsibilities:

- They can write **placement log entries** — personal accounts of their interview experiences at companies that visited campus. Each entry is submitted for faculty approval before being ingested into the Knowledge Brain.
- Their LeetCode stats include a **batch-period weighted score** that places them on a batch leaderboard. Having a high percentile contributes 25 points to their Readiness Score.
- They have a higher stake in mock exam results — each exam can contribute up to 35 points to their Readiness Score.

On graduation (automatically triggered on June 1st of their final year), they become Alumni.

---

## Team Leader

A Team Leader is a student with the `team_leader` app_role, assigned by the Placement Rep. They are responsible for one team within their batch.

**Key responsibility — attendance marking**:
1. After each placement session, open the Flutter app.
2. Navigate to the session's attendance screen.
3. Mark each team member as Present, Absent, or Excused.
4. Optionally add a note (e.g., "Medical leave — has doctor's note").

**Task verification**:
- Team Leaders can verify task completions submitted by their team members.

A Team Leader retains all the standard student permissions in addition to attendance marking.

---

## Coordinator

A Coordinator is a student with the `coordinator` app_role. They manage the operational logistics for their batch.

**Session scheduling**:
1. Open the Flutter app → Sessions tab.
2. Create a new placement session with a date, time, topic, and target scope (entire batch or specific teams).
3. The session appears in all targeted students' calendars and generates a session reminder notification 1 hour before.

**Task publishing**:
1. Navigate to Tasks → Publish New Task.
2. Choose task type: LeetCode (attach a problem URL) or Core Subject (specify subject, add description).
3. Set the date. One task per type per day per batch.

A Coordinator has all Team Leader permissions plus scheduling and task publishing.

---

## Placement Representative

The Placement Rep is the most privileged student role. There is one Placement Rep per batch.

**Company record management**:
- After a company visits campus, the Placement Rep logs the visit: company name, visit date, roles offered, package band (min and max in LPA), eligibility criteria, and interview rounds.

**Full batch visibility**:
- The Placement Rep can view all student data within their batch, including attendance records for all teams, task completion rates, and individual readiness scores.

**Team management**:
- The Placement Rep creates and configures teams, assigns students to teams, and designates Team Leaders and Coordinators.

The Placement Rep has all Coordinator permissions plus company record management and full batch read/write access.

---

## Faculty

Faculty members use the web platform exclusively. They do not use the Flutter mobile app.

**Mock exam lifecycle**:
1. Create a mock exam: title, description, scheduled time, duration, total marks, proctoring level (Standard or Strict).
2. Add questions: MCQ with four options, short answer, or coding.
3. Publish the exam. Students in the target batch receive an `exam_scheduled` notification.
4. On exam day: the web platform enforces the proctoring level. Faculty can monitor in real time.
5. After exam completion: view all student results, download the report.

**Knowledge Brain moderation**:
- Faculty receive notification when a placement log entry or student article is pending approval.
- They review and approve or reject on the web platform. Approved entries are automatically ingested into the Knowledge Brain with embeddings.

**Mentee roster**:
- Faculty can view a read-only roster of all students in active batches, including their readiness scores, streak status, and mock exam history.

---

## Alumni

Alumni are graduated students. Their role changes automatically on graduation day. They cannot use the Flutter app's placement features but retain access to the web platform.

**Knowledge contribution**:
- Alumni can write articles directly on the Knowledge Brain. Articles are submitted for faculty approval (same workflow as student placement log entries).

**Mentorship**:
- On the alumni dashboard, there is a **Mentorship toggle**. When turned on, `users.mentorship_open = true` and their profile (name, current company, role, LinkedIn) becomes visible to their matched juniors' **"Your Senior"** card in the Flutter app.
- When toggled off (default), they are invisible to juniors.

**Lineage network**:
- Alumni are matched to current students who share the same roll number suffix. For example, a `24MX223` alumni is matched to the `25MX223` and `26MX223` students.
- Matched alumni and their junior students can exchange messages via the lineage message system on the web platform.

**Collaboration marketplace**:
- Alumni can post job opportunities, project collaborations, or mentorship offers. Posts can be scoped to lineage-only, the entire batch, or the whole department.

---

## HOD (Head of Department)

The HOD uses the web platform in a read-only capacity for department oversight. They cannot write any data except their own profile.

**Department overview dashboard**:
- All active batches displayed with aggregate statistics: average readiness score, score band distribution (strong / building / needs attention / at risk), attendance rates, and LeetCode activity.
- Individual student drill-down: the HOD can view any student's complete readiness breakdown.

**Placement outcomes**:
- All company visit records across all batches.
- Aggregate placement statistics: students placed, package bands, company names.

The HOD account is created by invitation via Supabase Auth (not self-signup). Only `@psgtech.ac.in` email addresses are permitted.
