-- ============================================================================
-- PSGMX v4 — Migration 19: Daily Five Quiz Engine
-- ============================================================================
-- Creates the question_bank and daily_five_streaks tables.
--
-- KEY DESIGN: Per-attempt data (which questions a student got today,
-- what they answered) is NEVER written to the database — it lives only
-- in device memory during the session. Only the streak state is persisted.
--
-- Run AFTER 18_placement_sessions.sql
-- ============================================================================

-- ── 1. question_bank ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS question_bank (
    id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text   TEXT    NOT NULL,
    -- options stored as a JSON array, e.g. ["A", "B", "C", "D"]
    options         JSONB   NOT NULL,
    -- 0-based index into options array (0=A, 1=B, 2=C, 3=D)
    correct_option  INT     NOT NULL CHECK (correct_option BETWEEN 0 AND 3),
    topic           TEXT    NOT NULL,
    difficulty      TEXT    NOT NULL
                    CHECK (difficulty IN ('easy', 'medium', 'hard')),
    created_by      UUID    REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_question_bank_topic      ON question_bank(topic);
CREATE INDEX IF NOT EXISTS idx_question_bank_difficulty ON question_bank(difficulty);
CREATE INDEX IF NOT EXISTS idx_question_bank_active     ON question_bank(is_active);

DROP TRIGGER IF EXISTS set_updated_at_question_bank ON question_bank;
CREATE TRIGGER set_updated_at_question_bank
    BEFORE UPDATE ON question_bank
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 2. daily_five_streaks ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_five_streaks (
    user_id             UUID    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak      INT     NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak      INT     NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    freezes_remaining   INT     NOT NULL DEFAULT 2 CHECK (freezes_remaining BETWEEN 0 AND 2),
    -- Tracks which month granted the current freezes (for monthly reset)
    freezes_reset_month TEXT    NOT NULL DEFAULT TO_CHAR(NOW(), 'YYYY-MM'),
    last_completed_date DATE,
    -- Cached accuracy rate from most recent session (0.0–1.0)
    last_accuracy_rate  NUMERIC(4,3) CHECK (last_accuracy_rate BETWEEN 0 AND 1),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 3. Function: increment_streak() ─────────────────────────────────────────
-- Called by the app after a student completes all 5 questions.
-- Handles: new month freeze reset, streak increment, longest_streak update.
CREATE OR REPLACE FUNCTION increment_daily_five_streak(
    p_user_id           UUID,
    p_accuracy_rate     NUMERIC   -- 0.0–1.0, correct / 5
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rec          daily_five_streaks%ROWTYPE;
    v_current_month TEXT := TO_CHAR(NOW(), 'YYYY-MM');
BEGIN
    -- Upsert to handle first-ever completion
    INSERT INTO daily_five_streaks (user_id, current_streak, longest_streak,
        freezes_remaining, freezes_reset_month, last_completed_date, last_accuracy_rate)
    VALUES (p_user_id, 0, 0, 2, v_current_month, NULL, NULL)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_rec FROM daily_five_streaks WHERE user_id = p_user_id;

    -- Reset freezes at start of a new month
    IF v_rec.freezes_reset_month <> v_current_month THEN
        v_rec.freezes_remaining  := 2;
        v_rec.freezes_reset_month := v_current_month;
    END IF;

    -- Increment streak (or start fresh if last was not yesterday)
    IF v_rec.last_completed_date IS NULL
       OR v_rec.last_completed_date = CURRENT_DATE - INTERVAL '1 day' THEN
        v_rec.current_streak := v_rec.current_streak + 1;
    ELSIF v_rec.last_completed_date = CURRENT_DATE THEN
        -- Already completed today — idempotent, just update accuracy
        NULL;
    ELSE
        -- Missed one or more days without a freeze
        v_rec.current_streak := 1;
    END IF;

    v_rec.longest_streak     := GREATEST(v_rec.longest_streak, v_rec.current_streak);
    v_rec.last_completed_date := CURRENT_DATE;
    v_rec.last_accuracy_rate  := p_accuracy_rate;
    v_rec.updated_at          := NOW();

    UPDATE daily_five_streaks
    SET current_streak      = v_rec.current_streak,
        longest_streak      = v_rec.longest_streak,
        freezes_remaining   = v_rec.freezes_remaining,
        freezes_reset_month = v_rec.freezes_reset_month,
        last_completed_date = v_rec.last_completed_date,
        last_accuracy_rate  = v_rec.last_accuracy_rate,
        updated_at          = v_rec.updated_at
    WHERE user_id = p_user_id;
END;
$$;

-- ── 4. Function: apply_streak_freeze() ───────────────────────────────────────
-- Spends a freeze to preserve the streak when a day was missed.
CREATE OR REPLACE FUNCTION apply_streak_freeze(p_user_id UUID)
RETURNS TEXT   -- 'ok', 'no_freezes', 'already_completed'
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rec           daily_five_streaks%ROWTYPE;
    v_current_month TEXT := TO_CHAR(NOW(), 'YYYY-MM');
BEGIN
    SELECT * INTO v_rec FROM daily_five_streaks WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN 'no_streak';
    END IF;

    -- Already completed today — no freeze needed
    IF v_rec.last_completed_date = CURRENT_DATE THEN
        RETURN 'already_completed';
    END IF;

    -- No freezes available
    IF v_rec.freezes_remaining <= 0 THEN
        RETURN 'no_freezes';
    END IF;

    -- Spend a freeze: mark yesterday as "completed" so streak continues
    UPDATE daily_five_streaks
    SET freezes_remaining   = v_rec.freezes_remaining - 1,
        last_completed_date = CURRENT_DATE - INTERVAL '1 day',
        updated_at          = NOW()
    WHERE user_id = p_user_id;

    RETURN 'ok';
END;
$$;

-- ── 5. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_five_streaks ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read active questions
DROP POLICY IF EXISTS "qbank_read_active" ON question_bank;
CREATE POLICY "qbank_read_active" ON question_bank
    FOR SELECT TO authenticated
    USING (is_active = TRUE);

-- publish_tasks permission required to manage questions
DROP POLICY IF EXISTS "qbank_write" ON question_bank;
CREATE POLICY "qbank_write" ON question_bank
    FOR ALL TO authenticated
    USING (user_has_permission(auth.uid(), 'publish_tasks'))
    WITH CHECK (user_has_permission(auth.uid(), 'publish_tasks'));

-- Users can only see/update their own streak
DROP POLICY IF EXISTS "streaks_own" ON daily_five_streaks;
CREATE POLICY "streaks_own" ON daily_five_streaks
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Admins can read all streaks for leaderboard
DROP POLICY IF EXISTS "streaks_read_admin" ON daily_five_streaks;
CREATE POLICY "streaks_read_admin" ON daily_five_streaks
    FOR SELECT TO authenticated
    USING (user_has_permission(auth.uid(), 'view_batch_analytics'));

-- ── 6. Success ────────────────────────────────────────────────────────────────
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration 19 complete: Daily Five Quiz Engine';
    RAISE NOTICE '  - question_bank table created';
    RAISE NOTICE '  - daily_five_streaks table created';
    RAISE NOTICE '  - increment_daily_five_streak() function created';
    RAISE NOTICE '  - apply_streak_freeze() function created';
    RAISE NOTICE 'NEXT: Run 20_readiness_scores.sql';
    RAISE NOTICE '========================================';
END $$;
