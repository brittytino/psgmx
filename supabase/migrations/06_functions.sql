-- ============================================================
-- PSGMX — 06_functions.sql
-- ============================================================
-- Every Postgres function used by RLS policies (08_rls_policies.sql),
-- triggers (07_triggers.sql), or called directly by the apps via
-- supabase.rpc(...). Names and parameter names are matched 1:1 against
-- what apps/web and apps/mobile actually call.
--
-- Run AFTER 05_schema_misc.sql.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Role / permission helpers
-- ──────────────────────────────────────────────────────────────

-- Enable pgcrypto extension for pgp_sym_decrypt
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION has_role(user_id UUID, role_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_roles JSONB;
BEGIN
    SELECT roles INTO user_roles FROM users WHERE id = user_id;
    RETURN COALESCE((user_roles->>role_name)::BOOLEAN, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_placement_rep(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isPlacementRep');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_coordinator(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isCoordinator');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_team_leader(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN has_role(user_id, 'isTeamLeader');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_team(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_team TEXT;
BEGIN
    SELECT team_id INTO user_team FROM users WHERE id = user_id;
    RETURN user_team;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_batch_id(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_batch_id UUID;
BEGIN
    SELECT batch_id INTO v_batch_id FROM users WHERE id = p_user_id LIMIT 1;
    RETURN v_batch_id;
END;
$$;

-- Fine-grained capability check (user_permissions table).
CREATE OR REPLACE FUNCTION user_has_permission(p_user_id UUID, p_key TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_permissions
        WHERE user_id = p_user_id AND permission_key = p_key
    );
END;
$$;

-- role_label-based check, mirrors apps/web/lib/auth.ts's isFacultyOrHod().
CREATE OR REPLACE FUNCTION is_faculty_or_hod(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users WHERE id = p_user_id AND role_label IN ('Faculty', 'HOD')
    );
END;
$$;

CREATE OR REPLACE FUNCTION is_hod(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND role_label = 'HOD');
$$;

-- ──────────────────────────────────────────────────────────────
-- Scheduling helpers
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION is_date_scheduled(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM scheduled_attendance_dates WHERE date = check_date);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_scheduled_dates(start_date DATE, end_date DATE)
RETURNS TABLE (
    id UUID, date DATE, scheduled_by UUID, notes TEXT,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT sad.id, sad.date, sad.scheduled_by, sad.notes, sad.created_at, sad.updated_at
    FROM scheduled_attendance_dates sad
    WHERE sad.date >= start_date AND sad.date <= end_date
    ORDER BY sad.date ASC;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_team_task_completion_stats(p_team_id TEXT, p_date DATE)
RETURNS TABLE (total_members INT, completed_count INT, completion_percentage NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(u.id)::int AS total_members,
        SUM(CASE WHEN tc.completed THEN 1 ELSE 0 END)::int AS completed_count,
        CASE WHEN COUNT(u.id) = 0 THEN 0
             ELSE ROUND(SUM(CASE WHEN tc.completed THEN 1 ELSE 0 END)::numeric / COUNT(u.id) * 100, 2)
        END AS completion_percentage
    FROM users u
    LEFT JOIN task_completions tc ON tc.user_id = u.id AND tc.task_date = p_date
    WHERE u.team_id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Per-student attendance for one team on one date (mobile team-leader screen).
CREATE OR REPLACE FUNCTION get_team_attendance_for_date(check_date DATE, check_team_id TEXT)
RETURNS TABLE (user_id UUID, name TEXT, reg_no TEXT, status TEXT)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.name, u.reg_no, COALESCE(ar.status, 'NOT_MARKED')
    FROM users u
    LEFT JOIN attendance_records ar ON ar.user_id = u.id AND ar.date = check_date
    WHERE u.team_id = check_team_id
    ORDER BY u.name;
END;
$$;

-- Current consecutive-present streak for a student, counting back from the
-- most recent scheduled working day.
CREATE OR REPLACE FUNCTION calculate_attendance_streak(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_streak INTEGER := 0;
    v_date   RECORD;
BEGIN
    FOR v_date IN
        SELECT sad.date FROM scheduled_attendance_dates sad
        WHERE sad.is_working_day = true AND sad.date <= CURRENT_DATE
        ORDER BY sad.date DESC
    LOOP
        IF EXISTS (
            SELECT 1 FROM attendance_records ar
            WHERE ar.user_id = p_user_id AND ar.date = v_date.date AND ar.status = 'PRESENT'
        ) THEN
            v_streak := v_streak + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    RETURN v_streak;
END;
$$;

-- Scans every student, flags/unflags defaulter_flags based on overall
-- attendance % (student_attendance_summary) and trailing consecutive
-- absences. Returns the number of students newly flagged as defaulters.
CREATE OR REPLACE FUNCTION check_and_flag_defaulters(p_threshold NUMERIC, p_consecutive_days INT)
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user          RECORD;
    v_date          RECORD;
    v_consecutive   INTEGER;
    v_flagged_count INTEGER := 0;
    v_reason        TEXT;
BEGIN
    FOR v_user IN
        SELECT student_id AS user_id, attendance_percentage
        FROM student_attendance_summary
        WHERE student_id IS NOT NULL
    LOOP
        v_consecutive := 0;
        FOR v_date IN
            SELECT sad.date FROM scheduled_attendance_dates sad
            WHERE sad.is_working_day = true AND sad.date <= CURRENT_DATE
            ORDER BY sad.date DESC
        LOOP
            IF EXISTS (
                SELECT 1 FROM attendance_records ar
                WHERE ar.user_id = v_user.user_id AND ar.date = v_date.date AND ar.status = 'ABSENT'
            ) THEN
                v_consecutive := v_consecutive + 1;
            ELSE
                EXIT;
            END IF;
        END LOOP;

        IF v_user.attendance_percentage < p_threshold OR v_consecutive >= p_consecutive_days THEN
            v_reason := CASE
                WHEN v_consecutive >= p_consecutive_days THEN format('%s consecutive absences', v_consecutive)
                ELSE format('Attendance %s%% below threshold %s%%', v_user.attendance_percentage, p_threshold)
            END;

            INSERT INTO defaulter_flags (user_id, defaulter_status, defaulter_reason, consecutive_absences, attendance_percentage, detected_at)
            VALUES (v_user.user_id, true, v_reason, v_consecutive, v_user.attendance_percentage, now())
            ON CONFLICT (user_id) DO UPDATE SET
                defaulter_status      = true,
                defaulter_reason      = EXCLUDED.defaulter_reason,
                consecutive_absences  = EXCLUDED.consecutive_absences,
                attendance_percentage = EXCLUDED.attendance_percentage,
                detected_at           = now(),
                updated_at            = now();

            v_flagged_count := v_flagged_count + 1;
        ELSE
            UPDATE defaulter_flags SET defaulter_status = false, resolved_at = now(), updated_at = now()
            WHERE user_id = v_user.user_id AND defaulter_status = true;
        END IF;
    END LOOP;

    RETURN v_flagged_count;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- LeetCode
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_leetcode_username_unified(p_user_id UUID, p_new_username TEXT)
RETURNS VOID AS $$
DECLARE
    v_old_username TEXT;
    v_email TEXT;
BEGIN
    SELECT leetcode_username, email INTO v_old_username, v_email FROM users WHERE id = p_user_id;
    p_new_username := TRIM(p_new_username);

    UPDATE users SET leetcode_username = p_new_username, updated_at = NOW() WHERE id = p_user_id;

    IF v_email IS NOT NULL THEN
        UPDATE whitelist SET leetcode_username = p_new_username WHERE email = v_email;
    END IF;

    IF v_old_username IS NOT NULL AND v_old_username != p_new_username THEN
        IF EXISTS (SELECT 1 FROM leetcode_stats WHERE username = v_old_username) THEN
            IF EXISTS (SELECT 1 FROM leetcode_stats WHERE username = p_new_username) THEN
                DELETE FROM leetcode_stats WHERE username = v_old_username;
            ELSE
                UPDATE leetcode_stats SET username = p_new_username, last_updated = NOW() WHERE username = v_old_username;
            END IF;
        END IF;
    END IF;

    INSERT INTO leetcode_stats (username, total_solved, easy_solved, medium_solved, hard_solved)
    VALUES (p_new_username, 0, 0, 0, 0)
    ON CONFLICT (username) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rate-limited variant (max 1 change / 30 days) — anti-cheat hardening.
CREATE OR REPLACE FUNCTION update_leetcode_username_rate_limited(p_user_id UUID, p_new_username TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_last_changed TIMESTAMPTZ;
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Not authenticated as this user';
    END IF;

    SELECT ls.username_last_changed_at INTO v_last_changed
    FROM users u JOIN leetcode_stats ls ON ls.username = u.leetcode_username
    WHERE u.id = p_user_id;

    IF v_last_changed IS NOT NULL AND v_last_changed > now() - INTERVAL '30 days' THEN
        RAISE EXCEPTION 'LeetCode username can only be changed once every 30 days (last changed %)', v_last_changed;
    END IF;

    PERFORM update_leetcode_username_unified(p_user_id, p_new_username);
    UPDATE leetcode_stats SET username_last_changed_at = now() WHERE username = p_new_username;
END;
$$;

CREATE OR REPLACE FUNCTION _flag_leetcode_anomaly()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.total_solved IS NOT NULL
       AND NEW.total_solved - OLD.total_solved > 50
       AND NEW.last_updated - OLD.last_updated < INTERVAL '2 days' THEN
        NEW.flagged := true;
        NEW.flag_reason := format(
            'Jumped from %s to %s solved (+%s) between %s and %s',
            OLD.total_solved, NEW.total_solved, NEW.total_solved - OLD.total_solved,
            OLD.last_updated, NEW.last_updated
        );
    END IF;
    RETURN NEW;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Maintenance / notification trigger functions
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION update_app_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_new_daily_task()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (title, message, notification_type, tone, target_audience, created_by)
    VALUES (
        'New Task Added: ' || NEW.title,
        'A new ' || NEW.topic_type || ' task has been posted for ' || NEW.date || '. Check it out now!',
        'alert', 'friendly', 'all', NEW.uploaded_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_attendance_schedule()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (title, message, notification_type, tone, target_audience, created_by)
    VALUES (
        'Attendance Scheduled',
        'Attendance marking has been scheduled for ' || NEW.date || '. Team Leaders, please be ready.',
        'reminder', 'serious', 'team_leaders', NEW.scheduled_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION notify_leetcode_milestone()
RETURNS TRIGGER AS $$
DECLARE
    milestone INT := 50;
    old_milestone INT;
    new_milestone INT;
    display_name TEXT;
BEGIN
    old_milestone := OLD.total_solved / milestone;
    new_milestone := NEW.total_solved / milestone;

    IF new_milestone > old_milestone THEN
        SELECT name INTO display_name FROM users WHERE leetcode_username = NEW.username LIMIT 1;
        IF display_name IS NULL THEN
            display_name := NEW.username;
        END IF;

        INSERT INTO notifications (title, message, notification_type, tone, target_audience, created_by)
        VALUES (
            '🏆 New Milestone Reached!',
            display_name || ' has just solved ' || NEW.total_solved || ' problems! Keep it up!',
            'motivation', 'friendly', 'all', NULL
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Whitelist → users on first OTP login. This is the ONLY correct way to
-- populate `users` — never gen_random_uuid(), always the real auth UUID.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    wl RECORD;
BEGIN
    SELECT * INTO wl FROM public.whitelist WHERE email = NEW.email;

    IF wl IS NOT NULL THEN
        INSERT INTO public.users (
            id, email, reg_no, reg_no_is_placeholder, name, team_id, batch, batch_id, gender, roles,
            leetcode_username, dob,
            birthday_notifications_enabled, leetcode_notifications_enabled,
            task_reminders_enabled, attendance_alerts_enabled, announcements_enabled
        ) VALUES (
            NEW.id, NEW.email, wl.reg_no, COALESCE(wl.reg_no_is_placeholder, false), wl.name, wl.team_id,
            COALESCE(wl.batch, 'G1'), wl.batch_id, wl.gender,
            COALESCE(wl.roles, '{"isStudent": true, "isTeamLeader": false, "isCoordinator": false, "isPlacementRep": false}'::jsonb),
            wl.leetcode_username, wl.dob,
            TRUE, TRUE, TRUE, TRUE, TRUE
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ──────────────────────────────────────────────────────────────
-- Batch lifecycle
-- ──────────────────────────────────────────────────────────────

-- Nightly: graduates batches past their end_year (July 1 cutoff), flips
-- graduated students' role_label to 'Alumni', and promotes the oldest
-- active_junior batch to active_senior once no active_senior remains.
CREATE OR REPLACE FUNCTION rotate_batch_status()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    graduation_cutoff DATE;
    v_batch           RECORD;
BEGIN
    FOR v_batch IN
        SELECT id, batch_code, end_year, status FROM batches
        WHERE status NOT IN ('graduated', 'pending_onboarding')
        ORDER BY end_year
    LOOP
        graduation_cutoff := make_date(v_batch.end_year, 7, 1);

        IF CURRENT_DATE >= graduation_cutoff THEN
            UPDATE batches SET status = 'graduated', updated_at = NOW() WHERE id = v_batch.id;

            UPDATE users SET role_label = 'Alumni', updated_at = NOW()
            WHERE batch_id = v_batch.id AND role_label = 'Student';

            INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, metadata)
            SELECT u.id, 'BATCH_GRADUATED', 'batch', v_batch.id,
                   jsonb_build_object('batch_code', v_batch.batch_code, 'graduated_at', NOW())
            FROM users u
            WHERE (u.roles->>'isPlacementRep')::boolean = TRUE AND u.batch_id = v_batch.id
            LIMIT 1;

            RAISE NOTICE 'Batch % graduated', v_batch.batch_code;
        END IF;
    END LOOP;

    IF NOT EXISTS (SELECT 1 FROM batches WHERE status = 'active_senior') THEN
        UPDATE batches SET status = 'active_senior', updated_at = NOW()
        WHERE id = (SELECT id FROM batches WHERE status = 'active_junior' ORDER BY start_year LIMIT 1);
    END IF;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Readiness score
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION compute_readiness_score(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_placement_att    NUMERIC := 0;
    v_streak_adherence NUMERIC := 0;
    v_task_completion  NUMERIC := 0;
    v_daily_accuracy   NUMERIC := 0;
    v_lc_percentile    NUMERIC := 0;
    v_score            NUMERIC;
    v_batch_id         UUID;
    v_30d_ago          DATE := CURRENT_DATE - INTERVAL '30 days';
BEGIN
    SELECT batch_id INTO v_batch_id FROM users WHERE id = p_user_id;

    SELECT COALESCE(attendance_pct, 0) INTO v_placement_att
    FROM placement_attendance_summary WHERE user_id = p_user_id;

    SELECT COALESCE(
        CASE WHEN last_completed_date >= v_30d_ago THEN LEAST(current_streak, 30) * 100.0 / 30 ELSE 0 END, 0)
    INTO v_streak_adherence
    FROM daily_five_streaks WHERE user_id = p_user_id;

    SELECT COALESCE(COUNT(*) FILTER (WHERE completed = TRUE) * 100.0 / NULLIF(COUNT(*), 0), 0)
    INTO v_task_completion
    FROM task_completions WHERE user_id = p_user_id AND task_date >= v_30d_ago;

    SELECT COALESCE(last_accuracy_rate * 100, 0) INTO v_daily_accuracy
    FROM daily_five_streaks WHERE user_id = p_user_id;

    WITH batch_lc AS (
        SELECT ls.username, ls.total_solved,
               PERCENT_RANK() OVER (ORDER BY ls.total_solved) * 100 AS pct_rank
        FROM leetcode_stats ls
        JOIN users u ON u.leetcode_username = ls.username
        WHERE u.batch_id = v_batch_id
    )
    SELECT COALESCE(pct_rank, 0) INTO v_lc_percentile
    FROM batch_lc JOIN users u2 ON u2.leetcode_username = batch_lc.username
    WHERE u2.id = p_user_id;

    v_score := 0.30 * v_placement_att + 0.20 * v_streak_adherence + 0.20 * v_task_completion
             + 0.15 * v_daily_accuracy + 0.15 * v_lc_percentile;
    v_score := ROUND(LEAST(GREATEST(v_score, 0), 100), 2);

    INSERT INTO readiness_scores (user_id, score, computed_at, components_json)
    VALUES (p_user_id, v_score, NOW(), jsonb_build_object(
        'placement_attendance_pct', ROUND(v_placement_att, 2),
        'daily_five_adherence_pct', ROUND(v_streak_adherence, 2),
        'task_completion_rate_pct', ROUND(v_task_completion, 2),
        'daily_five_accuracy_pct', ROUND(v_daily_accuracy, 2),
        'leetcode_momentum_percentile', ROUND(v_lc_percentile, 2)
    ));

    RETURN v_score;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Daily Five quiz engine
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION increment_daily_five_streak(p_user_id UUID, p_accuracy_rate NUMERIC)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_rec           daily_five_streaks%ROWTYPE;
    v_current_month TEXT := TO_CHAR(NOW(), 'YYYY-MM');
BEGIN
    INSERT INTO daily_five_streaks (user_id, current_streak, longest_streak, freezes_remaining, freezes_reset_month, last_completed_date, last_accuracy_rate)
    VALUES (p_user_id, 0, 0, 2, v_current_month, NULL, NULL)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_rec FROM daily_five_streaks WHERE user_id = p_user_id;

    IF v_rec.freezes_reset_month <> v_current_month THEN
        v_rec.freezes_remaining := 2;
        v_rec.freezes_reset_month := v_current_month;
    END IF;

    IF v_rec.last_completed_date IS NULL OR v_rec.last_completed_date = CURRENT_DATE - 1 THEN
        v_rec.current_streak := v_rec.current_streak + 1;
    ELSIF v_rec.last_completed_date = CURRENT_DATE THEN
        NULL;
    ELSE
        v_rec.current_streak := 1;
    END IF;

    v_rec.longest_streak := GREATEST(v_rec.longest_streak, v_rec.current_streak);
    v_rec.last_completed_date := CURRENT_DATE;
    v_rec.last_accuracy_rate := p_accuracy_rate;
    v_rec.updated_at := NOW();

    UPDATE daily_five_streaks SET
        current_streak = v_rec.current_streak, longest_streak = v_rec.longest_streak,
        freezes_remaining = v_rec.freezes_remaining, freezes_reset_month = v_rec.freezes_reset_month,
        last_completed_date = v_rec.last_completed_date, last_accuracy_rate = v_rec.last_accuracy_rate,
        updated_at = v_rec.updated_at
    WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION apply_streak_freeze(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_rec daily_five_streaks%ROWTYPE;
BEGIN
    SELECT * INTO v_rec FROM daily_five_streaks WHERE user_id = p_user_id;

    IF NOT FOUND THEN RETURN 'no_streak'; END IF;
    IF v_rec.last_completed_date = CURRENT_DATE THEN RETURN 'already_completed'; END IF;
    IF v_rec.freezes_remaining <= 0 THEN RETURN 'no_freezes'; END IF;

    UPDATE daily_five_streaks
    SET freezes_remaining = v_rec.freezes_remaining - 1,
        last_completed_date = CURRENT_DATE - INTERVAL '1 day',
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN 'ok';
END;
$$;

CREATE OR REPLACE FUNCTION get_question_bank_full()
RETURNS SETOF question_bank
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = auth.uid()
          AND (u.role_label IN ('Faculty', 'HOD')
               OR EXISTS (SELECT 1 FROM user_permissions p WHERE p.user_id = u.id AND p.permission_key = 'publish_tasks'))
    ) THEN
        RAISE EXCEPTION 'Missing publish_tasks permission';
    END IF;
    RETURN QUERY SELECT * FROM question_bank ORDER BY topic;
END;
$$;

-- Server-picked, seeded per (user_id, today); resumes the same set if
-- called again the same day before submission.
CREATE OR REPLACE FUNCTION get_daily_five_questions(p_user_id UUID)
RETURNS TABLE (id UUID, question_text TEXT, options JSONB, topic TEXT, difficulty TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_attempt daily_five_attempts%ROWTYPE;
    v_seed FLOAT;
    v_question_ids UUID[];
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Not authenticated as this user';
    END IF;

    SELECT * INTO v_attempt FROM daily_five_attempts WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

    IF FOUND THEN
        IF v_attempt.submitted_at IS NOT NULL THEN
            RAISE EXCEPTION 'Already completed today''s Daily Five';
        END IF;
        RETURN QUERY
            SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
            FROM question_bank q WHERE q.id = ANY(v_attempt.question_ids);
        RETURN;
    END IF;

    v_seed := (('x' || substr(md5(p_user_id::TEXT || CURRENT_DATE::TEXT), 1, 8))::bit(32)::BIGINT::FLOAT / 2147483647.0) - 1.0;
    PERFORM setseed(v_seed);

    SELECT array_agg(qid) INTO v_question_ids FROM (
        SELECT q.id AS qid FROM question_bank q WHERE q.is_active = true ORDER BY random() LIMIT 5
    ) sub;

    IF v_question_ids IS NULL OR array_length(v_question_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'No active questions found in question bank';
    END IF;

    INSERT INTO daily_five_attempts (user_id, attempt_date, question_ids, started_at)
    VALUES (p_user_id, CURRENT_DATE, v_question_ids, now());

    RETURN QUERY
        SELECT q.id, q.question_text, q.options, q.topic, q.difficulty
        FROM question_bank q WHERE q.id = ANY(v_question_ids);
END;
$$;

CREATE OR REPLACE FUNCTION submit_daily_five_answers(p_user_id UUID, p_answers JSONB)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_attempt daily_five_attempts%ROWTYPE;
    v_question RECORD;
    v_correct_count INTEGER := 0;
    v_total INTEGER := 0;
    v_accuracy NUMERIC;
    v_elapsed_seconds INTEGER;
    v_flagged BOOLEAN := false;
    v_flag_reason TEXT;
    v_student_answer INTEGER;
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Not authenticated as this user';
    END IF;

    SELECT * INTO v_attempt FROM daily_five_attempts WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active Daily Five session — call get_daily_five_questions first';
    END IF;
    IF v_attempt.submitted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Already completed today''s Daily Five';
    END IF;

    FOR v_question IN SELECT id, correct_option FROM question_bank WHERE id = ANY(v_attempt.question_ids) LOOP
        v_total := v_total + 1;
        v_student_answer := (p_answers ->> v_question.id::TEXT)::INTEGER;
        IF v_student_answer IS NOT NULL AND v_student_answer = v_question.correct_option THEN
            v_correct_count := v_correct_count + 1;
        END IF;
    END LOOP;

    v_accuracy := CASE WHEN v_total > 0 THEN v_correct_count::NUMERIC / v_total ELSE 0 END;

    v_elapsed_seconds := EXTRACT(EPOCH FROM (now() - v_attempt.started_at))::INTEGER;
    IF v_elapsed_seconds < 3 THEN
        v_flagged := true;
        v_flag_reason := format('Completed in %s seconds (floor: 3s for %s questions)', v_elapsed_seconds, v_total);
    END IF;

    UPDATE daily_five_attempts SET
        submitted_at = now(), correct_count = v_correct_count, accuracy_rate = v_accuracy,
        flagged = v_flagged, flag_reason = v_flag_reason
    WHERE id = v_attempt.id;

    PERFORM increment_daily_five_streak(p_user_id, v_accuracy);

    INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, metadata)
    VALUES (p_user_id, 'DAILY_FIVE_COMPLETED', 'daily_five_attempts', v_attempt.id,
            jsonb_build_object('accuracy_rate', v_accuracy, 'correct_count', v_correct_count, 'total_questions', v_total, 'flagged', v_flagged));

    RETURN jsonb_build_object('correct_count', v_correct_count, 'total_questions', v_total, 'accuracy_rate', v_accuracy, 'flagged', v_flagged);
END;
$$;

CREATE OR REPLACE FUNCTION get_daily_five_results(p_user_id UUID)
RETURNS TABLE (id UUID, correct_option INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_attempt daily_five_attempts%ROWTYPE;
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Not authenticated as this user';
    END IF;

    SELECT * INTO v_attempt FROM daily_five_attempts WHERE user_id = p_user_id AND attempt_date = CURRENT_DATE;

    IF NOT FOUND OR v_attempt.submitted_at IS NULL THEN
        RAISE EXCEPTION 'No submitted attempt found for today';
    END IF;

    RETURN QUERY SELECT q.id, q.correct_option FROM question_bank q WHERE q.id = ANY(v_attempt.question_ids);
END;
$$;

CREATE OR REPLACE FUNCTION reset_daily_five_streak_violation(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
        RAISE EXCEPTION 'Not authenticated as this user';
    END IF;
    UPDATE daily_five_streaks SET current_streak = 0 WHERE user_id = p_user_id;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Mock exams
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION start_mock_exam(p_exam_id UUID)
RETURNS TABLE (result_id UUID, session_token UUID, started_at TIMESTAMPTZ, duration_minutes INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_existing mock_exam_results%ROWTYPE;
    v_duration INTEGER;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_existing FROM mock_exam_results WHERE exam_id = p_exam_id AND student_id = auth.uid();
    SELECT m.duration_minutes INTO v_duration FROM mock_exams m WHERE m.id = p_exam_id;
    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Exam not found';
    END IF;

    IF FOUND AND v_existing.status IN ('submitted', 'auto_submitted') THEN
        RAISE EXCEPTION 'Already submitted';
    END IF;

    IF FOUND THEN
        RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
        RETURN;
    END IF;

    INSERT INTO mock_exam_results (exam_id, student_id, session_token, started_at, status)
    VALUES (p_exam_id, auth.uid(), gen_random_uuid(), now(), 'in_progress')
    RETURNING mock_exam_results.id, mock_exam_results.session_token, mock_exam_results.started_at
    INTO v_existing.id, v_existing.session_token, v_existing.started_at;

    RETURN QUERY SELECT v_existing.id, v_existing.session_token, v_existing.started_at, v_duration;
END;
$$;

CREATE OR REPLACE FUNCTION submit_exam_server_side(
    p_exam_id UUID, p_student_id UUID, p_answers JSONB,
    p_time_taken_seconds INTEGER, p_proctoring_flags JSONB
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_result mock_exam_results%ROWTYPE;
    v_duration_minutes INTEGER;
    v_question RECORD;
    v_raw_marks NUMERIC := 0;
    v_out_of NUMERIC := 0;
    v_total_questions INTEGER := 0;
    v_student_answer TEXT;
    v_elapsed_seconds INTEGER;
    v_status TEXT := 'submitted';
BEGIN
    IF auth.uid() IS NULL OR auth.uid() != p_student_id THEN
        RAISE EXCEPTION 'Not authenticated as the submitting student';
    END IF;

    SELECT * INTO v_result FROM mock_exam_results WHERE exam_id = p_exam_id AND student_id = p_student_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active session — call start_mock_exam first';
    END IF;
    IF v_result.status IN ('submitted', 'auto_submitted') THEN
        RAISE EXCEPTION 'Already submitted';
    END IF;

    SELECT duration_minutes INTO v_duration_minutes FROM mock_exams WHERE id = p_exam_id;
    v_elapsed_seconds := EXTRACT(EPOCH FROM (now() - v_result.started_at))::INTEGER;
    IF v_elapsed_seconds > (v_duration_minutes * 60) + 120 THEN
        v_status := 'auto_submitted';
    END IF;

    FOR v_question IN SELECT * FROM mock_exam_questions WHERE exam_id = p_exam_id ORDER BY order_index LOOP
        v_total_questions := v_total_questions + 1;
        v_out_of := v_out_of + v_question.marks;
        v_student_answer := p_answers ->> v_question.id::TEXT;
        IF v_student_answer IS NOT NULL AND upper(v_student_answer) = v_question.correct_option THEN
            v_raw_marks := v_raw_marks + v_question.marks;
        END IF;
    END LOOP;

    UPDATE mock_exam_results SET
        submitted_at = now(),
        score = CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
        raw_marks = v_raw_marks, out_of = v_out_of, total_questions = v_total_questions,
        proctoring_flags = COALESCE(p_proctoring_flags, '[]'::jsonb), status = v_status
    WHERE id = v_result.id;

    RETURN jsonb_build_object(
        'result_id', v_result.id,
        'score', CASE WHEN v_out_of > 0 THEN round((v_raw_marks / v_out_of) * 100, 2) ELSE 0 END,
        'raw_marks', v_raw_marks, 'out_of', v_out_of
    );
END;
$$;

CREATE OR REPLACE FUNCTION get_mock_exam_question_with_answer(p_question_id UUID)
RETURNS TABLE (id UUID, exam_id UUID, question_text TEXT, option_a TEXT, option_b TEXT, option_c TEXT, option_d TEXT, correct_option TEXT, marks INTEGER)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role_label IN ('Faculty', 'HOD')) THEN
        RAISE EXCEPTION 'Only faculty/HOD may view correct answers';
    END IF;
    RETURN QUERY
        SELECT q.id, q.exam_id, q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks
        FROM mock_exam_questions q WHERE q.id = p_question_id;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- Knowledge Brain (RAG)
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_knowledge_search_vector()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.summary, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.company_name, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(substring(NEW.content, 1, 2000), '')), 'D');
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION knowledge_semantic_search(
    query_embedding vector, match_threshold FLOAT DEFAULT 0.5, match_count INT DEFAULT 5
)
RETURNS TABLE (id UUID, article_id UUID, chunk_text TEXT, title TEXT, similarity FLOAT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT ke.id, ke.article_id, ke.chunk_text, kba.title, 1 - (ke.embedding <=> query_embedding) AS similarity
    FROM knowledge_embeddings ke
    JOIN knowledge_brain_articles kba ON kba.id = ke.article_id AND kba.approval_status = 'approved'
    WHERE ke.embedding IS NOT NULL AND (1 - (ke.embedding <=> query_embedding)) >= match_threshold
    ORDER BY ke.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- ──────────────────────────────────────────────────────────────
-- Birthdays
-- ──────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION send_birthday_notifications()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR v_user IN
        SELECT id, name FROM users
        WHERE dob IS NOT NULL
          AND EXTRACT(MONTH FROM dob) = EXTRACT(MONTH FROM CURRENT_DATE)
          AND EXTRACT(DAY FROM dob) = EXTRACT(DAY FROM CURRENT_DATE)
    LOOP
        IF EXISTS (
            SELECT 1 FROM notifications
            WHERE created_by = v_user.id AND notification_type = 'birthday'
              AND target_audience = 'user' AND generated_at::date = CURRENT_DATE
        ) THEN
            CONTINUE;
        END IF;

        INSERT INTO notifications (title, message, notification_type, tone, target_audience, created_by, is_active, generated_at, valid_until)
        VALUES (
            'Happy Birthday, ' || split_part(v_user.name, ' ', 1) || '! 🎂',
            E'Hope your day''s a good one. On behalf of the whole PSGMX community — faculty, seniors, and juniors — we wish you a wonderful year ahead, both in your placement journey and beyond.\n— With warm regards, PSG MCA Department',
            'birthday', 'friendly', 'user', v_user.id, true, now(), (CURRENT_DATE + INTERVAL '1 day')::timestamptz
        );

        IF EXISTS (SELECT 1 FROM users WHERE id = v_user.id AND show_birthday_publicly = true) THEN
            INSERT INTO notifications (title, message, notification_type, tone, target_audience, created_by, is_active, generated_at, valid_until)
            VALUES (
                '🎉 Today''s birthday',
                split_part(v_user.name, ' ', 1) || ' is celebrating a birthday today!',
                'birthday', 'friendly', 'all', v_user.id, true, now(), (CURRENT_DATE + INTERVAL '1 day')::timestamptz
            );
        END IF;

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;

-- ──────────────────────────────────────────────────────────────
-- eCampus password vault
-- ──────────────────────────────────────────────────────────────

-- Fetches the shared key from a DB-level setting so no client ever needs to
-- hold or transmit it. Set once per environment, e.g.:
--   ALTER DATABASE postgres SET app.ecampus_encryption_key = '<random-secret>';
CREATE OR REPLACE FUNCTION _ecampus_encryption_key()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT current_setting('app.ecampus_encryption_key', true);
$$;

CREATE OR REPLACE FUNCTION set_ecampus_password(p_password TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_key TEXT := _ecampus_encryption_key();
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_password IS NULL OR btrim(p_password) = '' THEN
        DELETE FROM user_ecampus_credentials WHERE user_id = auth.uid();
        UPDATE users SET ecampus_password_set = false WHERE id = auth.uid();
        RETURN;
    END IF;

    IF v_key IS NULL OR v_key = '' THEN
        RAISE EXCEPTION 'eCampus encryption key is not configured on this database';
    END IF;

    INSERT INTO user_ecampus_credentials (user_id, encrypted_password, updated_at)
    VALUES (auth.uid(), extensions.pgp_sym_encrypt(btrim(p_password), v_key), now())
    ON CONFLICT (user_id) DO UPDATE SET encrypted_password = EXCLUDED.encrypted_password, updated_at = now();

    UPDATE users SET ecampus_password_set = true WHERE id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION get_ecampus_password(p_reg_no TEXT)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_encrypted BYTEA;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE reg_no = p_reg_no;
    IF v_user_id IS NULL THEN RETURN NULL; END IF;

    SELECT encrypted_password INTO v_encrypted FROM user_ecampus_credentials WHERE user_id = v_user_id;
    IF v_encrypted IS NULL THEN RETURN NULL; END IF;

    RETURN extensions.pgp_sym_decrypt(v_encrypted, _ecampus_encryption_key());
END;
$$;

CREATE OR REPLACE FUNCTION get_ecampus_passwords_bulk()
RETURNS TABLE(reg_no TEXT, password TEXT)
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
    SELECT u.reg_no, extensions.pgp_sym_decrypt(c.encrypted_password, _ecampus_encryption_key())
    FROM user_ecampus_credentials c JOIN users u ON u.id = c.user_id
    WHERE u.reg_no IS NOT NULL;
$$;

-- ──────────────────────────────────────────────────────────────
-- Function-level execute grants (table/column grants are in 09_grants_security.sql)
-- ──────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION _ecampus_encryption_key() FROM PUBLIC;
REVOKE ALL ON FUNCTION set_ecampus_password(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION set_ecampus_password(TEXT) TO authenticated;
REVOKE ALL ON FUNCTION get_ecampus_password(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_ecampus_password(TEXT) TO service_role;
REVOKE ALL ON FUNCTION get_ecampus_passwords_bulk() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_ecampus_passwords_bulk() TO service_role;

REVOKE ALL ON FUNCTION get_question_bank_full() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_question_bank_full() TO authenticated;
REVOKE ALL ON FUNCTION get_daily_five_questions(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_daily_five_questions(UUID) TO authenticated;
REVOKE ALL ON FUNCTION submit_daily_five_answers(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_daily_five_answers(UUID, JSONB) TO authenticated;
REVOKE ALL ON FUNCTION get_daily_five_results(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_daily_five_results(UUID) TO authenticated;
REVOKE ALL ON FUNCTION reset_daily_five_streak_violation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reset_daily_five_streak_violation(UUID) TO authenticated;
REVOKE ALL ON FUNCTION update_leetcode_username_rate_limited(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_leetcode_username_rate_limited(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION start_mock_exam(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION start_mock_exam(UUID) TO authenticated;
REVOKE ALL ON FUNCTION submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_exam_server_side(UUID, UUID, JSONB, INTEGER, JSONB) TO service_role;
REVOKE ALL ON FUNCTION get_mock_exam_question_with_answer(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_mock_exam_question_with_answer(UUID) TO authenticated;

REVOKE ALL ON FUNCTION send_birthday_notifications() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION send_birthday_notifications() TO service_role;

DO $$
BEGIN
    RAISE NOTICE '✅ 06_functions.sql complete.';
    RAISE NOTICE 'NEXT: run 07_triggers.sql';
END $$;
